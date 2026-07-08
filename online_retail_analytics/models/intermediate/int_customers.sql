WITH stg_invoices AS
  (
SELECT *
FROM {{ ref('stg_invoices') }}
  ),
  final AS 
  (
SELECT  
 customer_id,
  argMax(country, invoice_ts) AS country,
  min(invoice_ts) AS first_invoice_ts,
  max(invoice_ts) AS last_invoice_ts,
  
  uniqExactIf(invoice_id, is_cancelled = 0 and is_zero_priced = 0) AS total_invoice_count,
  uniqExactIf(invoice_id, is_cancelled = 1 and is_zero_priced = 0) AS cancelled_invoice_count,
  
  sumIf(unit_price * quantity, is_cancelled = 0) AS gross_revenue,
  sumIf(unit_price * quantity * -1, is_cancelled = 1) AS cancelled_revenue
FROM stg_invoices
WHERE customer_id IS NOT NULL
GROUP BY customer_id
  )
SELECT *
FROM final