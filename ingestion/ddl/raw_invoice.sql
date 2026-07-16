create table if not exists retail.raw_invoice (
    invoice_id      String,
    stock_code    String,
    description   Nullable(String),
    quantity      Int64,
    invoice_date  DateTime,
    unit_price    Decimal(10, 2),
    customer_id   Nullable(Int64),
    country       LowCardinality(String),
    _loaded_at    DateTime default now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(invoice_date)
ORDER BY (toDate(invoice_date), invoice_id, stock_code)
