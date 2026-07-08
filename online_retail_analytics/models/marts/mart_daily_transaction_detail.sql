WITH int_invoice_items AS 
  (
 SELECT 
   * 
 FROM {{ ref('int_invoice_items') }}
  )
SELECT  
 stock_code, 
 country,
 toDate(invoice_create_ts) AS report_dt,
 is_cancelled,
 is_merchandise,
 sum(total_quantity) as total_quantity,
 sum(adjustment_quantity) as adjustment_quantity,
 sum(line_revenue) as line_revenue
FROM int_invoice_items
GROUP BY 
 stock_code, 
 country,
 toDate(invoice_create_ts),
 is_cancelled,
 is_merchandise
  