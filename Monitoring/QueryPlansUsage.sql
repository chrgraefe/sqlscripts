/* Query plans and their usage */
SELECT 
  DB_NAME(st.dbid) DataBaseName
, st.[text] SqlText
, deq.query_plan QueryPlan
, cp.objtype ObjectType
, cp.size_in_bytes SizeInBytes
, cp.usecounts AnzahlAusfuehrungen
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS deq
ORDER BY cp.size_in_bytes DESC
OPTION (RECOMPILE);