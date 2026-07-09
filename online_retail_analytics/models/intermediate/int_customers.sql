with stg_invoices as (
    select *
    from {{ ref('stg_invoices') }}
),

final as (
    select
        customer_id,
        argMax(country, invoice_ts) as country,
        min(invoice_ts) as first_invoice_ts,
        max(invoice_ts) as last_invoice_ts,

        uniqExactIf(invoice_id, is_cancelled = 0 and is_zero_priced = 0) as total_invoice_count,
        uniqExactIf(invoice_id, is_cancelled = 1 and is_zero_priced = 0) as cancelled_invoice_count,

        sumIf(unit_price * quantity, is_cancelled = 0) as gross_revenue,
        sumIf(unit_price * quantity * -1, is_cancelled = 1) as cancelled_revenue
    from stg_invoices
    where customer_id is not NULL
    group by customer_id
)

select *
from final
