with
-- since historical dataset, max(invoice_date) is referenced as recent day
(
    select max(invoice_date)
    from {{ ref('fct_invoice_lines') }}
) as ref_date,
rfm_base as (
    select
        customer_id,
        max(invoice_date) as last_purchase_date,
        date_diff('day', last_purchase_date, ref_date) as recency,
        uniqExactIf(invoice_id, transaction_type <> 'return') as frequency,
        sumIf(line_amount, is_merchandise) as monetary
    from {{ ref('fct_invoice_lines') }}
    where customer_id <> -1
    group by customer_id
),

scored as (
    select
        customer_id,
        last_purchase_date,
        recency,
        ntile(5) over (order by recency desc) as r_score,
        frequency,
        ntile(5) over (order by frequency) as f_score,
        monetary,
        ntile(5) over (order by monetary) as m_score
    from rfm_base
)

select
    *,
    multiIf(
        r_score >= 4 and (f_score >= 4 or m_score >= 4), 'Champions',
        r_score >= 4, 'Recent/New',
        r_score <= 2 and (f_score >= 4 or m_score >= 4), 'At Risk',
        'Others'
    ) as rfm_segment
from scored
