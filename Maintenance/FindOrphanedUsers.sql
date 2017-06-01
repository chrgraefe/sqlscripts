/*************************************************
** Purpose: To return database users (for each db) orphaned from any login.
** Created By: James Howard
** Created On: 03 DEC 09
*************************************************/

--create a temp table to store the results
CREATE TABLE #temp (
DatabaseName NVARCHAR(50),
UserName NVARCHAR(50)
)


--create statement to run on each database
declare @sql nvarchar(500)
SET @sql='
	select 
	  ''?'' as DBName
	, name AS UserName
	from [?]..sysusers
	where 
		(sid is not null and sid <> 0x0)
	and suser_sname(sid) is null 
	and (issqlrole <> 1) 
	AND (isapprole <> 1) 
	AND (name <> ''INFORMATION_SCHEMA'') 
	AND (name <> ''guest'') 
	AND (name <> ''sys'') 
	AND (name <> ''dbo'') 
	AND (name <> ''system_function_schema'')
	order by name;
'
--insert the results from each database to temp table
INSERT INTO #temp
exec SP_MSforeachDB @sql
--return results


--SELECT * FROM #temp


SELECT 
'
USE '+ DatabaseName + ';
      
DECLARE @USer SYSNAME;

SET @USer = ''' + UserName + ''';

EXECUTE sp_change_users_login @Action=''update_one'', @UserNamePattern=@USer, @LoginName=@USer;
'
FROM #temp

DROP TABLE #temp

/*



USE KVPLUS_ARCHIV
GO
      
DECLARE @USer SYSNAME 

SET @USer = 'KV_Admin';

EXECUTE sp_change_users_login @Action='update_one', @UserNamePattern=@USer, @LoginName=@USer;


*/