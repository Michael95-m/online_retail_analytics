
WITH int_revenue_by_invoice AS
(
 SELECT
invoice_id, total_revenue
FROM {{ ref('int_invoices') }}
),
stg_revenue_by_invoice as
(
SELECT
invoice_id, sum(quantity * unit_price) as total_revenue
FROM {{ ref('stg_invoices') }}
group by invoice_id
)
SELECT
coalesce(int.invoice_id, stg.invoice_id) as invoice_id,
int.total_revenue as int_total_revenue,
stg.total_revenue as stg_total_revenue

FROM int_revenue_by_invoice int
full outer join
 stg_revenue_by_invoice stg
on int.invoice_id = stg.invoice_id
where int_total_revenue <> stg_total_revenue
