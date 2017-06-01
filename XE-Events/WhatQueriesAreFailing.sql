/** 2008r2 and older */
USE master;
GO

-- Create the Event Session
IF EXISTS ( SELECT *
				FROM sys.server_event_sessions
				WHERE name = 'WhatQueriesAreFailing' )
	DROP EVENT SESSION WhatQueriesAreFailing
    ON SERVER;
GO
--Create an extended event session
CREATE EVENT SESSION [WhatQueriesAreFailing] ON SERVER
ADD EVENT sqlserver.error_reported
(
	ACTION (sqlserver.sql_text, sqlserver.tsql_stack, sqlserver.database_id, sqlserver.username)
	WHERE ([severity]> 10)
)
ADD TARGET package0.asynchronous_file_target
(set 	filename = 'D:\LOG\XEvents\WhatQueriesAreFailing.xel' ,
		metadatafile = 'D:\LOG\XEvents\WhatQueriesAreFailing.xem',
		max_file_size = 5,
		max_rollover_files = 5)
WITH (MAX_DISPATCH_LATENCY = 30SECONDS)
GO

-- Start the session
ALTER EVENT SESSION WhatQueriesAreFailing ON SERVER STATE = START
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
	AND ses.name = 'WhatQueriesAreFailing'
	) cte1
OUTER APPLY sys.fn_xe_file_target_read_file(cte1.targetvalue,REPLACE(cte1.targetvalue, '*.xel', '*.xem'), NULL, NULL) t2
;

SELECT 
DATEADD(mi,	DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
x.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS [err_timestamp],
x.event_data.value('(event/data[@name="severity"]/value)[1]', 'bigint') AS [err_severity],
x.event_data.value('(event/data[@name="error_number"]/value)[1]', 'bigint') AS [err_number],
x.event_data.value('(event/data[@name="message"]/value)[1]', 'nvarchar(512)') AS [err_message],
x.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text],
x.event_data.value('(event/action[@name="tsql_stack"]/value)[1]', 'nvarchar(max)') AS [tsql_stack],
x.event_data
FROM #xmlprocess x
ORDER BY 
 [err_timestamp]
, event_data.value('(event/action[@name="event_sequence"]/value)[1]', 'varchar(max)')
;