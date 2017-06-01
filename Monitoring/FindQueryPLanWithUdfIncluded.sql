WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),GetQueriesWithUDF AS ( 
	SELECT 
	  DISTINCT udf.value('(@FunctionName)[1]','varchar(100)') As UDF_Name
	, RIGHT(udf.value('(@FunctionName)[1]','varchar(100)'), Len(udf.value('(@FunctionName)[1]','varchar(100)'))-charindex('.',udf.value('(@FunctionName)[1]','varchar(100)'), charindex('.',udf.value('(@FunctionName)[1]','varchar(100)'),1)+1)) As Stripped_UDF_Name
	, QS.execution_count
	, CONVERT(float,cs.value('(.//RelOp/@EstimateRows)[1]','varchar(100)')) As EstimatedRows
	, QS.total_elapsed_time/1000000 As TotalElapsedTime_Sec
	, QS.max_elapsed_time/1000000 As max_elapsed_time_Sec
	, QS.total_elapsed_time/(1000000*qs.execution_count) AS [avg_elapsed_time_Sec]
	, QS.total_logical_reads
	, QS.total_logical_reads/qs.execution_count As avg_logical_reads
	, SUBSTRING(ST.[text],QS.statement_start_offset/2+1, (CASE WHEN QS.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), ST.[text])) * 2 ELSE QS.statement_end_offset END - QS.statement_start_offset)/2) AS [Query_Text]
	, ST.text As Parent_Query
	FROM sys.dm_exec_query_stats QS
	CROSS APPLY sys.dm_exec_sql_text (QS.sql_handle ) ST
	CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp 
	CROSS APPLY qp.query_plan.nodes('.//ComputeScalar') AS CompCsalar(cs) 
	CROSS APPLY cs.nodes('.//UserDefinedFunction[@FunctionName]') AS fn(udf) 
	Where DB_Name(qp.dbid) not in ('msdb','master','tempdb')
)
Select 
* 
From GetQueriesWithUDF 
Where 
	Query_text like '%'+Stripped_UDF_Name+'%'
ORDER BY EstimatedRows desc OPTION(MAXDOP 1, RECOMPILE); 