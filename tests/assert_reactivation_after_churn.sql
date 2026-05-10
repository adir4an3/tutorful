-- Singular test: reactivation_date must always be after churn_date.
-- A reactivation is by definition a lesson that ends a churn period,
-- so reactivation_date must be strictly after churn_date.
-- Any row violating this indicates a logic error in student_lesson_gaps.

select
    student_id,
    churn_date,
    reactivation_date
from {{ ref('student_churn_reactivation') }}
where reactivation_date <= churn_date
