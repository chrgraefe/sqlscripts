SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT DISTINCT TOP 20
	qs.last_execution_time
	, qt.text AS [Parent Query]
	, DB_NAME(qt.dbid) AS DatabaseName
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
WHERE qt.text LIKE '%CREATE PROCEDURE%usp_Maske_GetTransportByAuftragsNr%'
ORDER BY qs.last_execution_time DESC