sp_msforeachdb ' IF ''?'' NOT IN (''msdb'',''master'',''tempdb'') 
BEGIN USE [?] 

SELECT top 100 DB_NAME() as [database], qs.total_worker_time /1000000 As TotalWorkerTime, 
QS.total_elapsed_time/1000000 As TotalElapsedTime_Sec, 
QS.total_elapsed_time/(1000000*qs.execution_count) AS [avg_elapsed_time_Sec], 
QS.execution_count,
QS.total_logical_reads/QS.execution_count As Avg_logical_reads, 
QS.max_logical_writes, ST.text AS ParentQueryText, 
SUBSTRING(ST.[text],QS.statement_start_offset/2+1, 
 (CASE WHEN QS.statement_end_offset = -1 
   THEN LEN(CONVERT(nvarchar(max), ST.[text])) * 2 
  ELSE QS.statement_end_offset 
  END - QS.statement_start_offset)/2) AS [Query Text] ,
QP.query_plan ,
O.type_desc
FROM sys.dm_exec_query_stats QS 
CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST 
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) QP 
LEFT JOIN Sys.objects O ON 
O.object_id =St.objectid Where O.type_desc like ''%Function%'' 
ORDER by qs.total_worker_time DESC ;
END '