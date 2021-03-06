-- Enable Database Mail for this instance
EXECUTE sp_configure 'show advanced', 1;
RECONFIGURE WITH OVERRIDE;
EXECUTE sp_configure 'Database Mail XPs',1;
RECONFIGURE WITH OVERRIDE;

GO

-- Create a Database Mail account
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'MAIL-ACCOUNT',
    @description = 'Account f�r gesamten Mailverkehr.',
    @email_address = 'l-bicc@123.com',
    @replyto_address = 'l-bicc@123.com',
    @display_name = 'L-BICC',
    @mailserver_name = 'dummy.sv.db.de';
 
-- Create a Database Mail profile
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'Standard Profil',
    @description = 'Standard Profil f�r alle Benutzer';

-- Create a Database Mail profile
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'EMAIL_VERSAND_UEBER_dummy',
    @description = 'Standard Profil f�r alle Benutzer';


	

-- Add the mail account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'Standard Profil',
    @account_name = 'MAIL-ACCOUNT',
    @sequence_number = 1;

-- Add the mail account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'EMAIL_VERSAND_UEBER_dummy',
    @account_name = 'MAIL-ACCOUNT',
    @sequence_number = 1;

-- Grant access to the profile to all msdb database users
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'Standard Profil',
    @principal_name = 'public',
    @is_default = 1;

-- Grant access to the profile to all msdb database users
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'EMAIL_VERSAND_UEBER_dummy',
    @principal_name = 'public',
    @is_default = 0;


GO


USE [master]
GO
CREATE LOGIN [AD\SQLSERVER_MAIL_USER] FROM WINDOWS WITH DEFAULT_DATABASE=[msdb], DEFAULT_LANGUAGE=[Deutsch]
GO
USE [msdb]
GO
CREATE USER [AD\SQLSERVER_MAIL_USER] FOR LOGIN [AD\SQLSERVER_MAIL_USER]
GO
USE [msdb]
GO
EXEC sp_addrolemember N'DatabaseMailUserRole', N'AD\SQLSERVER_MAIL_USER'
GO


ALTER DATABASE msdb SET ENABLE_BROKER /* SQL_Agent vorher stoppen, sonst wird kein exklusiver Zugang erreicht	*/


--send a test email
EXECUTE msdb.dbo.sp_send_dbmail
	@profile_name = 'EMAIL_VERSAND_UEBER_dummy',
    @subject = 'Test Database Mail Message',
    @recipients = 'noname@123.com',
    @body = 'SELECT 1; ';

GO

--send a test email
EXECUTE msdb.dbo.sp_send_dbmail
	@profile_name = 'Standard Profil',
    @subject = 'Test Database Mail Message',
    @recipients = 'noname@123.com',
    @body = 'SELECT 1; ';

GO