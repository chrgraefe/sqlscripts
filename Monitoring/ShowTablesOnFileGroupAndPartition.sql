SELECT 
  OBJECT_SCHEMA_NAME(t.object_id) AS schema_name 
, t.name AS table_name
, i.index_id
, i.type_desc
, i.name AS index_name
, p.partition_number
, fg.name AS filegroup_name
, p.rows AS rows 
FROM sys.tables t 
INNER JOIN sys.indexes i ON 
	t.object_id = i.object_id 
INNER JOIN sys.partitions p ON 
	i.object_id=p.object_id 
AND i.index_id=p.index_id 
LEFT OUTER JOIN sys.partition_schemes ps ON 
	i.data_space_id=ps.data_space_id 
LEFT OUTER JOIN sys.destination_data_spaces dds ON 
	ps.data_space_id=dds.partition_scheme_id 
AND p.partition_number=dds.destination_id 
INNER JOIN sys.filegroups fg ON 
	COALESCE(dds.data_space_id, i.data_space_id)=fg.data_space_id 
where t.name = 'T_BV_RDE_DPS_SENDUNG'
AND OBJECT_SCHEMA_NAME(t.object_id) = 'DPS_DATA'
ORDER BY
	schema_name, table_name