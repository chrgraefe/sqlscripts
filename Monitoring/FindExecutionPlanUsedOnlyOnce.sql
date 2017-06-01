/* Finde Ausführungspläne, welche nur einmal genutzt werden */
SELECT 
  text
, cp.objtype
, cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE 
	cp.cacheobjtype = N'Compiled Plan'
AND cp.objtype IN(N'Adhoc', N'Prepared')
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC
OPTION (RECOMPILE)
;