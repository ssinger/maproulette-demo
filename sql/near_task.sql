select t.task_id from task t
   left outer join task_assignment ta on (t.task_id = 
       ta.task_id
       and (now()-ta.start_time 
        <'30 minutes'::interval
        or ta.end_time is not null))
        , task_state ts
where t.state_id=ts.state_id and ts.name='ACTIVE'
                          and ta.task_assignment_id is null
                          order by ST_Distance(t.centroid,ST_MakePoint(74,90)) 
limit 5
