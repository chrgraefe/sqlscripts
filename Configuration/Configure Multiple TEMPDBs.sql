USE [master]; 
GO 
alter database tempdb modify file (NAME = 'tempdev', SIZE = 10GB, FILEGROWTH = 5GB, MAXSIZE = UNLIMITED);
GO
/* Adding three additional files */
USE [master];
GO
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME = N'E:\MSSQL10.MSSQLSERVER\MSSQL\DATA\tempdev2.ndf', SIZE = 10GB, FILEGROWTH = 5GB, MAXSIZE = UNLIMITED);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME = N'E:\MSSQL10.MSSQLSERVER\MSSQL\DATA\tempdev3.ndf', SIZE = 10GB, FILEGROWTH = 5GB, MAXSIZE = UNLIMITED);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME = N'E:\MSSQL10.MSSQLSERVER\MSSQL\DATA\tempdev4.ndf', SIZE = 10GB, FILEGROWTH = 5GB, MAXSIZE = UNLIMITED);
GO

/* resize tempdb Log-file to a reasonable size */
USE [master]
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'templog', SIZE = 40GB , FILEGROWTH = 1GB, MAXSIZE = UNLIMITED )
GO



/* modify 4 files */
USE [master];
GO
ALTER DATABASE [tempdb] MODIFY FILE (NAME = N'tempdev' , SIZE = 10GB, FILEGROWTH = 5GB, MAXSIZE = UNLIMITED);
ALTER DATABASE [tempdb] MODIFY FILE (NAME = N'tempdev2', SIZE = 10GB, FILEGROWTH = 5GB, MAXSIZE = UNLIMITED);
ALTER DATABASE [tempdb] MODIFY FILE (NAME = N'tempdev3', SIZE = 10GB, FILEGROWTH = 5GB, MAXSIZE = UNLIMITED);
ALTER DATABASE [tempdb] MODIFY FILE (NAME = N'tempdev4', SIZE = 10GB, FILEGROWTH = 5GB, MAXSIZE = UNLIMITED);
GO