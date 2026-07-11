select
    invoice_id,
    stock_code,
    count(*) as stock_code_count
from {{ ref('int_invoice_items') }}
group by invoice_id, stock_code
having count(*) > 1
