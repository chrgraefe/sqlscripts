select 
(case when D.is_read_only = 1 then '-- Remove ReadOnly State' when D.state_desc = 'ONLINE' then 'ALTER AUTHORIZATION on DATABASE::['+D.name+'] to [SA];' else '-- Turn On ' end) as CommandToRun
,D.name as Database_Name
, D.database_id Database_ID
,L.Name as Login_Name
,D.state_desc as Current_State
,D.is_read_only as [ReadOnly]
from master.sys.databases D
inner join master.sys.syslogins L on D.owner_sid = L.sid
where L.Name <> 'sa'
order by D.Name
;