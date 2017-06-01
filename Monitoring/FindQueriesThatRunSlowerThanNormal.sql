
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT TOP 100
qs.execution_count AS [Runs]
, (qs.total_worker_time - qs.last_worker_time) / (qs.execution_count - 1) AS [Avg time]
, qs.last_worker_time AS [Last time]
, (qs.last_worker_time - ((qs.total_worker_time - qs.last_worker_time) /
(qs.execution_count - 1))) AS [Time Deviation]
, CASE WHEN qs.last_worker_time = 0
		THEN 100
	ELSE (qs.last_worker_time - ((qs.total_worker_time -
	qs.last_worker_time) / (qs.execution_count - 1))) * 100
	END
		/ (((qs.total_worker_time - qs.last_worker_time) /
(qs.execution_count - 1.0))) AS [% Time Deviation]
,qs.last_logical_reads + qs.last_logical_writes + qs.last_physical_reads AS [Last IO]
, ((qs.total_logical_reads + qs.total_logical_writes +
qs.total_physical_reads) -
(qs.last_logical_reads + last_logical_writes
+ qs.last_physical_reads))
/ (qs.execution_count - 1) AS [Avg IO]
, SUBSTRING (qt.text,(qs.statement_start_offset/2) + 1,
	((CASE WHEN qs.statement_end_offset = -1
	THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
	ELSE qs.statement_end_offset
	END - qs.statement_start_offset)/2) + 1) AS [Individual Query]
, qt.text AS [Parent Query]
, DB_NAME(qt.dbid) AS [DatabaseName]
INTO #SlowQueries
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) qt
WHERE qs.execution_count > 1
AND qs.total_worker_time != qs.last_worker_time
ORDER BY [% Time Deviation] DESC

SELECT TOP 100 [Runs]
	, [Avg time]
	, [Last time]
	, [Time Deviation]
	, [% Time Deviation]
	, [Last IO]
	, [Avg IO]
	, [Last IO] - [Avg IO] AS [IO Deviation]
	, CASE WHEN [Avg IO] = 0
			THEN 0
		ELSE ([Last IO]- [Avg IO]) * 100 / [Avg IO]
	  END AS [% IO Deviation]
	, [Individual Query]
	, [Parent Query]
	, [DatabaseName]
INTO #SlowQueriesByIO
FROM #SlowQueries
ORDER BY [% Time Deviation] DESC

SELECT TOP 100
	[Runs]
	, [Avg time]
	, [Last time]
	, [Time Deviation]
	, [% Time Deviation]
	, [Last IO]
	, [Avg IO]
	, [IO Deviation]
	, [% IO Deviation]
	, [Impedance] = [% Time Deviation] - [% IO Deviation]
	, [Individual Query]
	, [Parent Query]
	, [DatabaseName]
FROM #SlowQueriesByIO
WHERE [% Time Deviation] - [% IO Deviation] > 20
ORDER BY [Impedance] DESC

DROP TABLE #SlowQueries
DROP TABLE #SlowQueriesByIO