

EXEC msdb.dbo.sp_delete_operator @name=N'The DBA Team';

EXEC msdb.dbo.sp_add_operator @name=N'The DBA Team', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'chr.Graefe@gmail.com', 
		@category_name=N'[Uncategorized]'
		;



