/*
SQL Server Stabndardsetting!
 */



sp_configure 'show advanced options', 1;
GO
RECONFIGURE WITH OVERRIDE;
GO

sp_configure
GO

sp_configure 'max degree of parallelism', 4; /* Option gewählt da 4 Cores je Prozessorsockel (NUMA-Node) enthalten sind */
GO
RECONFIGURE WITH OVERRIDE;
GO

sp_configure 'cost threshold for parallelism', 25;  /* ab Kosten von 25 wird versucht einen "günstigeren" parallelen Plan zu finden */
GO
RECONFIGURE WITH OVERRIDE;
GO