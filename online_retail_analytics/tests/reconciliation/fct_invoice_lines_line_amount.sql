with fct as (
    select sum(line_amount) as total
    from {{ ref('fct_invoice_lines') }}
),

raw as (
    select sum(unit_price * quantity) as total
    from {{ source('retail', 'raw_invoice') }}
)

select
    fct.total,
    raw.total
from fct, raw
where abs(fct.total - raw.total) > 0.01
