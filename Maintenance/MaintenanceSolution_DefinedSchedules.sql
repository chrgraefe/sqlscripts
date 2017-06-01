

IF NOT EXISTS (select * from [msdb].[dbo].[sysschedules] where name = N'DB_WARTUNG_SO_0000')
BEGIN

	EXEC msdb.dbo.sp_add_jobschedule 
			@name=N'DB_WARTUNG_SO_0000', 
			@job_name=N'DatabaseBackup - USER_DATABASES - FULL',
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20140211, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959
	;

	EXEC msdb.dbo.sp_attach_schedule
			@job_name='DatabaseBackup - SYSTEM_DATABASES - FULL', 
			@schedule_name='DB_WARTUNG_SO_0000'
	;

	EXEC msdb.dbo.sp_attach_schedule
			@job_name='CommandLog Cleanup', 
			@schedule_name='DB_WARTUNG_SO_0000'		
	;


	EXEC msdb.dbo.sp_attach_schedule
			@job_name='Output File Cleanup', 
			@schedule_name='DB_WARTUNG_SO_0000'		
	;

END
GO


IF NOT EXISTS (select * from [msdb].[dbo].[sysschedules] where name = N'DB_WARTUNG_SA_0000')
BEGIN
		
	EXEC msdb.dbo.sp_add_jobschedule 
			@name=N'DB_WARTUNG_SA_0000', 
			@job_name='IndexOptimize - USER_DATABASES',
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=64, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20140211, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959 
	;

	EXEC msdb.dbo.sp_attach_schedule
			@job_name='DatabaseIntegrityCheck - SYSTEM_DATABASES', 
			@schedule_name='DB_WARTUNG_SA_0000'		
	;

END
GO

IF NOT EXISTS (select * from [msdb].[dbo].[sysschedules] where name = N'DB_WARTUNG_SO_1200')
BEGIN
		
EXEC msdb.dbo.sp_add_jobschedule 
		@name=N'DB_WARTUNG_SO_1200', 
		@job_name='DatabaseIntegrityCheck - USER_DATABASES',
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20140211, 
		@active_end_date=99991231, 
		@active_start_time=120000, 
		@active_end_time=235959
;

END
GO
	
IF NOT EXISTS (select * from [msdb].[dbo].[sysschedules] where name = N'DB_WARTUNG_MO_SA_0000')
BEGIN
		
	EXEC msdb.dbo.sp_add_jobschedule 
			@name=N'DB_WARTUNG_MO_SA_0000', 
			@job_name='DatabaseBackup - USER_DATABASES - DIFF',
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=126, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20140211, 
			@active_end_date=99991231, 
			@active_start_time=0, 
			@active_end_time=235959 
	;
			
	EXEC msdb.dbo.sp_attach_schedule
			@job_name='DatabaseBackup - USER_DATABASES - LOG', 
			@schedule_name='DB_WARTUNG_MO_SA_0000'		
	;

END
GO

