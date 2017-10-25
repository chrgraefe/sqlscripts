/* Session */
CREATE EVENT SESSION [LongRunningQueries] ON SERVER
ADD EVENT sqlserver.sp_statement_completed
(
ACTION
(
package0.collect_system_time
,sqlserver.client_app_name
,sqlserver.client_hostname
,sqlserver.database_name
,sqlserver.plan_handle
,sqlserver.query_hash
,sqlserver.session_id
)
WHERE duration > 5000000 -- longer than 5 seconds
),
ADD EVENT sqlserver.sql_statement_completed
(
ACTION
(
package0.collect_system_time
,sqlserver.client_app_name
,sqlserver.client_hostname
,sqlserver.database_name
,sqlserver.plan_handle
,sqlserver.query_hash
,sqlserver.session_id
)
WHERE duration > 5000000 -- longer than 5 seconds
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
WHERE xes.name = 'LongRunningQueries'
AND xet.target_name = 'ring_buffer';

--*/

/**********************************************************/

SELECT xed.event_data.value('(@timestamp)[1]', 'datetime2') AS datetime_utc,
CONVERT(datetime2,SWITCHOFFSET(CONVERT(datetimeoffset,xed.event_data.value('(@timestamp)[1]', 'datetime2')),DATENAME(TzOffset, SYSDATETIMEOFFSET()))) AS datetime_local,
xed.event_data.value('(@name)[1]', 'varchar(50)') AS event_type,
xed.event_data.value('(data[@name="statement"]/value)[1]', 'varchar(max)') AS statement,
xed.event_data.value('(data[@name="duration"]/value)[1]', 'bigint')/1000 AS duration_ms,
xed.event_data.value('(data[@name="cpu_time"]/value)[1]', 'bigint')/1000 AS cpu_time_ms,
xed.event_data.value('(data[@name="physical_reads"]/value)[1]', 'bigint') AS physical_reads,
xed.event_data.value('(data[@name="logical_reads"]/value)[1]', 'bigint') AS logical_reads,
xed.event_data.value('(data[@name="writes"]/value)[1]', 'bigint') AS writes,
xed.event_data.value('(data[@name="row_count"]/value)[1]', 'bigint') AS row_count,
xed.event_data.value('(action[@name="database_name"]/value)[1]', 'varchar(255)') AS database_name,
xed.event_data.value('(action[@name="client_hostname"]/value)[1]', 'varchar(255)') AS client_hostname,
xed.event_data.value('(action[@name="client_app_name"]/value)[1]', 'varchar(255)') AS client_app_name
FROM #capture_waits_data
CROSS APPLY targetdata.nodes('//RingBufferTarget/event') AS xed (event_data)
WHERE 1=1
/* refine your search further than the XE session's filter
AND xed.event_data.value('(data[@name="statement"]/value)[1]', 'varchar(max)') = 'EXEC spDemoSproc'
--*/
/* find queries within a time range
AND xed.event_data.value('(@timestamp)[1]', 'datetime2') > CAST('20170925 09:57 AM' AS datetime2) AT TIME ZONE 'Eastern Standard Time'
--*/
/* Find highest resource consumption
ORDER BY
xed.event_data.value('(data[@name="duration"]/value)[1]', 'bigint') DESC
--xed.event_data.value('(data[@name="cpu_time"]/value)[1]', 'bigint') DESC
--xed.event_data.value('(data[@name="physical_reads"]/value)[1]', 'bigint') DESC
--xed.event_data.value('(data[@name="logical_reads"]/value)[1]', 'bigint') DESC
--xed.event_data.value('(data[@name="writes"]/value)[1]', 'bigint') DESC
--xed.event_data.value('(data[@name="row_count"]/value)[1]', 'bigint') DESC
--*/
