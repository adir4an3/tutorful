-- Singular test: a student cannot churn twice on the same date.
-- Each churn event is derived from a unique gap between consecutive
-- lessons, so student_id + churn_date should be unique.

select
    student_id,
    churn_date,
    count(*) as cnt
from {{ ref('student_churn_reactivation') }}
group by student_id, churn_date
having count(*) > 1
