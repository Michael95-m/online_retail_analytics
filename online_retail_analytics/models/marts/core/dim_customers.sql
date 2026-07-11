with customers as (
    select
        customer_id,
        argMax(country, invoice_ts) as country,
        min(invoice_ts) as first_invoice_ts,
        max(invoice_ts) as last_invoice_ts,
        toDate(min(invoice_ts)) as first_invoice_date
    from {{ ref('stg_invoices') }}
    where customer_id is not null
    group by customer_id
)

-- for real customer
select
    customer_id,
    country,
    first_invoice_ts,
    last_invoice_ts,
    first_invoice_date
from customers
union all
select
    -1 as customer_id, -- for "unknown" member
    'UNKNOWN' as country,
    null as first_invoice_ts,
    null as last_invoice_ts,
    null as first_invoice_date
