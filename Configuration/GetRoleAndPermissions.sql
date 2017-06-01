declare @RoleName varchar(50) = 'ROL_FACHBEREICH_DPS'





declare @Script varchar(max) = 
'' + char(13) + 
'IF NOT EXISTS(SELECT * FROM sys.database_principals rol WHERE type = ''R'' AND name = ''' + @RoleName + ''')' + char(13) + 
'	CREATE ROLE ' + @RoleName + ';' + char(13) + char(13)


select @script = @script + 'GRANT ' + prm.permission_name + ' ON ' + SCHEMA_NAME(so.schema_id) + '.' + OBJECT_NAME(prm.major_id) + ' TO ' + rol.name + ';' + char(13) COLLATE Latin1_General_CI_AS
from sys.database_permissions prm
inner join sys.database_principals rol on
	prm.grantee_principal_id = rol.principal_id
inner join sys.objects so ON
	so.object_id = prm.major_id

where rol.name = @RoleName
order by rol.name, OBJECT_NAME(prm.major_id)

print @script