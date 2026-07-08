WITH stg_invoices AS 
  (
  SELECT 
   * 
  FROM {{ ref('stg_invoices') }}
  )

SELECT  
 invoice_id,
 stock_code, 
 customer_id,
 country,
 is_cancelled,
 is_merchandise,
 min(invoice_ts) as invoice_create_ts,
 sumIf(quantity, is_zero_priced=0) as total_quantity,
 sumIf(quantity, is_zero_priced=1) as adjustment_quantity,
 sum(quantity * unit_price) as line_revenue
FROM stg_invoices
GROUP BY 
 invoice_id,
 stock_code, 
 customer_id,
 country,
 is_cancelled,
 is_merchandise