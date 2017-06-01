------------------------------------------------------------------------------------------- 
--Most Recent Database Backup for Each Database 
------------------------------------------------------------------------------------------- 
SELECT  
 CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server
,msdb.dbo.backupset.database_name
,MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date 
,(SELECT 
TOP (1)
 REPLACE(Command,
 CAST(YEAR(StartTime) AS VARCHAR(4)) 
+ RIGHT('0' + CAST(MONTH(StartTime)AS VARCHAR(2)),2) 
+ RIGHT('0' + CAST(DAY(StartTime)AS VARCHAR(2)),2) + '_' 
+ RIGHT('0' + CAST(DATEPART(HOUR, StartTime) AS VARCHAR(2)),2) 
+ RIGHT('0' + CAST(DATEPART(MINUTE, StartTime) AS VARCHAR(2)),2) 
+ RIGHT('0' + CAST(DATEPART(SECOND, StartTime) AS VARCHAR(2)),2) 
,
 CAST(YEAR(GETDATE()) AS VARCHAR(4)) 
+ RIGHT('0' + CAST(MONTH(GETDATE())AS VARCHAR(2)),2) 
+ RIGHT('0' + CAST(DAY(GETDATE())AS VARCHAR(2)),2) + '_' 
+ RIGHT('0' + CAST(DATEPART(HOUR, GETDATE()) AS VARCHAR(2)),2) 
+ RIGHT('0' + CAST(DATEPART(MINUTE, GETDATE()) AS VARCHAR(2)),2) 
+ RIGHT('0' + CAST(DATEPART(SECOND, GETDATE()) AS VARCHAR(2)),2) 
) BACKUP_COMMAND
FROM master.dbo.CommandLog
WHERE
	DatabaseName = msdb.dbo.backupset.database_name
AND Command LIKE N'BACKUP DATABASE %['+msdb.dbo.backupset.database_name+'%]%'
AND PATINDEX('%DIFFERENTIAL%', Command) = 0
ORDER BY ID DESC) BACKUP_COMMAND
 
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
WHERE  msdb..backupset.type = 'D' 
GROUP BY 
   msdb.dbo.backupset.database_name  
ORDER BY  
   last_db_backup_date
;