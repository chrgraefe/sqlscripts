USE master;
GO
 
-- Dirty reads zulassen, um möglichst keine Ressourcen zu sperren!
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO
-- Tabellenvariable für die Speicherung der Ergebnisse
DECLARE @Result TABLE
(
    Database_Name         sysname        NOT NULL,
    Database_Owner        sysname        NULL,
    compatibility_level   VARCHAR(10)    NOT NULL,
    collation_Name        sysname        NOT NULL,
    snapshot_isolation    VARCHAR(5)     NOT NULL    DEFAULT ('OFF'),
    read_committed_SI     TINYINT        NOT NULL    DEFAULT (0),                
    Logical_Name          sysname        NOT NULL,
    type_desc             VARCHAR(10)    NOT NULL,
    physical_name         VARCHAR(255)   NOT NULL,
    size_MB               DECIMAL(18, 2) NOT NULL    DEFAULT (0),
    growth_MB             DECIMAL(18, 2) NOT NULL    DEFAULT (0),
    used_MB               DECIMAL(18, 2) NOT NULL    DEFAULT (0),
    is_percent_growth     TINYINT        NOT NULL    DEFAULT (0),
    
    PRIMARY KEY CLUSTERED
    (
        Database_Name,
        logical_name
    ),
    
    UNIQUE (physical_name)    
);
 
INSERT INTO @Result
EXEC    sys.sp_MSforeachdb @command1 = N'USE [?];
SELECT  DB_NAME(D.database_id)                            AS [Database Name],
        SP.name                                           AS [Database_Owner],
        D.compatibility_level,
        D.collation_name,
        D.snapshot_isolation_state_desc,
        D.is_read_committed_snapshot_on,
        MF.name,
        MF.type_desc,
        MF.physical_name,
        MF.size / 128.0                                   AS [size_MB],
        CASE WHEN MF.[is_percent_growth] = 1
            THEN MF.[size] * (MF.[growth] / 100.0)
            ELSE MF.[growth]
        END    / 128.0                                    AS [growth_MB],
        FILEPROPERTY(MF.name, ''spaceused'') / 128.0      AS [used_MB],
        MF.[is_percent_growth]
FROM    sys.databases AS D INNER JOIN sys.master_files AS MF
        ON    (D.database_id = MF.database_id) LEFT JOIN sys.server_principals AS SP
        ON    (D.owner_sid = SP.sid)
WHERE    D.database_id = DB_ID();';
 
-- Ausgabe des Ergebnisses für alle Datenbanken

WITH cteSUMMIERUNG AS 
(
	SELECT
	 R.Database_Name
	,R.type_desc TYP 
	,SUM(R.size_MB) size_MB
	,SUM(R.used_MB) used_MB
	FROM @Result AS R
	GROUP BY
	 R.Database_Name
	,R.type_desc
)

SELECT 
  SERVERPROPERTY('ServerName') AS [ServerName]
, SERVERPROPERTY('InstanceName') AS [InstanceName] 
, Database_Name
, TYP 
, size_MB
, used_MB
, CASE WHEN Database_Name <> 'TEMPDB' THEN CAST(1.0*used_MB/size_MB*100 AS NUMERIC(4,1)) ELSE 100 END used_Percent
FROM cteSUMMIERUNG AS R
;


-- Umstellung der Isolationsstufe
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO