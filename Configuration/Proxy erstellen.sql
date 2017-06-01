USE [msdb]
GO

/* Gewünschte Anmeldeinformationen */
CREATE CREDENTIAL SV_TECHNI
WITH IDENTITY = 'SV\TECHNI', SECRET = 'RailionAG2008';
GO

/* Proxy erstellen */
EXEC dbo.sp_add_proxy
    @proxy_name = 'PROXXY_SV_TECHNI',
    @enabled = 1,
    @description = 'Technischer User für PowerShell',
    @credential_name = 'SV_TECHNI' ;
GO

/* Zugriffsrechte für SQL-Agent-User erteilen */
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'PROXXY_SV_TECHNI', @login_name=N'NT SERVICE\SQLSERVERAGENT'
GO

/* Test ob Proxy angelegt wurde*/
SELECT * FROM msdb.dbo.sysproxies

/* Liste aller verfügbaren SQL-Agent-Subsysteme */
EXEC sp_enum_sqlagent_subsystems 
GO

/* Zugriff für den Proxy auf das gewünschte Subsystem festelegen */
EXEC msdb.dbo.sp_grant_proxy_to_subsystem 
@proxy_name=N'PROXXY_SV_TECHNI', 
@subsystem_id = 3 /* CMDEXEC */
--@subsystem_id = 11 /* SSIS */
--@subsystem_id = 12 /* Powershell */
GO 

/* Zeige alle zugewiesenen Proxies */
EXEC dbo.sp_enum_proxy_for_subsystem

/* Auflistung der Proxies mit zugewiesenen Login */
EXEC dbo.sp_enum_login_for_proxy 
GO




--USE [msdb]
--GO

--/* Gewünschte Anmeldeinformationen */
--CREATE CREDENTIAL SV_SQLMDWPROXY
--WITH IDENTITY = 'SV\SQLMDWPROXY', SECRET = 'UMmXFnq4xShledikAkpy';
--GO

--/* Proxy erstellen */
--EXEC dbo.sp_add_proxy
--    @proxy_name = 'PROXXY_SV_SQLMDWPROXY',
--    @enabled = 1,
--    @description = 'Technischer User für SQL Management DWH',
--    @credential_name = 'SV_SQLMDWPROXY' ;
--GO

--/* Zugriffsrechte für SQL-Agent-User erteilen */
----EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'PROXXY_SV_SQLMDWPROXY', @login_name=N'SV\TECHNI'
----GO

--/* Zugriff für den Proxy auf das gewünschte Subsystem festelegen */
--EXEC msdb.dbo.sp_grant_proxy_to_subsystem 
--@proxy_name=N'PROXXY_SV_SQLMDWPROXY', 
--@subsystem_id = 3 /* CMDEXEC */
----@subsystem_id = 11 /* SSIS */
----@subsystem_id = 12 /* Powershell */
--GO 
