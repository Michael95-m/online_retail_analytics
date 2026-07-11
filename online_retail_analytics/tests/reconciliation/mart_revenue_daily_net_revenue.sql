select *
from {{ ref('mart_revenue_daily') }}
--WHERE net_revenue != merchandise_revenue + non_merchandise_revenue
where abs(net_revenue - (merchandise_revenue + non_merchandise_revenue)) > 0.01
