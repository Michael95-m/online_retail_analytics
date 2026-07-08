
WITH int_revenue_by_customer AS 
(
 SELECT 
 customer_id, gross_revenue - cancelled_revenue as total_revenue -- calculate total revenue by subtracting cancelled revenue from gross revenue
FROM {{ ref('int_customers') }}
),
stg_revenue_by_customer as 
(
SELECT 
customer_id, sum(quantity * unit_price) as total_revenue
FROM {{ ref('stg_invoices') }}
where customer_id is not null -- ignore null customer_id values
group by customer_id
)
SELECT  
coalesce(int.customer_id, stg.customer_id) as customer_id,
int.total_revenue as int_total_revenue,
stg.total_revenue as stg_total_revenue

FROM int_revenue_by_customer int
full outer join 
 stg_revenue_by_customer stg 
on int.customer_id = stg.customer_id 
where int_total_revenue <> stg_total_revenue
