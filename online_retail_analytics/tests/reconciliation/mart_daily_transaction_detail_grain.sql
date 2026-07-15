select
    stock_code,
    country,
    report_date,
    is_cancelled,
    count(*)
from {{ ref('mart_daily_transaction_detail') }}
group by all
having count(*) > 1
