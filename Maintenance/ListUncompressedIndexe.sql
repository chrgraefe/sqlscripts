SELECT 
DISTINCT
  [s].[name] AS [Schema]
, [t].[name] AS [Table]
, [i].[name] AS [Index]
, [p].[partition_number] AS [Partition]
, p.rows [NumberOfRowsInThisPartition]
, [p].[data_compression_desc] AS [Compression]
, 'ALTER INDEX ['+ i.name +'] ON ['+s.name+'].['+t.name+'] REBUILD PARTITION = ' + CASE WHEN ds.type='PS' THEN CAST([p].[partition_number] AS VARCHAR(10)) ELSE 'ALL' END + ' WITH (DATA_COMPRESSION = PAGE)' Query
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.indexes AS [i] ON [i].[object_id] = [p].[object_id]
INNER JOIN sys.data_spaces ds ON ds.data_space_id = i.data_space_id
WHERE [p].[index_id] > 1
AND [p].[data_compression_desc] = 'NONE'
AND i.name IS NOT NULL
order by s.name, t.name, i.name, [p].[partition_number]
;


