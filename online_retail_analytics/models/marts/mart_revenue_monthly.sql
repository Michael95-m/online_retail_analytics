select
    toStartOfMonth(invoice_date) as invoice_month,
    sumIf(line_amount, transaction_type <> 'return') as gross_revenue,
    -sumIf(line_amount, transaction_type = 'return') as cancelled_revenue,
    sum(line_amount) as net_revenue,
    sumIf(line_amount, is_merchandise) as merchandise_revenue,
    sumIf(line_amount, not is_merchandise) as non_merchandise_revenue,
    uniqExact(invoice_id) as total_invoice_count,
    uniqExactIf(invoice_id, transaction_type = 'return') as cancelled_invoice_count,
    sumIf(quantity, transaction_type = 'adjustment') as adjustment_quantity
from {{ ref('fct_invoice_lines') }}
group by toStartOfMonth(invoice_date)
