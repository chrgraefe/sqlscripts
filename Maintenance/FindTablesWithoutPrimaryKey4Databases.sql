IF OBJECT_ID('tempdb..#tempTable') IS NOT NULL
	DROP TABLE tempdb..#tempTable


CREATE TABLE #tempTable
(
 SERVERNAME VARCHAR(255)
,[Database] VARCHAR(255)
,[SCHEMA] VARCHAR(255)
,NAME VARCHAR(255)
,CRDATE DATETIME
);

IF @@MICROSOFTVERSION = 134219767
BEGIN
	INSERT INTO #tempTable
	EXEC sp_MSforeachdb
	'
	USE [?]
	 
	SELECT 
	 @@SERVERNAME SERVERNAME
	,DB_NAME() [Database]
	,su.name [SCHEMA]
	,so.NAME 
	,so.CRDATE 
	FROM sysobjects so 
	inner join sysusers su ON su.uid = so.uid
	WHERE 
		so.xtype = ''U'' 
	AND DB_NAME() <> ''tempdb''
	AND OBJECTPROPERTY(so.id, ''IsMSShipped'') = 0
	AND so.NAME NOT IN ( 
		SELECT 
		so.NAME 
		FROM sysobjects so 
		inner join sysindexes si ON 
			so.ID = si.ID 
		WHERE 
			so.xtype = ''U'' 
		AND si.indid = 1 
		) 
	';

END
ELSE
BEGIN
	INSERT INTO #tempTable
	EXEC sp_MSforeachdb
	'
	USE [?]
	 
	SELECT 
	 @@SERVERNAME SERVERNAME
	,DB_NAME() [Database]
	,OBJECT_SCHEMA_NAME(so.id, DB_ID()) [SCHEMA]
	,so.NAME 
	,so.CRDATE 
	FROM sysobjects so 
	WHERE 
		so.xtype = ''U'' 
	AND DB_NAME() <> ''tempdb''
	AND OBJECTPROPERTY(so.id, ''IsMSShipped'') = 0
	AND so.NAME NOT IN ( 
		SELECT 
		so.NAME 
		FROM sysobjects so 
		inner join sysindexes si ON 
			so.ID = si.ID 
		WHERE 
			so.xtype = ''U'' 
		AND si.indid = 1 
		) 
	';
END

	SELECT * FROM #tempTable
	ORDER BY SERVERNAME, [Database], [SCHEMA], NAME
