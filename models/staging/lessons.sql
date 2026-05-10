with cte as (
    select * from {{source ('source', 'lessons')}}
)

select 
id as lesson_id
, relationship_id as relationship_id
, subject_id as subject_id

from cte