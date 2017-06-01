USE [Master]
GO 
SELECT 
  db.name AS 'db_name'  
, db.cmptlevel CompatLevel
, db.crdate CreateDate
,	CASE  
		WHEN files.groupid = 1 THEN 'data'
		WHEN files.groupid = 0 THEN 'log'
	END as 'file_type'	
, files.filename 'PhysicalFilename'
, files.name AS 'LogicalFilename'
, (files.size * 8 / 1024) AS 'file_size(MB)' -- file size in MB
FROM 
	dbo.sysdatabases db
JOIN
	dbo.sysaltfiles files ON
	(db.dbid=files.dbid)
WHERE
	db.dbid NOT IN ('1','2','3','4')
ORDER BY
	db.name