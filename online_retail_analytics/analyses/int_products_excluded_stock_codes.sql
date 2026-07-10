"""
Just checking which stock codes are in the invoices staging table but not in the products table.
"""

select
 t1.stock_code, count(*)
from {{ ref('stg_invoices') }} t1
left anti join
 {{ ref('int_products') }} t2
on t1.stock_code = t2.stock_code
group by 1
order by 2 desc
