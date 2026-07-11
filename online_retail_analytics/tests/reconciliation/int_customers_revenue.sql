with int_revenue_by_customer as (
    select
        -- calculate total revenue by subtracting cancelled revenue from gross revenue
        customer_id,
        gross_revenue - cancelled_revenue as total_revenue
    from {{ ref('int_customers') }}
),

stg_revenue_by_customer as (
    select
        customer_id,
        sum(quantity * unit_price) as total_revenue
    from {{ ref('stg_invoices') }}
    where customer_id is not null -- ignore null customer_id values
    group by customer_id
)

select
    coalesce(int.customer_id, stg.customer_id) as customer_id,
    int.total_revenue as int_total_revenue,
    stg.total_revenue as stg_total_revenue

from int_revenue_by_customer as int
full outer join
    stg_revenue_by_customer as stg
    on int.customer_id = stg.customer_id
where int_total_revenue <> stg_total_revenue
