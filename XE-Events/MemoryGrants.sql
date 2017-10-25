/* Session */

CREATE EVENT SESSION [MemoryUsage] ON SERVER
ADD EVENT sqlserver.query_memory_grant_usage
(
ACTION
(
sqlserver.query_hash
,sqlserver.query_plan_hash
,sqlserver.sql_text
)
WHERE granted_memory_kb > 2048 --2 MB
)
ADD TARGET package0.ring_buffer(SET max_events_limit=(0 /*unlimited*/),max_memory=(1048576 /*1 GB*/))
WITH (STARTUP_STATE=OFF,MAX_DISPATCH_LATENCY = 5SECONDS)

/* Query */

--/* Comment this part out after you run it once, unless you want to refresh the temp table.

IF OBJECT_ID('tempdb..#capture_waits_data') IS NOT NULL
DROP TABLE #capture_waits_data

SELECT CAST(target_data as xml) AS targetdata
INTO #capture_waits_data
FROM sys.dm_xe_session_targets xet
JOIN sys.dm_xe_sessions xes
ON xes.address = xet.event_session_address
WHERE xes.name = 'MemoryUsage'
AND xet.target_name = 'ring_buffer';

--*/

/**********************************************************/

SELECT xed.event_data.value('(@timestamp)[1]', 'datetime2') AS datetime_utc,
DATEADD(hh,DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP),xed.event_data.value('(@timestamp)[1]', 'datetime2')) AS datetime_local,
xed.event_data.value('(@name)[1]', 'varchar(50)') AS event_type,
xed.event_data.value('(data[@name="ideal_memory_kb"]/value)[1]', 'bigint') AS ideal_memory_kb,
xed.event_data.value('(data[@name="granted_memory_kb"]/value)[1]', 'bigint') AS granted_memory_kb,
xed.event_data.value('(data[@name="used_memory_kb"]/value)[1]', 'bigint') AS used_memory_kb,
xed.event_data.value('(data[@name="usage_percent"]/value)[1]', 'int') AS usage_percent,
xed.event_data.value('(data[@name="dop"]/value)[1]', 'int') AS dop,
xed.event_data.value('(data[@name="granted_percent"]/value)[1]', 'int') AS granted_percent,
xed.event_data.value('(action[@name="sql_text"]/value)[1]', 'varchar(max)') AS sql_text,
xed.event_data.value('(action[@name="query_plan_hash"]/value)[1]', 'numeric(20)') AS query_plan_hash,
xed.event_data.value('(action[@name="query_hash"]/value)[1]', 'numeric(20)') AS query_hash
FROM #capture_waits_data
CROSS APPLY targetdata.nodes('//RingBufferTarget/event') AS xed (event_data)
WHERE 1=1
--/* Search for large memory grants.
AND xed.event_data.value('(data[@name="used_memory_kb"]/value)[1]', 'bigint') > 5120 -- 5MB
--*/
--/* Search for grants too large for the actual used
AND xed.event_data.value('(data[@name="usage_percent"]/value)[1]', 'bigint') < 50
--*/