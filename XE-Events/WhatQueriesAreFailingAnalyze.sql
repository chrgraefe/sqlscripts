DECLARE
 @sqlHanddle VARBINARY = cast((0x03000C00F7CD343D435917013AA300000100000000000000) as varbinary)
,@startOffset INT = 28748
,@endOffset INT = 29078
;

select 
*
--,sqltext = SUBSTRING(text, 1610, 2002-1610)
,sqltext =  SUBSTRING (qt.text, (@startOffset / 2) + 1, ((CASE WHEN @endOffset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE @endOffset END - @startOffset) / 2) + 1) --AS [Individual Query]
	    --, SUBSTRING (qt.text, (@startOffset / 2) + 1, ((CASE WHEN @endOffset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE @endOffset END - @startOffset) / 2) + 1) AS [Individual Query]
from sys.dm_exec_sql_text(cast((0x03000C00F7CD343D435917013AA300000100000000000000) as varbinary))  qt






--IF EXISTS (SELECT OBJECT_ID('tempdb..#xmlprocess'))
--BEGIN
--	DROP TABLE #xmlprocess;
--END

--SELECT 
--  CAST ([t2].[event_data] AS XML) AS event_data
--, t2.file_offset
--, t2.file_name
--, cte1.event_session_id
----, ' AS event_predicate
--INTO #xmlprocess
--FROM ( 
--	SELECT 
--	  REPLACE(CONVERT(NVARCHAR(128),sesf.value),'.xel','*.xel') AS targetvalue
--	, ses.event_session_id
--	FROM sys.server_event_sessions ses
--	INNER JOIN sys.server_event_session_fields sesf ON ses.event_session_id = sesf.event_session_id
--	WHERE sesf.name = 'filename'
--	AND ses.name = 'WhatQueriesAreFailing'
--	) cte1
--OUTER APPLY sys.fn_xe_file_target_read_file(cte1.targetvalue,REPLACE(cte1.targetvalue, '*.xel', '*.xem'), NULL, NULL) t2
--;

WITH cteXmlProcessing AS
(
	SELECT 
	top 2694 /* 2690 -->*/
	DATEADD(mi,	DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), x.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS [err_timestamp],
	x.event_data.value('(event/action[@name="event_sequence"]/value)[1]', 'varchar(max)') AS [event_sequence],
	x.event_data.value('(event/data[@name="severity"]/value)[1]', 'bigint') AS [err_severity],
	x.event_data.value('(event/data[@name="error_number"]/value)[1]', 'bigint') AS [err_number],
	x.event_data.value('(event/data[@name="message"]/value)[1]', 'nvarchar(512)') AS [err_message],
	x.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text],
	CAST(x.event_data.value('(event/action[@name="tsql_stack"]/value)[1]', 'nvarchar(max)') AS XML) AS [tsql_stack],
	x.event_data xmlData
	FROM #xmlprocess x
)
,cteExtractOfTSQL AS
(
	SELECT
	[err_timestamp],
	[event_sequence],
	[err_severity],
	[err_number],
	[err_message],
	[sql_text],

	CONVERT(VARBINARY(64), [tsql_stack].value('(/frame[@level="1"]/@handle)[1]', 'char(64)'), 1)  AS [sql_handle1],
	[tsql_stack].value('(/frame[@level="1"]/@offsetStart)[1]', 'nvarchar(max)') AS [startOffset1],
	[tsql_stack].value('(/frame[@level="1"]/@offsetEnd)[1]', 'nvarchar(max)') AS [endeOffset1],

	CONVERT(VARBINARY(64), [tsql_stack].value('(/frame[@level="2"]/@handle)[1]', 'varchar(64)'), 1) AS [sql_handle2],
	[tsql_stack].value('(/frame[@level="2"]/@offsetStart)[1]', 'nvarchar(max)') AS [startOffset2],
	[tsql_stack].value('(/frame[@level="2"]/@offsetEnd)[1]', 'nvarchar(max)') AS [endeOffset2],

	CONVERT(VARBINARY(64), [tsql_stack].value('(/frame[@level="3"]/@handle)[1]', 'varchar(64)'), 1) AS [sql_handle3],
	[tsql_stack].value('(/frame[@level="3"]/@offsetStart)[1]', 'nvarchar(max)') AS [startOffset3],
	[tsql_stack].value('(/frame[@level="3"]/@offsetEnd)[1]', 'nvarchar(max)') AS [endeOffset3],

	CONVERT(VARBINARY(64), [tsql_stack].value('(/frame[@level="4"]/@handle)[1]', 'varchar(64)'), 1) AS [sql_handle4],
	[tsql_stack].value('(/frame[@level="4"]/@offsetStart)[1]', 'nvarchar(max)') AS [startOffset4],
	[tsql_stack].value('(/frame[@level="4"]/@offsetEnd)[1]', 'nvarchar(max)') AS [endeOffset4],

	CONVERT(VARBINARY(64), [tsql_stack].value('(/frame[@level="5"]/@handle)[1]', 'varchar(64)'), 1) AS [sql_handle5],
	[tsql_stack].value('(/frame[@level="5"]/@offsetStart)[1]', 'nvarchar(max)') AS [startOffset5],
	[tsql_stack].value('(/frame[@level="5"]/@offsetEnd)[1]', 'nvarchar(max)') AS [endeOffset5],

	[tsql_stack],
	xmlData
	FROM cteXmlProcessing cte
)
SELECT 
	[err_timestamp],
	[event_sequence],
	[err_severity],
	[err_number],
	[err_message],
	[sql_text],
	[sql_Level1] = (select SUBSTRING (qt.text, ([startOffset1] / 2) + 1, ((CASE WHEN [endeOffset1] = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE [endeOffset1] END - [startOffset1]) / 2) + 1) from sys.dm_exec_sql_text([sql_handle1])  qt),
	[sql_Level2] = (select SUBSTRING (qt.text, ([startOffset2] / 2) + 1, ((CASE WHEN [endeOffset2] = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE [endeOffset2] END - [startOffset2]) / 2) + 1) from sys.dm_exec_sql_text([sql_handle2])  qt),
	[sql_Level3] = (select SUBSTRING (qt.text, ([startOffset3] / 2) + 1, ((CASE WHEN [endeOffset3] = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE [endeOffset3] END - [startOffset3]) / 2) + 1) from sys.dm_exec_sql_text([sql_handle3])  qt),
	[sql_Level4] = (select SUBSTRING (qt.text, ([startOffset4] / 2) + 1, ((CASE WHEN [endeOffset4] = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE [endeOffset4] END - [startOffset4]) / 2) + 1) from sys.dm_exec_sql_text([sql_handle4])  qt),
	[sql_Level5] = (select SUBSTRING (qt.text, ([startOffset5] / 2) + 1, ((CASE WHEN [endeOffset5] = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE [endeOffset5] END - [startOffset4]) / 2) + 1) from sys.dm_exec_sql_text([sql_handle5])  qt),
	[tsql_stack]
FROM cteExtractOfTSQL
ORDER BY 
 [err_timestamp]
,[event_sequence]
