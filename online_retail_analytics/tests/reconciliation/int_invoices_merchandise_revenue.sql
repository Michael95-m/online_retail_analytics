WITH int_invoice AS (
    SELECT * FROM {{ ref('int_invoices') }}
)
SELECT
    invoice_id,
    merchandise_revenue,
    non_merchandise_revenue,
    total_revenue
FROM int_invoice
where total_revenue != (merchandise_revenue + non_merchandise_revenue)