use lfg;
go

SELECT SCHEMA_NAME([schema_id]) AS [schema_name]
      ,t.[name] AS [table_name]
      ,i.[name] AS [index_name]
      ,i.[type_desc] AS [index_type]
      ,ps.[name] AS [partition_scheme]
      ,pf.[name] AS [partition_function]
      ,p.[partition_number]
      ,r.[value] AS [current_partition_range_boundary_value]
      ,p.[rows] AS [partition_rows]
      ,p.[data_compression_desc]
FROM sys.tables t
INNER JOIN sys.partitions p ON p.[object_id] = t.[object_id]
INNER JOIN sys.indexes i ON p.[object_id] = i.[object_id]
                           AND p.[index_id] = i.[index_id]
INNER JOIN sys.data_spaces ds ON i.[data_space_id] = ds.[data_space_id]
INNER JOIN sys.partition_schemes ps ON ds.[data_space_id] = ps.[data_space_id]
INNER JOIN sys.partition_functions pf ON ps.[function_id] = pf.[function_id]
LEFT JOIN sys.partition_range_values AS r ON pf.[function_id] = r.[function_id]
    AND r.[boundary_id] = p.[partition_number]
GROUP BY SCHEMA_NAME([schema_id])
        ,t.[name]
        ,i.[name]
        ,i.[type_desc]
        ,ps.[name]
        ,pf.[name]
        ,p.[partition_number]
        ,r.[value]
        ,p.[rows]
        ,p.[data_compression_desc]
ORDER BY SCHEMA_NAME([schema_id])
        ,t.[name]
        ,i.[name]
        ,p.[partition_number];