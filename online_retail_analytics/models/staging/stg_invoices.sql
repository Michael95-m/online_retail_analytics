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
        country,
        startsWith(invoice_id, 'C') as is_cancelled,
        (unit_price = 0) as is_zero_priced,
        if(
            stock_code in (
                'POST', 'DOT', 'C2', 'M', 'BANK CHARGES', 'D', 'CRUK', 'AMAZONFEE', 'S', 'ADJUST', 'B', 'GIFT'
            )
            or match(stock_code, '^GIFT')
            or match(stock_code, 'TEST'),
            0, 1
        ) as is_merchandise -- roles that is not related with revenue
    from
        source
)

select * from renamed
