with int_invoice_items as (
    select *
    from {{ ref('int_invoice_items') }}
)

select
    stock_code,
    country,
    toDate(invoice_create_ts) as report_dt,
    is_cancelled,
    is_merchandise,
    sum(total_quantity) as total_quantity,
    sum(adjustment_quantity) as adjustment_quantity,
    sum(line_revenue) as line_revenue
from int_invoice_items
group by
    stock_code,
    country,
    toDate(invoice_create_ts),
    is_cancelled,
    is_merchandise
