SELECT
    *
FROM {{ ref('mart_revenue_daily') }}
--WHERE net_revenue != merchandise_revenue + non_merchandise_revenue
WHERE abs(net_revenue - (merchandise_revenue + non_merchandise_revenue)) > 0.01
