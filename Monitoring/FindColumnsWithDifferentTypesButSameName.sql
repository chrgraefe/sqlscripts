;WITH allColumnsOfDatabaseObjColumn AS
(
    /* get all columns of tables, views and table-value-functions */
    SELECT 
      sc.name ColumnName
    , 'Column' TypeOf
    , SCHEMA_NAME(so.schema_id) ObjectSchema
    , so.name ObjectName
    , so.type_desc ObjectDescription
    , case
        when sysType.name IN (N'char', N'nchar', N'varchar', N'nvarchar') then sysType.name+'('+IIF(sc.max_length=-1, 'max' ,cast(sc.max_length as varchar(5))) +')'
        when sysType.name IN (N'decimal') then sysType.name+'('+ cast(sc.precision as varchar(2)) + ', ' + cast(sc.scale as varchar(2)) + ')'
        else sysType.name
    end TypeSyntax
    FROM sys.columns sc
    INNER JOIN sys.types sysType
        ON sysType.user_type_id = sc.user_type_id
    inner join sys.objects so 
        ON so.object_id = sc.object_id
    WHERE
        EXISTS (SELECT 1 FROM sys.objects so WHERE so.object_id = sc.object_id AND so.is_ms_shipped = 0)
)
,allColumnsOfDatabaseObjComputedColumn AS
(
    /* get all computed columns of tables, views and table-value-functions */
    SELECT 
    sc.name ColumnName
    , 'ComputedColumn' TypeOf
    , SCHEMA_NAME(so.schema_id) ObjectSchema
    , so.name ObjectName
    , so.type_desc ObjectDescription
    ,case
        when sysType.name IN (N'char', N'nchar', N'varchar', N'nvarchar') then sysType.name+'('+IIF(sc.max_length=-1, 'max' ,cast(sc.max_length as varchar(5))) +')'
        when sysType.name IN (N'decimal') then sysType.name+'('+ cast(sc.precision as varchar(2)) + ', ' + cast(sc.scale as varchar(2)) + ')'
        else sysType.name
    end TypeSyntax
    FROM sys.computed_columns sc
    INNER JOIN sys.types sysType
        ON sysType.user_type_id = sc.user_type_id
    inner join sys.objects so 
        ON so.object_id = sc.object_id
    WHERE
        EXISTS (SELECT 1 FROM sys.objects so WHERE so.object_id = sc.object_id AND so.is_ms_shipped = 0)
)
,allColumnsOfDatabaseObjFunctionAndProcedures AS
(
    /* get all parameters of functions and procedures */
    SELECT 
      CASE
        WHEN param.Name = N'' THEN N'ReturnValueOfScalarFunction'
        ELSE REPLACE(param.Name, N'@', N'')
      END ColumnName
    , 'Parameter' TypeOf
    , SCHEMA_NAME(so.schema_id) ObjectSchema
    , so.name ObjectName
    , so.type_desc ObjectDescription

    ,CASE
            when sysType.name IN (N'char', N'nchar', N'varchar', N'nvarchar') then sysType.name+'('+IIF(param.max_length=-1, 'max' ,cast(param.max_length as varchar(5))) +')'
            when sysType.name IN (N'decimal') then sysType.name+'('+ cast(param.precision as varchar(2)) + ', ' + cast(param.scale as varchar(2)) + ')'
            else sysType.name
        end TypeSyntax
    from sys.parameters param
    inner join sys.objects so 
        ON so.object_id = param.object_id
    INNER JOIN sys.types sysType
        ON sysType.user_type_id = param.user_type_id
)
,AggregationOfAllTypes AS
(
    SELECT 
      ColumnName
    , TypeOf
    , ObjectSchema
    , ObjectName
    , ObjectDescription
    , TypeSyntax
    FROM allColumnsOfDatabaseObjColumn

    UNION

    SELECT 
      ColumnName
    , TypeOf
    , ObjectSchema
    , ObjectName
    , ObjectDescription
    , TypeSyntax
    FROM allColumnsOfDatabaseObjComputedColumn

    UNION

    SELECT 
      ColumnName
    , TypeOf
    , ObjectSchema
    , ObjectName
    , ObjectDescription
    , TypeSyntax
    FROM allColumnsOfDatabaseObjFunctionAndProcedures
)
,groupedColumnsByType AS
(
    SELECT 
     cte.ColumnName
    ,cte.TypeSyntax
    FROM AggregationOfAllTypes cte
    GROUP BY
    cte.ColumnName
    ,cte.TypeSyntax
)
,columnsWithDifferentTypesButSameName AS
(
    SELECT
    cte2.ColumnName
    FROM groupedColumnsByType cte2
    GROUP BY
    cte2.ColumnName
    HAVING COUNT(1) > 1
)
SELECT
  cteAllColumns.ColumnName
, cteAllColumns.TypeOf
, cteAllColumns.ObjectSchema
, cteAllColumns.ObjectName
, cteAllColumns.ObjectDescription
, cteAllColumns.TypeSyntax
FROM columnsWithDifferentTypesButSameName cteRelevantColumns
INNER JOIN AggregationOfAllTypes cteAllColumns 
    ON cteRelevantColumns.ColumnName = cteAllColumns.ColumnName
ORDER BY
 cteAllColumns.ColumnName
,cteAllColumns.ObjectName