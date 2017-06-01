USE [msdb]
GO

DECLARE 
 @SERACH_STRING NVARCHAR(MAX) = 'usp_Fill_ve__MASTER'
;

SELECT	
j.job_id,
s.srvname,
j.name,
js.step_id,
js.command,
j.enabled 
FROM	dbo.sysjobs j
INNER JOIN	dbo.sysjobsteps js
	ON	js.job_id = j.job_id 
INNER JOIN	master.dbo.sysservers s
	ON	s.srvid = j.originating_server_id
WHERE	js.command LIKE N'%' + @SERACH_STRING + '%'
;