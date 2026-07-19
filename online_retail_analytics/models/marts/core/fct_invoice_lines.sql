{{ config(
    materialized='incremental',
    unique_key=['invoice_id', 'line_number'],
    incremental_strategy='delete+insert',
    order_by=['invoice_date', 'invoice_id','line_number'],
    partition_by='toYYYYMM(invoice_date)'
) }}
select
    i.invoice_id,
    i.stock_code,
    i.country,
    toDate(i.invoice_ts) as invoice_date,
    multiIf(
        startsWith(i.invoice_id, 'C'), 'return',
        not empty(c.stock_code), c.product_type,
        i.unit_price = 0, 'adjustment',
        'sale'
    ) as transaction_type,
    empty(c.stock_code) as is_merchandise,
    i.quantity,
    i.unit_price,
    cast(i.quantity * i.unit_price as Decimal(18, 2)) as line_amount,
    coalesce(i.customer_id, -1) as customer_id,
    row_number() over (partition by i.invoice_id order by i.invoice_ts, i.stock_code) as line_number,
    i.invoice_ts,
    i._loaded_at
from {{ ref('stg_invoices') }} as i
left join
    {{ ref('stock_code_type') }} as c
    on i.stock_code = c.stock_code
{% if is_incremental() %}
    where i._loaded_at > (select max(t._loaded_at) from {{ this }} as t)
{% endif %}
