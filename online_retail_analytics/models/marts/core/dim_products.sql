with products as (
    select
        stock_code,
        argMax(description, (description is not NULL, invoice_ts)) as description,
        min(invoice_ts) as first_invoice_ts,
        max(invoice_ts) as last_invoice_ts
    from {{ ref('stg_invoices') }}
    group by stock_code
)

select
    p.stock_code,
    p.description,
    if(empty(s.stock_code), 'merchandise', s.product_type) as product_type,
    empty(s.stock_code) as is_merchandise,
    p.first_invoice_ts,
    p.last_invoice_ts
from products as p
left join {{ ref('stock_code_type') }} as s
    on p.stock_code = s.stock_code
