/* Session */

CREATE EVENT SESSION [QueryTimeouts] ON SERVER
ADD EVENT sqlserver.sql_statement_completed
(
ACTION
(
sqlserver.session_id
,sqlserver.query_hash
,sqlserver.tsql_stack
)
),
ADD EVENT sqlserver.sql_statement_starting
(
ACTION
(
sqlserver.session_id
,sqlserver.query_hash
,sqlserver.tsql_stack
)
)
ADD TARGET package0.pair_matching
(
SET
begin_event = 'sqlserver.sql_statement_starting',
begin_matching_actions = 'sqlserver.session_id, sqlserver.tsql_stack',
end_event = 'sqlserver.sql_statement_completed',
end_matching_actions = 'sqlserver.session_id, sqlserver.tsql_stack',
respond_to_memory_pressure = 0
)
WITH (MAX_DISPATCH_LATENCY=5 SECONDS, TRACK_CAUSALITY=ON, STARTUP_STATE=OFF)

/* Query */
-- Create XML variable to hold Target Data
DECLARE @target_data XML
SELECT @target_data =
CAST(target_data AS XML)
FROM sys.dm_xe_sessions AS s
JOIN sys.dm_xe_session_targets AS t
ON t.event_session_address = s.address
WHERE s.name = 'QueryTimeouts'
AND t.target_name = 'pair_matching'

-- Query XML variable to get Target Execution information
SELECT
@target_data.value('(PairingTarget/@orphanCount)[1]', 'int') AS orphanCount,
@target_data.value('(PairingTarget/@matchedCount)[1]', 'int') AS matchedCount,
COALESCE(@target_data.value('(PairingTarget/@memoryPressureDroppedCount)[1]', 'int'),0) AS memoryPressureDroppedCount

-- Query the XML variable to get the Target Data
SELECT
n.value('(event/action[@name="session_id"]/value)[1]', 'int') as session_id,
n.value('(event/@name)[1]', 'varchar(50)') AS event_name,
n.value('(event/data[@name="statement"]/value)[1]', 'varchar(8000)') as statement,
NULLIF(n.value('(event/action[@name="query_hash"]/value)[1]', 'numeric(20)'),0) as query_hash_numeric,
n.value('(event/@timestamp)[1]', 'datetime2') AS datetime_utc,
DATEADD(hh,DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP),n.value('(event/@timestamp)[1]', 'datetime2')) AS datetime_local,
n.value('(event/action[@name="tsql_stack"]/text)[1]', 'varchar(max)') as tsql_stack
FROM
(
SELECT td.query('.') as n
FROM @target_data.nodes('PairingTarget/event') AS q(td)
) as tab
--Excluding this currently running query.
WHERE n.value('(event/action[@name="session_id"]/value)[1]', 'int') <> @@SPID
ORDER BY session_id