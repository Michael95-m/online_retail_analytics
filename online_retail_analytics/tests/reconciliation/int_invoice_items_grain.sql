SELECT
    invoice_id, stock_code, count(*) as stock_code_count
FROM {{ ref('int_invoice_items') }}
GROUP BY invoice_id, stock_code
HAVING count(*) > 1
