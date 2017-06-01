SELECT 
  [s].[name] AS [Schema]
, [t].[name] AS [Table]
, [p].[partition_number] AS [Partition]
, p.rows [NumberOfRowsInThisPartition]
, [p].[data_compression_desc] AS [Compression]
, 'ALTER TABLE ['+s.name+'].['+ t.name +'] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)' Query
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE [p].[index_id] = 0
AND [p].[data_compression_desc] = 'NONE'
order by
4 DESC
--  [s].[name]
--, [t].[name]
;