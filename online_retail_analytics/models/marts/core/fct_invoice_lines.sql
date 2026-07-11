{{ config(
    materialized='table',
    order_by=['invoice_date', 'invoice_id','line_number'],
    partition_by='toYYYYMM(invoice_date)'
) }}
select
    invoice_id,
    i.stock_code,
    country,
    toDate(invoice_ts) as invoice_date,
    multiIf(
        startsWith(invoice_id, 'C'), 'return',
        not empty(c.stock_code), c.product_type,
        unit_price = 0, 'adjustment',
        'sale'
    ) as transaction_type,
    empty(c.stock_code) as is_merchandise,
    quantity,
    unit_price,
    cast(quantity * unit_price as Decimal(18, 2)) as line_amount,
    coalesce(i.customer_id, -1) as customer_id,
    row_number() over (partition by invoice_id order by invoice_ts, i.stock_code) as line_number,
    invoice_ts
from {{ ref('stg_invoices') }} as i
left join
    {{ ref('stock_code_type') }} as c
    on i.stock_code = c.stock_code
