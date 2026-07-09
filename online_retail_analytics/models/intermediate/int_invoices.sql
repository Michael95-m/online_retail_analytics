with stg_invoices as (
    select * from {{ ref('stg_invoices') }}
)

select
    invoice_id,
    customer_id,
    country,
    min(invoice_ts) as invoice_create_ts,
    is_cancelled,
    uniqExact(stock_code) as distinct_product_count,
    sumIf(quantity, is_zero_priced = 0) as total_quantity,
    sumIf(quantity, is_zero_priced = 1) as adjustment_quantity,
    sumIf(quantity * unit_price, is_merchandise = 1) as merchandise_revenue,
    sumIf(quantity * unit_price, is_merchandise = 0) as non_merchandise_revenue,
    sum(quantity * unit_price) as total_revenue
from stg_invoices
group by all
