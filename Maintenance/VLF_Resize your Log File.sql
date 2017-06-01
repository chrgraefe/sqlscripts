/* USE ALF */ --Set db name before running using drop-down above or this USE statement

DECLARE @file_name sysname,
@file_size int,
@file_growth int,
@shrink_command nvarchar(max),
@alter_command nvarchar(max)

SELECT @file_name = name,
@file_size = (size / 128)
FROM sys.database_files
WHERE type_desc = 'log'

PRINT 'USE [' + db_name() + ']
GO';


SELECT @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name + ''' , 0, TRUNCATEONLY);'
PRINT @shrink_command
--EXEC sp_executesql @shrink_command

SELECT @shrink_command = 'DBCC SHRINKFILE (N''' + @file_name + ''' , 0);'
PRINT @shrink_command
--EXEC sp_executesql @shrink_command

PRINT '--Huge Databases';
SELECT @alter_command = 
'ALTER DATABASE [' + db_name() + '] 
	MODIFY FILE (
		  NAME = N''' + @file_name + '''
		, SIZE = 10GB
		, MAXSIZE = UNLIMITED
		, FILEGROWTH = 10GB
		);
'
PRINT @alter_command

PRINT '--Medium Databases';
SELECT @alter_command = 
'ALTER DATABASE [' + db_name() + '] 
	MODIFY FILE (
		  NAME = N''' + @file_name + '''
		, SIZE = 5GB
		, MAXSIZE = UNLIMITED
		, FILEGROWTH = 5GB
		);
'
PRINT @alter_command

PRINT '--Tiny Databases';
SELECT @alter_command = 
'ALTER DATABASE [' + db_name() + '] 
	MODIFY FILE (
		  NAME = N''' + @file_name + '''
		, SIZE = 1GB
		, MAXSIZE = UNLIMITED
		, FILEGROWTH = 1GB
		);
'
PRINT @alter_command
