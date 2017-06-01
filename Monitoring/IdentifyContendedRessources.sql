
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	tl1.resource_type
	, DB_NAME(tl1.resource_database_id) AS DatabaseName
	, tl1.resource_associated_entity_id
	, tl1.request_session_id
	, tl1.request_mode
	, tl1.request_status
	, CASE
		WHEN tl1.resource_type = 'OBJECT'
			THEN OBJECT_NAME(tl1.resource_associated_entity_id)
		WHEN tl1.resource_type IN ('KEY', 'PAGE', 'RID')
			THEN (SELECT OBJECT_NAME(OBJECT_ID)
					FROM sys.partitions s
					WHERE s.hobt_id = tl1.resource_associated_entity_id)
	END AS resource_type_name
	, t.text AS [Parent Query]
	, SUBSTRING (t.text,(r.statement_start_offset/2) + 1,
		((CASE WHEN r.statement_end_offset = -1
		THEN LEN(CONVERT(NVARCHAR(MAX), t.text)) * 2
		ELSE r.statement_end_offset
		END - r.statement_start_offset)/2) + 1) AS [Individual Query]
FROM sys.dm_tran_locks as tl1
INNER JOIN sys.dm_tran_locks as tl2
	ON tl1.resource_associated_entity_id = tl2.resource_associated_entity_id
		AND tl1.request_status <> tl2.request_status
		AND (tl1.resource_description = tl2.resource_description
		OR (tl1.resource_description IS NULL
		AND tl2.resource_description IS NULL))
INNER JOIN sys.dm_exec_connections c
	ON tl1.request_session_id = c.most_recent_session_id
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
LEFT OUTER JOIN sys.dm_exec_requests r ON c.connection_id = r.connection_id
ORDER BY tl1.resource_associated_entity_id, tl1.request_status
