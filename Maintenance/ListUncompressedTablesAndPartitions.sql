SELECT  
SCHEMA_NAME(soParent.schema_id) AS [SchemaName]  
,OBJECT_NAME(soParent.object_id) AS [ObjectName]  
,[rows]  
,[data_compression_desc]  
,CASE WHEN [index_id] > 0 THEN (select top 1 siChild.name from sys.objects soChild, sys.indexes siChild
								where
									soChild.object_id = siChild.object_id
								AND soChild.object_id = soParent.object_id
)
	ELSE CAST([index_id] AS VARCHAR(100))
	END object_name
	,index_id 
FROM sys.partitions spParent
INNER JOIN sys.objects soParent
ON spParent.object_id = soParent.object_id  
WHERE data_compression = 0  
AND SCHEMA_NAME(soParent.schema_id) <> 'SYS'  
ORDER BY SchemaName, ObjectName
;