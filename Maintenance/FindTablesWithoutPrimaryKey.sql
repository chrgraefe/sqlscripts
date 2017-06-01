SELECT
  t.table_catalog [Database]
, t.table_schema [Schema]
, t.table_name [TableName]
FROM information_schema.tables t
LEFT JOIN
    (
        SELECT
              table_catalog
            , table_schema
            , table_name
        FROM information_schema.table_constraints
        WHERE constraint_type = 'PRIMARY KEY'
    ) SubQuery ON
    t.TABLE_CATALOG = SubQuery.TABLE_CATALOG AND
    t.TABLE_NAME = SubQuery.TABLE_NAME AND
    t.TABLE_SCHEMA = SubQuery.TABLE_SCHEMA
WHERE SubQuery.TABLE_CATALOG IS NULL AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY [Database], [Schema], [TableName]
;