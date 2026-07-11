{{
    config(
        materialized='table',
        order_by=['invoice_id'],
        partition_by='toYYYYMM(invoice_date)'
    )
}}

select
    invoice_id,
    any(customer_id) as customer_id,
    any(country) as country,
    min(invoice_date) as invoice_date,
    startsWith(invoice_id, 'C') as is_cancelled,
    count(*) as line_count,
    count(distinct stock_code) as distinct_product_count,
    sum(quantity) as total_quantity,
    sumIf(line_amount, is_merchandise) as merchandise_revenue,
    sumIf(line_amount, not is_merchandise) as non_merchandise_revenue,
    sum(line_amount) as net_revenue

from {{ ref('fct_invoice_lines') }}
group by
    invoice_id
