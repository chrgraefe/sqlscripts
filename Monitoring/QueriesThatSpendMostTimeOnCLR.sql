SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT TOP 20
	qs.total_clr_time
	, qs.total_elapsed_time AS [Duration]
	, qs.total_worker_time AS [Time on CPU]
	, qs.total_elapsed_time - qs.total_worker_time AS [Time waiting]
	, qs.total_logical_reads
	, qs.total_logical_writes
	, qs.execution_count
	, SUBSTRING (qt.text,qs.statement_start_offset/2 + 1,
	((CASE WHEN qs.statement_end_offset = -1
		THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
		ELSE qs.statement_end_offset
	  END - qs.statement_start_offset)/2) + 1) AS [Individual Query]
	, qt.text AS [Parent Query]
	, DB_NAME(qt.dbid) AS DatabaseName
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) as qt
WHERE qs.total_clr_time > 0
ORDER BY qs.total_clr_time DESC
