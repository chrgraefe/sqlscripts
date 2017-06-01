/* Indexnutzung in der aktuellen Datenbank */
SELECT
  DB_NAME(ixUS.database_id) AS database__name
, OBJECT_SCHEMA_NAME(SI.object_id, ixUS.database_id) as Schema__Name
, Object_name(SI.object_id, ixUS.database_id) AS object__name
, SI.name AS index__name
, ixUS.index_id
, (ixUS.user_seeks + ixUS.user_scans + ixUS.user_lookups)/ CASE WHEN ixUS.user_updates = 0 THEN 1 ELSE ixUS.user_updates END AS [r_per_w]
, ixUS.user_seeks
, ixUS.user_scans
, ixUS.user_lookups
, (ixUS.user_seeks + ixUS.user_scans + ixUS.user_lookups) AS total_reads
, ixUS.user_updates AS total_writes
FROM sys.dm_db_index_usage_stats ixUS
INNER JOIN sys.indexes SI ON 
		SI.object_id = ixUS.object_id
	AND SI.index_id = ixUS.index_id
ORDER BY 
r_per_w, 
OBJECT_NAME(ixUS.object_id, IxUS.database_id), 
ixUS.index_id;