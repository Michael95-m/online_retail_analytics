WITH source AS (
    SELECT * FROM {{ source('retail', 'raw_invoice') }}
),
renamed as 
(
SELECT 
    invoice_id,
    upper(trim(stock_code)) AS stock_code,
    description,
    quantity,
    invoice_date as invoice_ts,
    unit_price,
    customer_id,
    country,
    startsWith(invoice_id, 'C')  AS is_cancelled,
    (unit_price = 0) AS is_zero_priced,
    if(
        stock_code IN ('POST','DOT','C2','M','BANK CHARGES','D','CRUK','AMAZONFEE','S', 'ADJUST', 'B', 'GIFT')
    or match(stock_code, '^GIFT')
    or match(stock_code, 'TEST')
    , 0, 1) AS is_merchandise -- roles that is not related with revenue
FROM 
    source 
)
SELECT * FROM renamed