with source as (
    select * from {{ source('retail', 'raw_invoice') }}
),

renamed as (
    select
        invoice_id,
        upper(trim(stock_code)) as stock_code,
        description,
        quantity,
        invoice_date as invoice_ts,
        unit_price,
        customer_id,
        country
    from
        source
)

select * from renamed
