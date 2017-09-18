select 
  w.worker_address
, t.last_wait_type 
from sys.dm_os_workers w, sys.dm_os_tasks t 
where 
    w.task_address = t.task_address 
and t.session_id = 66
;