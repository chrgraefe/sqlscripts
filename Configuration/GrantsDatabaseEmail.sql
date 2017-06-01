USE [msdb]
GO
CREATE USER [STACATO_BACKEND] FOR LOGIN [STACATO_BACKEND]
GO
EXEC sp_addrolemember N'DatabaseMailUserRole', N'STACATO_BACKEND'
GO
/* 
	SQL Server Agent muss vorher gestoppt werden, da sonst die folgende Abfrage blockiert wird. 
	Danach kann der Agent wieder gestartet werden.
 */
ALTER DATABASE msdb SET ENABLE_BROKER;
GO