/*
  mart_churn_reactivation
  -----------------------
  One row per student per churn/reactivation event pair, across all time.

  The business question asks for February 2026 specifically, but the logic
  is intentionally generic. February 2026 (or any other window) is applied
  as a filter at query time, not hardcoded here. This makes the model
  reusable for any reporting period.

  Example query for February 2026:
    select * from mart_churn_reactivation
    where churn_date between '2026-02-01' and '2026-02-28'
       or reactivation_date between '2026-02-01' and '2026-02-28'

  Extended metrics included beyond the core ask:
  - days_until_reactivation: useful for understanding recovery lag
  - churn_event_number: identifies students who churn multiple times
  - is_repeat_churner: quick flag for high-risk student segment
*/

with

gaps as (
    select * from {{ ref('student_lesson_gaps') }}
),

-- Count lifetime churn events per student for repeat-churner analysis
churn_counts as (
    select
        student_id,
        count(*) as total_churn_events
    from gaps
    group by student_id
)


    select
        g.student_id,
        g.churn_date,
        g.reactivation_date,
        g.previous_lesson_date         as last_lesson_before_churn,
        g.days_since_previous_lesson   as gap_days,
        date_diff(
            g.reactivation_date,
            g.churn_date,
            day
        )                              as days_until_reactivation,

        -- Rank churn events per student chronologically
        row_number() over (
            partition by g.student_id
            order by g.churn_date
        )                              as churn_event_number,

        -- Flag students who have churned more than once
        case when cc.total_churn_events > 1 then true else false end
            as is_repeat_churner,

        cc.total_churn_events

    from gaps g
    inner join churn_counts cc
        on g.student_id = cc.student_id
