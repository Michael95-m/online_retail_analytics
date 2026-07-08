WITH stg_invoice AS 
  (
SELECT *
FROM {{ ref('stg_invoices') }}
  ),
  valid_stock_code AS 
  (
SELECT  
  stock_code, description, invoice_ts
FROM stg_invoice
WHERE is_merchandise = 1
  ),
  latest_update AS 
  (
SELECT
 stock_code,
 description,
 invoice_ts,
 row_number() OVER (PARTITION BY stock_code
ORDER BY (description IS NOT NULL) DESC, invoice_ts DESC) AS rn -- prefer a non-null description, but keep the row even if every description was null
FROM valid_stock_code
  ),
  stock_timestamp AS 
  (
  SELECT  
    stock_code, min(invoice_ts) AS first_invoice_ts, max(invoice_ts) AS final_invoice_ts
  FROM valid_stock_code 
  group by stock_code 
  )
SELECT  
 latest_update.stock_code,
  latest_update.description,
  ts_data.first_invoice_ts,
  ts_data.final_invoice_ts
FROM latest_update
LEFT JOIN 
  stock_timestamp ts_data
ON latest_update.stock_code = ts_data.stock_code
WHERE latest_update.rn = 1