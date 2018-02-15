WITH allColumnsOfDatabase AS
(
    /* get all columns of tables, views and table-value-functions */
    SELECT 
    sc.name ColumnName
    ,case
        when sysType.name IN (N'char', N'nchar', N'varchar', N'nvarchar') then sysType.name+'('+IIF(sc.max_length=-1, 'max' ,cast(sc.max_length as varchar(5))) +')'
        when sysType.name IN (N'decimal') then sysType.name+'('+ cast(sc.precision as varchar(2)) + ', ' + cast(sc.scale as varchar(2)) + ')'
        else sysType.name
    end TypeSyntax
    FROM sys.columns sc
    INNER JOIN sys.types sysType
        ON sysType.user_type_id = sc.user_type_id
    WHERE
        EXISTS (SELECT 1 FROM sys.objects so WHERE so.object_id = sc.object_id AND so.is_ms_shipped = 0)

    UNION

    /* get all computed columns of tables, views and table-value-functions */
    SELECT 
    sc.name ColumnName
    ,case
        when sysType.name IN (N'char', N'nchar', N'varchar', N'nvarchar') then sysType.name+'('+IIF(sc.max_length=-1, 'max' ,cast(sc.max_length as varchar(5))) +')'
        when sysType.name IN (N'decimal') then sysType.name+'('+ cast(sc.precision as varchar(2)) + ', ' + cast(sc.scale as varchar(2)) + ')'
        else sysType.name
    end TypeSyntax
    FROM sys.computed_columns sc
    INNER JOIN sys.types sysType
        ON sysType.user_type_id = sc.user_type_id
    WHERE
        EXISTS (SELECT 1 FROM sys.objects so WHERE so.object_id = sc.object_id AND so.is_ms_shipped = 0)

    UNION

    /* get all parameters of functions and procedures */
    SELECT 
    CASE
        WHEN param.Name = N'' THEN N'ReturnValueOfScalarFunction'
        ELSE param.Name
     END ColumnName
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
,groupedColumnsByType AS
(
    SELECT 
     cte.ColumnName
    ,cte.TypeSyntax
    FROM allColumnsOfDatabase cte
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
select 
 cte3.ColumnName
, 'Column' TypeOf
,SCHEMA_NAME(so.schema_id) ObjectSchema
,so.name ObjectName
,so.type_desc ObjectDescription
,case
    when sysType.name IN (N'char', N'varchar') then sysType.name+'('+IIF(sc.max_length=-1, 'max' ,cast(sc.max_length as varchar(5))) +')'
    when sysType.name IN (N'nchar', N'nvarchar') then sysType.name+'('+IIF(sc.max_length=-1, 'max' ,cast(sc.max_length/2 as varchar(5))) +')'
    when sysType.name IN (N'decimal') then sysType.name+'('+ cast(sc.precision as varchar(2)) + ', ' + cast(sc.scale as varchar(2)) + ')'
    else sysType.name
end TypeSyntax
from columnsWithDifferentTypesButSameName cte3
inner join sys.columns sc 
    ON sc.name = cte3.ColumnName
INNER JOIN sys.types sysType
    ON sysType.user_type_id = sc.user_type_id
INNER JOIN sys.objects so 
    ON so.object_id = sc.object_id
WHERE
    so.is_ms_shipped = CAST(0 as BIT)

UNION

select 
 cte3.ColumnName
, 'Computed Column' TypeOf
,SCHEMA_NAME(so.schema_id) ObjectSchema
,so.name ObjectName
,so.type_desc ObjectDescription
,case
    when sysType.name IN (N'char', N'varchar') then sysType.name+'('+IIF(sc.max_length=-1, 'max' ,cast(sc.max_length as varchar(5))) +')'
    when sysType.name IN (N'nchar', N'nvarchar') then sysType.name+'('+IIF(sc.max_length=-1, 'max' ,cast(sc.max_length/2 as varchar(5))) +')'
    when sysType.name IN (N'decimal') then sysType.name+'('+ cast(sc.precision as varchar(2)) + ', ' + cast(sc.scale as varchar(2)) + ')'
    else sysType.name
end TypeSyntax
from columnsWithDifferentTypesButSameName cte3
inner join sys.computed_columns sc 
    ON sc.name = cte3.ColumnName
INNER JOIN sys.types sysType
    ON sysType.user_type_id = sc.user_type_id
INNER JOIN sys.objects so 
    ON so.object_id = sc.object_id
WHERE
    so.is_ms_shipped = CAST(0 as BIT)

UNION

select 
 CASE
    WHEN param.Name = N'' THEN N'ReturnValueOfScalarFunction'
    ELSE REPLACE(param.Name, N'@', N'')
 END ColumnName
, 'Parameter' TypeOf
, SCHEMA_NAME(so.schema_id) ObjectSchema
, so.name ObjectName
, so.type_desc ObjectDescription
, case
        when sysType.name IN (N'char', N'nchar', N'varchar', N'nvarchar') then sysType.name+'('+IIF(param.max_length=-1, 'max' ,cast(param.max_length as varchar(5))) +')'
        when sysType.name IN (N'decimal') then sysType.name+'('+ cast(param.precision as varchar(2)) + ', ' + cast(param.scale as varchar(2)) + ')'
        else sysType.name
    end TypeSyntax
from columnsWithDifferentTypesButSameName cte3
INNER JOIN sys.parameters param
    ON cte3.ColumnName = CASE WHEN param.Name = N'' THEN N'ReturnValueOfScalarFunction' ELSE REPLACE(param.Name, N'@', N'') END
inner join sys.objects so 
    ON so.object_id = param.object_id
INNER JOIN sys.types sysType
    ON sysType.user_type_id = param.user_type_id

ORDER BY
 cte3.ColumnName
,ObjectName