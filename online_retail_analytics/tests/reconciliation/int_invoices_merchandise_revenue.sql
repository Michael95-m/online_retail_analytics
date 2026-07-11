with int_invoice as (
    select * from {{ ref('int_invoices') }}
)

select
    invoice_id,
    merchandise_revenue,
    non_merchandise_revenue,
    total_revenue
from int_invoice
where total_revenue != (merchandise_revenue + non_merchandise_revenue)
