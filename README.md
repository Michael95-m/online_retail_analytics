# Online Retail Analytics — dbt + ClickHouse

An end-to-end analytics engineering project using the [Online Retail II (UCI)](https://archive.ics.uci.edu/dataset/502/online+retail+ii) dataset — transactional data from a UK-based online giftware retailer (Dec 2009 – Dec 2011, ~1.07M rows).

**Stack:** Python · ClickHouse · dbt · Docker · uv

## Architecture

```
Excel (2 sheets)
      │
      ▼
ingestion/load_data.py        ← Python ingestion (pandas + clickhouse-connect)
      │
      ▼
retail.raw_invoice            ← raw layer (plain MergeTree, faithful mirror of source)
      │
      ▼
staging  (stg_invoices)       ← thin, type-safe view — rename/cast only, 1:1 with source
      │
      ▼
marts/core  (the star)        ← dim_date · dim_customers · dim_products   (conformed dimensions)
                                fct_invoice_lines   (atomic fact: one row per physical invoice line)
                                fct_invoices        (invoice-grain rollup of the lines)
      │
      ▼
marts             ← thin revenue rollups (daily / monthly / by country) over the fact
marts/analytics   ← mart_customer_rfm (RFM customer segmentation)

seeds/stock_code_type   ← tested lookup that classifies non-merchandise codes
                          (postage, fee, voucher, adjustment…) — data, not hardcoded logic
```

The old aggregate-on-aggregate `intermediate/int_*` layer has been replaced by a Kimball
star schema built on a single **atomic fact** (`fct_invoice_lines`, one row per invoice line
with a signed `line_amount`), so every mart is now a thin roll-up rather than an aggregate of
an aggregate.

## Project Structure

```
├── data/                     # raw data files (gitignored, keep .gitkeep)
├── docker-compose.yml        # ClickHouse + ch-ui
├── ingestion/
│   ├── ddl/
│   │   └── raw_invoice.sql   # DDL for the raw table
│   └── load_data.py          # idempotent ingestion script
├── online_retail_analytics/  # dbt project
│   ├── seeds/                # stock_code_type — non-merchandise classification
│   ├── models/
│   │   ├── staging/          # stg_invoices (thin: rename/cast only)
│   │   └── marts/
│   │       ├── core/         # dim_date, dim_customers, dim_products, fct_invoice_lines, fct_invoices
│   │       ├── analytics/    # mart_customer_rfm
│   │       └── *.sql         # mart_revenue_daily/monthly/by_country, mart_daily_transaction_detail
│   └── tests/
│       └── reconciliation/   # singular tests tying the fact + marts back to source numbers
├── pyproject.toml
└── uv.lock
```

## Prerequisites

- Docker Desktop
- [uv](https://docs.astral.sh/uv/) (Python package manager)

## Setup

### 1. Clone and install dependencies

```bash
git clone <repo-url>
cd online_retail_analytics
uv sync
source .venv/bin/activate
```

### 2. Configure environment variables

Create a `.env` file at the project root (see `.env.example`):

```
CLICKHOUSE_HOST=localhost
CLICKHOUSE_PORT=8123
CLICKHOUSE_USER=admin
CLICKHOUSE_PASSWORD=admin
```

### 3. Start ClickHouse + ch-ui

```bash
docker compose up -d
```

Verify ClickHouse is up:

```bash
curl http://localhost:8123/ping   # should return "Ok."
```

ch-ui (web SQL client) is available at [http://localhost:5521](http://localhost:5521) — sign in with your ClickHouse credentials.

### 4. Download the dataset

```bash
curl -L "https://archive.ics.uci.edu/static/public/502/online+retail+ii.zip" -o data/online_retail.zip
unzip data/online_retail.zip -d data/
```

### 5. Load the raw data

```bash
python ingestion/load_data.py
```

This script is idempotent — it drops and recreates `retail.raw_invoice`, reads both Excel sheets, renames columns to snake_case, applies type casting (including nullable handling for `description` and `customer_id`), and bulk-inserts via `clickhouse-connect`.

Expected result: **1,067,371 rows** in `retail.raw_invoice`.

### 6. Configure dbt

dbt connection settings live in `online_retail_analytics/profiles/profiles.yml`

```yaml
online_retail_analytics:
  target: dev
  outputs:
    dev:
      type: clickhouse
      driver:
      host: "{{ env_var('CLICKHOUSE_HOST') }}"
      port: "{{ env_var('CLICKHOUSE_PORT') | as_number }}"
      user: "{{ env_var('CLICKHOUSE_USER') }}"
      password: "{{ env_var('CLICKHOUSE_PASSWORD') }}"
      schema: "{{ env_var('CLICKHOUSE_SCHEMA', 'retail') }}"
      secure: False
```

Run this at the <b>root directory</b>.

```bash
source env.sh
```

Be careful. it's not ./env.sh

After that, verify the connection:

```bash
cd online_retail_analytics
dbt debug
```

### 7. Run dbt

```bash
dbt deps           # install packages (dbt_utils, dbt_expectations)
dbt build          # load seeds → build all models → run all tests, in dependency order
```

## Data Quality & Testing

Generic tests (`not_null`, `unique`) catch missing or duplicate data, but they don't catch logic bugs — a model can pass every generic test and still compute the wrong number. To cover that gap, this project pairs generic tests with **singular reconciliation tests** in `tests/reconciliation/` that check actual numbers tie out between layers: `fct_invoice_lines` total (`sum(line_amount)`) must equal the raw source revenue to the penny, `fct_invoices` net revenue must roll up to that same total, and `mart_revenue_daily`/`mart_revenue_monthly` net revenue must equal the sum of their own merchandise and non-merchandise splits. Together these prove the star-schema migration reproduced the original numbers exactly.

One lesson worth calling out: an early version of the mart reconciliation tests compared `net_revenue` to `merchandise_revenue + non_merchandise_revenue` with `!=`. Those two numbers are mathematically equal but computed via different summation paths, so at real data volume floating-point rounding made them differ by a fraction of a cent — a false failure on correct data. Fixed by using a tolerance (`abs(a - b) > 0.01`) instead of exact equality. Never compare floats with `!=` in a reconciliation test.

## Data Notes

- **Cancellations / returns**: invoices prefixed with `C` have negative quantities. The atomic fact records them with a signed `line_amount` (naturally negative) and `transaction_type = 'return'`, so net revenue falls out of `sum(line_amount)` with no manual sign-flipping. Guest purchases (null `customer_id`) map to a `-1` "unknown" member in `dim_customers`, so no fact row is ever dropped by a join.
- **Nulls**: `description` (missing product names) and `customer_id` (guest purchases) are genuinely nullable and preserved as `Nullable(...)` in ClickHouse — null handling decisions are deferred to staging/marts, keeping the raw layer a faithful mirror.
- **Duplicate-looking lines**: the same invoice + stock code can appear on multiple lines (e.g. quantity 2 and 1 at the same timestamp). These are valid source records, not duplicates — hence a plain `MergeTree` engine with no deduplication at the raw layer.
- **Ordering key**: `ORDER BY (toDate(invoice_date), invoice_id, stock_code)` — date-first to support the dominant query pattern (date-range filters).
