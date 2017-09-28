use dba;
go

exec sp_Blitz

exec sp_BlitzFirst @SinceStartup = 1

exec sp_BlitzIndex @GetAllDatabases = 1

exec sp_BlitzCache @SortOrder = 'cpu'
