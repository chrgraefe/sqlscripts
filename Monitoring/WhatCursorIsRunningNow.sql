
SELECT session_id,
	cursor_id,
	name,
	properties,
	creation_time,
	is_open,
	is_async_population,
	is_close_on_commit,
	fetch_status,
	fetch_buffer_size,
	fetch_buffer_start,
	ansi_position,
	worker_time / 1000 as worker_ms,
	reads,
	writes,
	dormant_duration / 1000  dormant_duration_sec,
	SUBSTRING (qt.text, (statement_start_offset / 2) + 1, ((CASE WHEN statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE statement_end_offset END - statement_start_offset) / 2) + 1) AS [Individual Query]
FROM sys.dm_exec_cursors(0)
CROSS APPLY sys.dm_exec_sql_text(sql_handle)as qt

