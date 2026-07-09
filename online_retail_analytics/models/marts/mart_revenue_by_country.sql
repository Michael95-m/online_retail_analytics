with int_invoices as (
    select * from {{ ref('int_invoices') }}
)

select
    country,
    sumIf(total_revenue, is_cancelled = 0) as gross_revenue,
    sumIf(total_revenue * -1, is_cancelled = 1) as cancelled_revenue,
    gross_revenue - cancelled_revenue as net_revenue,
    sum(merchandise_revenue) as merchandise_revenue,
    sum(non_merchandise_revenue) as non_merchandise_revenue,
    count(invoice_id) as total_invoice_count,
    countIf(invoice_id, is_cancelled = 1) as cancelled_invoice_count,
    sum(adjustment_quantity) as adjustment_quantity
from int_invoices
group by country
