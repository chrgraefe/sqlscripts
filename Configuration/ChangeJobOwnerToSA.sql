-- Agent Jobs
select 
 J.name as SQL_Agent_Job_Name
,L.name as Job_Owner
,J.description 
,C.name
,'EXEC msdb.dbo.sp_update_job @job_id=N'''+cast(job_id as varchar(150))+''', @owner_login_name=N''sa'' ' as RunCode
from msdb.dbo.sysjobs j
inner join master.sys.syslogins L on J.owner_sid = L.sid
inner join msdb.dbo.syscategories C on C.category_id = J.category_id
where L.Name <> 'sa'
;