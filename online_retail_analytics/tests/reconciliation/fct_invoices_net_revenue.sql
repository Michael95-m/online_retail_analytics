with fct_invoices as (
    select sum(net_revenue) as total
    from
        {{ ref('fct_invoices') }}
),

fct_invoice_lines as (
    select sum(line_amount) as total
    from
        {{ ref('fct_invoice_lines') }}
)

select
    fct_invoices.total,
    fct_invoice_lines.total
from
    fct_invoices, fct_invoice_lines
where
    abs(fct_invoice_lines.total - fct_invoices.total) > 0.01
