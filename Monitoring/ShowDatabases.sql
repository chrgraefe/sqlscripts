USE [Master]
GO 

SELECT 
  @@SERVERNAME InstanceName
, db.name AS DbName  
, case 
		when CHARINDEX('8.00.', @@VERSION, 1) > 0 then 'MS SQL 2000'
		when CHARINDEX('9.0.',  @@VERSION, 1) > 0 then 'MS SQL 2005'
		when CHARINDEX('10.0.', @@VERSION, 1) > 0 then 'MS SQL 2008'
		when CHARINDEX('10.5.', @@VERSION, 1) > 0 then 'MS SQL 2008 R2'
		when CHARINDEX('11.0.', @@VERSION, 1) > 0 then 'MS SQL 2012'
		when CHARINDEX('12.0.', @@VERSION, 1) > 0 then 'MS SQL 2014'
		when CHARINDEX('13.0.', @@VERSION, 1) > 0 then 'MS SQL 2016'
		when CHARINDEX('14.0.', @@VERSION, 1) > 0 then 'MS SQL 2017'
		else 'unbekannt'
  end InstanceVersion
, CASE db.cmptlevel 
		WHEN  80 THEN 'MS SQL 2000'
		WHEN  90 THEN 'MS SQL 2005'
		WHEN 100 THEN 'MS SQL 2008'
		WHEN 105 THEN 'MS SQL 2008 R2'
		WHEN 110 THEN 'MS SQL 2012'
		WHEN 120 THEN 'MS SQL 2014'
		WHEN 130 THEN 'MS SQL 2016'
		WHEN 140 THEN 'MS SQL 2017'
		ELSE 'unbekannt' 
  END DbCompatLevel
, cast(db.crdate as smalldatetime) CreateDate
, case
		when (512 & db.status) = 512 then 1
		else 0
  end IsOffline 
, (select SUM(files.size * 8 / 1024) from dbo.sysaltfiles files where (db.dbid=files.dbid) and files.groupid = 1) DataFileSizeInMb
, (select SUM(files.size * 8 / 1024) from dbo.sysaltfiles files where (db.dbid=files.dbid) and files.groupid = 0) LogFileSizeInMb
, CAST(GETDATE() AS SMALLDATETIME) ZEITSTEMPEL
FROM dbo.sysdatabases db
WHERE db.dbid NOT IN (1, 2, 3, 4) /* 1=master, 2=tempdb, 3=model, 4=msdb */
ORDER BY DbName;