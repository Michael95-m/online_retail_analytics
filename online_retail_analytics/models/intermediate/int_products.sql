with stg_invoice as (
    select *
    from {{ ref('stg_invoices') }}
),

valid_stock_code as (
    select
        stock_code,
        description,
        invoice_ts
    from stg_invoice
    where is_merchandise = 1
),

latest_update as (
    select
        stock_code,
        description,
        invoice_ts,
        row_number() over (
            partition by stock_code
            order by (description is not NULL) desc, invoice_ts desc
        ) as rn -- prefer a non-null description, but keep the row even if every description was null
    from valid_stock_code
),

stock_timestamp as (
    select
        stock_code,
        min(invoice_ts) as first_invoice_ts,
        max(invoice_ts) as final_invoice_ts
    from valid_stock_code
    group by stock_code
)

select
    latest_update.stock_code,
    latest_update.description,
    ts_data.first_invoice_ts,
    ts_data.final_invoice_ts
from latest_update
left join
    stock_timestamp as ts_data
    on latest_update.stock_code = ts_data.stock_code
where latest_update.rn = 1
