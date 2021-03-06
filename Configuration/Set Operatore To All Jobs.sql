USE [msdb]
GO


DECLARE @job_id UNIQUEIDENTIFIER

DECLARE db_cursor CURSOR FORWARD_ONLY READ_ONLY
FOR  
SELECT job_id
FROM msdb.dbo.sysjobs;


OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @job_id

WHILE @@FETCH_STATUS = 0  
BEGIN  
		
	EXEC msdb.dbo.sp_update_job @job_id=@job_id, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@notify_email_operator_name=N'The DBA Team'

    FETCH NEXT FROM db_cursor INTO @job_id
END  

CLOSE db_cursor  
DEALLOCATE db_cursor 



GO




