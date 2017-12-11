DECLARE @TEXT NVARCHAR(128)= 'pub_GetDetails'

-- Get the schema name, table name, and table type for:
-- Table names
SELECT
       TABLE_SCHEMA  AS 'Object Schema'
      ,TABLE_NAME    AS 'Object Name'
      ,TABLE_TYPE    AS 'Object Type'
      ,'Table Name'  AS 'TEXT Location'
FROM  INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%'+@Text+'%'
UNION

-- Get the schema name, view name, and view type for:
-- View Body
SELECT
 SCHEMA_NAME(so.schema_id) COLLATE DATABASE_DEFAULT AS 'Object Schema'
,so.[name] COLLATE DATABASE_DEFAULT AS 'Object Name'
,so.[type_desc] COLLATE DATABASE_DEFAULT AS 'Object Type'
,'View Body' COLLATE DATABASE_DEFAULT AS 'TEXT Location'
FROM  sys.sql_modules sm
inner join sys.objects so ON sm.object_id = so.object_id
WHERE 
	sm.definition LIKE '%'+@Text+'%'
AND so.[type] = 'V' /* View */
UNION

 --Column names
SELECT
      TABLE_SCHEMA   AS 'Object Schema'
      ,COLUMN_NAME   AS 'Object Name'
      ,'COLUMN'      AS 'Object Type'
      ,'Column Name' AS 'TEXT Location'
FROM  INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%'+@Text+'%'

UNION

-- Function or procedure bodies
SELECT
      SPECIFIC_SCHEMA     AS 'Object Schema'
      ,ROUTINE_NAME       AS 'Object Name'
      ,ROUTINE_TYPE       AS 'Object Type'
      ,ROUTINE_DEFINITION AS 'TEXT Location'
FROM  INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_DEFINITION LIKE '%'+@Text+'%'
      AND (ROUTINE_TYPE = 'function' OR ROUTINE_TYPE = 'procedure')

UNION

-- Synonyms
SELECT
 SCHEMA_NAME(syn.schema_id) COLLATE DATABASE_DEFAULT AS 'Object Schema'
,syn.[name] COLLATE DATABASE_DEFAULT AS 'Object Name'
,syn.[type_desc] COLLATE DATABASE_DEFAULT AS 'Object Type'
,syn.base_object_name COLLATE DATABASE_DEFAULT  AS 'TEXT Location'
FROM  sys.synonyms syn
WHERE syn.base_object_name LIKE '%'+@Text+'%'
;