select
    stock_code,
    country,
    invoice_date as report_date,
    transaction_type = 'return' as is_cancelled,
    is_merchandise,
    sum(quantity) as total_quantity,
    sumIf(quantity, transaction_type = 'adjustment') as adjustment_quantity,
    sum(line_amount) as line_revenue
from {{ ref('fct_invoice_lines') }}
group by
    stock_code,
    country,
    invoice_date,
    is_cancelled,
    is_merchandise
