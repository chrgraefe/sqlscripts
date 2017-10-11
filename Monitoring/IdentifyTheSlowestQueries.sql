SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH  cteQueries AS
(
	SELECT 
	--TOP 150
	CAST(qs.total_elapsed_time / 1000000.0 AS NUMERIC(28, 2)) AS [Total Elapsed Duration (sec)]
	,qs.execution_count

	,SUBSTRING(qt.text, (qs.statement_start_offset / 2) + 1, ((CASE WHEN qs.statement_end_offset = -1 
																THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
																ELSE qs.statement_end_offset
																END - qs.statement_start_offset) / 2) + 1) AS [Individual Query]

	,qt.text [Parent Query]
	,DB_NAME(qt.dbid) AS DatabaseName
	,qp.query_plan
	FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
	CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
	WHERE 
		qs.last_execution_time > DATEADD(DD, -2, GETDATE())

	--order by qs.total_elapsed_time desc
)
select
 SUM([Total Elapsed Duration (sec)]) [Total Elapsed Duration (sec)]
,SUM(execution_count) [Execution Count]
,SUM([Total Elapsed Duration (sec)]) / SUM(execution_count) [Average Elapsed Duration (sec)]
,MIN([Total Elapsed Duration (sec)]) [Minimum Elapsed Duration (sec)]
,MAX([Total Elapsed Duration (sec)]) [Maximum Elapsed Duration (sec)]
,[Parent Query]
from cteQueries cte
WHERE
	DatabaseName = DB_NAME(DB_ID())
GROUP BY
	[Parent Query]
ORDER BY 
	[Total Elapsed Duration (sec)] ASC
;