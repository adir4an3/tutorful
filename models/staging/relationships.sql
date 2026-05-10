with cte as (
    select * from {{source ('source', 'relationships')}}
)

select 
ID as relationship_id
, Tutor as tutor_id
, Student as student_id

from cte