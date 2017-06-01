declare @name as nvarchar(max)
declare @cmd as nvarchar(max)
 
if OBJECT_ID('tempdb..#temp') IS NOT NULL
	DROP TABLE #temp 

create table #temp
(
server_name nvarchar(max),
level nvarchar(max),
login_name sysname,
dbname nvarchar(max),
db_role sysname,
issysadmin bit,
issecurityadmin bit,
isserveradmin bit,
issetupadmin bit,
isprocessadmin bit,
isdiskadmin bit,
isdbcreator bit,
isbulkadmin bit
)
 
set @name = (select top 1 name from sys.databases where state_desc = 'ONLINE'order by name)
 
while @name IS NOT NULL
begin
	 
	set @cmd = 'select @@servername as server_name,
	case when (l.sysadmin = 1) then ''server'' else ''database'' end as level,
	u1.name as login_name, '''+@name+''', u2.name as role_db,
	l.sysadmin as issysadmin, l.securityadmin as issecurityadmin, l.serveradmin as isserveradmin,
	l.setupadmin as issetupadmin, l.processadmin as isprocessadmin, l.diskadmin as isdiskadmin,
	l.dbcreator as isdbcreator, l.bulkadmin as isbulkadmin
	from 
	['+@name+'].sys.sysusers u1,
	['+@name+'].sys.sysusers u2,
	['+@name+'].sys.database_role_members p,
	['+@name+'].sys.syslogins l
	where u1.uid = p.member_principal_id and u2.uid = p.role_principal_id
	and l.sid = u1.sid'
	 
	insert into #temp
	exec sp_executesql @cmd
	 
	set @name = (
					select top 1 name 
					from sys.databases 
					where  
						name > @name 
					AND state_desc = 'ONLINE'
					order by name
				)
end
 
select 
* 
from #temp 
where issysadmin <> 0
order by login_name
;
 
drop table #temp;


--select * from sys.sql_logins