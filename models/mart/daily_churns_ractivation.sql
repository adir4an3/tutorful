/*
  mart_churn_daily
  ----------------
  Daily aggregated churn and reactivation counts.

  This model directly answers the business question:
  "For February 2026, what were the daily churn and reactivation volumes?"

  It pivots the event-level mart_churn_reactivation into a calendar-grain
  view with one row per date, showing both churn and reactivation volumes
  side by side.

  The date spine uses the range of dates present in the data, ensuring
  days with zero events appear as 0 rather than being absent from results.
  This is important for accurate trend visualisation.

  To query February 2026 specifically:
    select * from mart_churn_daily
    where event_date between '2026-02-01' and '2026-02-28'
    order by event_date
*/

with

-- All churn events unpivoted to date-grain
churn_dates as (
    select
        churn_date      as event_date,
        'churn'         as event_type,
        student_id
    from {{ ref('student_chrun_reactivation') }}
),

-- All reactivation events unpivoted to date-grain
reactivation_dates as (
    select
        reactivation_date   as event_date,
        'reactivation'      as event_type,
        student_id
    from {{ ref('student_chrun_reactivation') }}
),

all_events as (
    select * from churn_dates
    union all
    select * from reactivation_dates
),

-- Generate a date spine across the full range of events
date_spine as (
    select date_day event_date
    from {{ref('dim_date')}}
    where date_day between (select min(event_date) from all_events)
                   and     (select max(event_date) from all_events)     
    
),

-- Aggregate to daily counts
daily_counts as (
    select
        event_date,
        countif(event_type = 'churn')        as churn_count,
        countif(event_type = 'reactivation') as reactivation_count,
        count(*)                              as total_events
    from all_events
    group by event_date
)

-- Join spine to counts so zero-event days are represented
select
    ds.event_date,
    coalesce(dc.churn_count, 0)         as churn_count,
    coalesce(dc.reactivation_count, 0)  as reactivation_count,
    coalesce(dc.total_events, 0)        as total_events,
    extract(year from ds.event_date)    as event_year,
    extract(month from ds.event_date)   as event_month,
    format_date('%A', ds.event_date)    as day_of_week
from date_spine ds
left join daily_counts dc
    on ds.event_date = dc.event_date