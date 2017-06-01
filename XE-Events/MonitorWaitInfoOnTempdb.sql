/** 2008r2 and older */
USE master;
GO

--Create the event 
IF EXISTS ( SELECT *
				FROM sys.server_event_sessions
				WHERE name = 'MonitorWaitInfoOnTempdb' )
				DROP EVENT SESSION MonitorWaitInfoOnTempdb ON SERVER 

GO

CREATE EVENT SESSION MonitorWaitInfoOnTempdb ON SERVER 
--We are looking at wait info only
ADD EVENT sqlos.wait_info
( 
   --Add additional columns to track
   ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.session_id, sqlserver.tsql_stack)  
    WHERE sqlserver.database_id = 2 --filter database id = 2 i.e tempdb
    --This allows us to track wait statistics at database granularity
) --As a best practise use asynchronous file target, reduces overhead.
ADD TARGET package0.asynchronous_file_target
( SET	filename='D:\LOG\XEvents\MonitorWaitInfoOnTempdb.xel',
		metadatafile='D:\LOG\XEvents\MonitorWaitInfoOnTempdb.xem',
		max_file_size = 5,
		max_rollover_files = 5
)
WITH (MAX_DISPATCH_LATENCY = 30SECONDS)
GO
GO
--Now start the session
ALTER EVENT SESSION MonitorWaitInfoOnTempdb ON SERVER STATE = START;
GO


/* ====================================================================================*/
/* ====================================================================================*/
/* ====================================================================================*/


IF EXISTS (SELECT OBJECT_ID('tempdb..#xmlprocess'))
BEGIN
	DROP TABLE #xmlprocess;
END

SELECT 
  CAST ([t2].[event_data] AS XML) AS event_data
, t2.file_offset
, t2.file_name
, cte1.event_session_id
--, ' AS event_predicate
INTO #xmlprocess
FROM ( 
	SELECT 
	  REPLACE(CONVERT(NVARCHAR(128),sesf.value),'.xel','*.xel') AS targetvalue
	, ses.event_session_id
	FROM sys.server_event_sessions ses
	INNER JOIN sys.server_event_session_fields sesf ON ses.event_session_id = sesf.event_session_id
	WHERE sesf.name = 'filename'
	AND ses.name = 'MonitorWaitInfoOnTempdb'
	) cte1
OUTER APPLY sys.fn_xe_file_target_read_file(cte1.targetvalue,REPLACE(cte1.targetvalue, '*.xel', '*.xem'), NULL, NULL) t2
;

SELECT
  FinalData.R.value ('@name', 'nvarchar(50)') AS EventName,  
  FinalData.R.value ('data(data/value)[1]', 'nvarchar(50)') AS wait_typeValue,
  FinalData.R.value ('data(data/text)[1]', 'nvarchar(50)') AS wait_typeName,
  FinalData.R.value ('data(data/value)[5]', 'int') AS total_duration,
  FinalData.R.value ('data(data/value)[6]', 'int') AS signal_duration,
  FinalData.R.value ('(action/.)[1]', 'nvarchar(50)') AS DatabaseID,
  FinalData.R.value ('(action/.)[2]', 'nvarchar(50)') AS SQLText,
  FinalData.R.value ('(action/.)[3]', 'nvarchar(50)') AS SessionID
  ,AsyncFileData.event_data
FROM #xmlprocess AsyncFileData
CROSS APPLY event_data.nodes ('//event') AS FinalData (R)
GO
 


SELECT wait_typeName 
      , SUM(total_duration) AS total_duration
      , SUM(signal_duration) AS total_signal_duration
FROM (
SELECT
  FinalData.R.value ('@name', 'nvarchar(50)') AS EventName,  
  FinalData.R.value ('data(data/value)[1]', 'nvarchar(50)') AS wait_typeValue,
  FinalData.R.value ('data(data/text)[1]', 'nvarchar(50)') AS wait_typeName,
  FinalData.R.value ('data(data/value)[5]', 'int') AS total_duration,
  FinalData.R.value ('data(data/value)[6]', 'int') AS signal_duration,
  FinalData.R.value ('(action/.)[1]', 'nvarchar(50)') AS DatabaseID,
  FinalData.R.value ('(action/.)[2]', 'nvarchar(50)') AS SQLText,
  FinalData.R.value ('(action/.)[3]', 'nvarchar(50)') AS SessionID
  ,AsyncFileData.event_data
  
FROM #xmlprocess AsyncFileData
CROSS APPLY event_data.nodes ('//event') AS FinalData (R)) xyz
WHERE wait_typeName NOT IN ('SLEEP_TASK')
 GROUP BY wait_typeName
 ORDER BY total_duration
 GO
 
