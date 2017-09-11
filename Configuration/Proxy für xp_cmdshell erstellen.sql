USE MASTER;
GO

/*
Muss als lokaler Administrator auf dem jeweiligen Server ausgef�hrt werden
*/

/* Erstelle den LOGIN f�r das Proxy-Konto falls dieses noch nicht existiert */
IF NOT EXISTS 
    (SELECT name  
     FROM master.sys.server_principals
     WHERE name = 'AD\TECHNI')
BEGIN
	CREATE LOGIN [AD\TECHNI] FROM WINDOWS;
END

/* Hinterlegung von Konto und Passwort */
EXEC sp_xp_cmdshell_proxy_account 'AD\123', '1234' ;

--Create the database role and assign rights to the role
IF DATABASE_PRINCIPAL_ID('role_CmdShell_Executor') IS NULL 
BEGIN
	CREATE ROLE [role_CmdShell_Executor] AUTHORIZATION [dbo]
END


GRANT EXEC ON xp_cmdshell TO [role_CmdShell_Executor]


EXEC sp_addrolemember [role_CmdShell_Executor], [AD\dummy];