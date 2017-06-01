/** 2008r2 and older */
USE master;
GO
-- Create the Event Session
IF EXISTS ( SELECT *
				FROM sys.server_event_sessions
				WHERE name = 'AuditDeprecated' )
	DROP EVENT SESSION AuditDeprecated
    ON SERVER;
GO

EXECUTE xp_create_subdir 'D:\LOG\XEvents';
GO


CREATE EVENT SESSION [AuditDeprecated] ON SERVER
ADD EVENT sqlserver.deprecation_announcement (
	ACTION ( sqlserver.database_id, 
	sqlserver.nt_username, sqlserver.sql_text, sqlserver.username,sqlserver.session_nt_username,
	sqlserver.client_app_name, sqlserver.session_id, sqlserver.client_hostname)
	WHERE  
		[sqlserver].[database_id] > 4 --exclude system databases
	AND [sqlserver].[client_app_name] <> 'Microsoft SQL Server Management Studio - Transact-SQL IntelliSense'),
ADD EVENT sqlserver.deprecation_final_support (
	ACTION ( sqlserver.database_id, 
	sqlserver.nt_username, sqlserver.sql_text, sqlserver.username,sqlserver.session_nt_username,
	sqlserver.client_app_name, sqlserver.session_id, sqlserver.client_hostname)
	WHERE  
		[sqlserver].[database_id] > 4
	AND [sqlserver].[client_app_name] <> 'Microsoft SQL Server Management Studio - Transact-SQL IntelliSense')
ADD TARGET package0.asynchronous_file_target (  SET filename = N'D:\LOG\XEvents\AuditDeprecated.xel', max_rollover_files = ( 25 ) )
WITH (  MAX_MEMORY = 4096 KB
		, EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
		, MAX_DISPATCH_LATENCY = 30 SECONDS
		, MAX_EVENT_SIZE = 0 KB
		, MEMORY_PARTITION_MODE = NONE
		, TRACK_CAUSALITY = ON
		, STARTUP_STATE = OFF );
GO

ALTER EVENT SESSION AuditDeprecated ON SERVER STATE = START;
 
 
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
INTO #xmlprocess
FROM ( 
	SELECT 
	  REPLACE(CONVERT(NVARCHAR(128),sesf.value),'.xel','*.xel') AS targetvalue
	, ses.event_session_id
	FROM sys.server_event_sessions ses
	INNER JOIN sys.server_event_session_fields sesf ON ses.event_session_id = sesf.event_session_id
	WHERE sesf.name = 'filename'
	AND ses.name = 'AuditDeprecated'
	) cte1
OUTER APPLY sys.fn_xe_file_target_read_file(cte1.targetvalue,REPLACE(cte1.targetvalue, '*.xel', '*.xem'), NULL, NULL) t2
;

SELECT 
  x.event_data.value('(event/@name)[1]', 'varchar(50)') AS event_name
, x.event_data.value('(event/@package)[1]', 'varchar(50)') AS package_name
, DATEADD(hh, DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP)
, x.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS [timestamp]
, event_data.value('(event/data[@name="feature_id"]/value)[1]','bigint') AS feature_id
, event_data.value('(event/data[@name="feature"]/value)[1]','varchar(max)') AS feature
, event_data.value('(event/data[@name="message"]/value)[1]','varchar(max)') AS message
, event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(max)') AS client_app_name
, event_data.value('(event/action[@name="client_connection_id"]/value)[1]', 'uniqueidentifier') AS client_connection_id
, event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(max)') AS client_hostname
, event_data.value('(event/action[@name="context_info"]/value)[1]', 'varbinary(max)') AS context_info
, event_data.value('(event/action[@name="database_id"]/value)[1]', 'int') AS database_id
, event_data.value('(event/action[@name="database_name"]/value)[1]', 'varchar(max)') AS database_name
, event_data.value('(event/action[@name="nt_username"]/value)[1]', 'varchar(max)') AS nt_username
, event_data.value('(event/action[@name="session_id"]/value)[1]', 'int') AS session_id
, event_data.value('(event/action[@name="session_nt_username"]/value)[1]', 'varchar(max)') AS session_nt_username
, event_data.value('(event/action[@name="sql_text"]/value)[1]', 'varchar(max)') AS sql_text
, event_data.value('(event/action[@name="username"]/value)[1]', 'varchar(max)') AS username
, event_data
FROM #xmlprocess x
LEFT OUTER JOIN sys.server_event_session_events sese ON 
		x.event_data.value('(event/@name)[1]', 'varchar(50)') = sese.name
	AND x.event_session_id = sese.event_session_id
ORDER BY 
 timestamp
, event_data.value('(event/action[@name="event_sequence"]/value)[1]', 'varchar(max)')
;