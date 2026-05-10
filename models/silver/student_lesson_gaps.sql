/*
  int_lesson_gaps
  ---------------
  Identifies every churn and reactivation event per student across the
  full history of completed lessons.

  Logic:
  1. Deduplicate to one row per student per lesson date (a student can
     have multiple bookings on the same day — only the date matters for
     the 30-day gap calculation).
  2. Use LAG() to find the previous completed lesson date per student.
  3. Calculate the gap in days between consecutive completed lessons.
  4. Where gap > 30 days:
       - churn_date    = previous_lesson_date + 30 days
         (the student became churned 30 days after their last lesson)
       - reactivation_date = current lesson_date
         (the lesson that ends the gap is the reactivation event)

  A student can generate multiple churn/reactivation pairs over their
  lifetime. Each gap > 30 days produces exactly one churn event and one
  reactivation event.

  Note: The very first lesson a student ever takes cannot produce a
  reactivation (there is no prior lesson to form a gap). This is handled
  naturally by LAG() returning NULL for the first row.
*/

with

-- One row per student per lesson date to avoid double-counting same-day lessons
daily_lessons as (
    select distinct
        student_id,
        finish_date as lesson_date
    from {{ ref('bookings_student') }}
),

-- Calculate gap from previous lesson for each student
lesson_gaps as (
    select
        student_id,
        lesson_date,
        lag(lesson_date) over (
            partition by student_id
            order by lesson_date
        ) as previous_lesson_date,

        date_diff(
            lesson_date,
            lag(lesson_date) over (
                partition by student_id
                order by lesson_date
            ),
            day
        ) as days_since_previous_lesson
    from daily_lessons
),

-- Flag gaps that exceed the 30-day churn threshold
churn_events as (
    select
        student_id,
        lesson_date                                           as reactivation_date,
        previous_lesson_date,
        days_since_previous_lesson,
        date_add(previous_lesson_date, interval 30 day)      as churn_date,
        true                                                  as is_churn_gap
    from lesson_gaps
    where days_since_previous_lesson > 30
)

select
    student_id,
    previous_lesson_date,
    reactivation_date,
    days_since_previous_lesson,
    churn_date,
    true  as has_churn,
    true  as has_reactivation
from churn_events