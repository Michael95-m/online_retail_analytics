with date_spine as (
    select toDate('2009-01-01') + number as date_day
    from numbers(
        toUInt32(toDate('2012-12-31') - toDate('2009-01-01')) + 1
    )
)

select
    date_day,
    toYear(date_day) as year,
    toQuarter(date_day) as quarter,
    toMonth(date_day) as month,
    toStartOfMonth(date_day) as month_start_date,
    dateName('month', date_day) as month_name,
    toISOWeek(date_day) as week_of_year,
    toDayOfYear(date_day) as day_of_year,
    toDayOfMonth(date_day) as day_of_month,
    toDayOfWeek(date_day) as day_of_week,
    dateName('weekday', date_day) as day_name,
    toDayOfWeek(date_day) in (6, 7) as is_weekend
from date_spine
