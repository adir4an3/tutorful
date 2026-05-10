with cte as (
    select * from {{source ('source', 'lesson_bookings')}}
)

select 
`LessonsB ID` as booking_id, 
lesson_id as lesson_id, 
parse_timestamp('%D %R',start_at) as start_time, 

parse_timestamp('%D %R',finish_at) as finish_time, 
status as lesson_status

from cte