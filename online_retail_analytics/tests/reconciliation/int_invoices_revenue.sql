with int_revenue_by_invoice as (
    select
        invoice_id,
        total_revenue
    from {{ ref('int_invoices') }}
),

stg_revenue_by_invoice as (
    select
        invoice_id,
        sum(quantity * unit_price) as total_revenue
    from {{ ref('stg_invoices') }}
    group by invoice_id
)

select
    coalesce(int.invoice_id, stg.invoice_id) as invoice_id,
    int.total_revenue as int_total_revenue,
    stg.total_revenue as stg_total_revenue

from int_revenue_by_invoice as int
full outer join
    stg_revenue_by_invoice as stg
    on int.invoice_id = stg.invoice_id
where int_total_revenue <> stg_total_revenue
