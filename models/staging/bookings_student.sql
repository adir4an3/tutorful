/*
  stg_lessons
  -----------
  Cleans and joins the three raw tables into a single flat model of
  completed lessons with student context.

  Key decisions:
  - Only 'completed' bookings are retained. Cancelled lessons do NOT
    reset the 30-day churn clock and are excluded entirely.
  - raw_subjects is intentionally excluded. Subject-level analysis is
    not required by the business question and the nested set structure
    (left/right/roll-up) would require additional modelling effort that
    is out of scope.
  - Column names are standardised to snake_case.
  - Timestamps are cast to DATE for churn gap calculations. Time of day
    is not relevant to the 30-day churn definition.
*/


with 
  lesson_bookings as (
    select 
    booking_id 
    , lesson_id
    , start_time
    , finish_time
    , date(start_time) start_date
    , date(finish_time) finish_date
    , lower(trim(lesson_status)) lesson_status


    from {{ ref('lesson_bookings') }}
    where lower(trim(lesson_status)) = 'completed'
  ),

  lessons as 
   (select 
    lesson_id
    , relationship_id

   from {{ref('lessons')}}),

   relationships as 
   (select 
   relationship_id
   , student_id
   
   from {{ref('relationships')}})



select 
 lb.booking_id
 ,r.relationship_id
 ,r.student_id
 ,lb.lesson_id
 ,lb.start_time
 ,lb.finish_time
 ,lb.start_date
 ,lb.finish_date
 ,lb.lesson_status



 from 
 lesson_bookings lb 
 inner join lessons l using(lesson_id)
 inner join relationships r using(relationship_id)
