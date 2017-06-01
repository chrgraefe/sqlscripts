use master
GO

CREATE TABLE [dbo].[ServerLogonHistory](
 [ID] bigint NOT NULL IDENTITY(1, 1) PRIMARY KEY,
 [SystemUser] [varchar](512) NULL,
 [HostName] [varchar](512) NULL,
 [DBUser] [varchar](512) NULL,
 [SPID] [int] NULL,
 [LogonTime] [datetime] NULL,
 [AppName] [varchar](512) NULL,
 [DatabaseName] [varchar](512) NULL
) ON [PRIMARY];
GO


USE [master]
GO

CREATE TRIGGER [TRG_SERVERLOGON]
ON ALL SERVER WITH EXECUTE AS 'sa'
FOR LOGON 
AS
BEGIN
	INSERT INTO dbo.ServerLogonHistory
	SELECT ORIGINAL_LOGIN(), HOST_NAME(),USER, @@SPID, GETDATE(), APP_NAME(), DB_NAME();
END;

GO

ENABLE TRIGGER [TRG_SERVERLOGON] ON ALL SERVER;
GO

