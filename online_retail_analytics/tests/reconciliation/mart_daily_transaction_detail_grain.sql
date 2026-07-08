SELECT  
 stock_code, country, report_dt, is_cancelled, count(*)
FROM {{ ref('mart_daily_transaction_detail') }}
group by all 
having count(*) > 1 