EXEC msdb.dbo.sp_add_schedule @schedule_name =N'CollectorSchedule_Every_15min', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080709, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
	GO 

		
EXEC msdb.dbo.sp_add_schedule @schedule_name =N'RunAsSQLAgentServiceStartSchedule', 
		@enabled=1, 
		@freq_type=64, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080709, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
	GO

		
EXEC msdb.dbo.sp_add_schedule @schedule_name =N'CollectorSchedule_Every_30min', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080709, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
	GO

		
EXEC msdb.dbo.sp_add_schedule @schedule_name =N'CollectorSchedule_Every_6h', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=6, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080709, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
	GO


SELECT * from sysschedules
order by name

--EXEC msdb.dbo.sp_delete_schedule @schedule_id = 32