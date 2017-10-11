SELECT  
  SERVERPROPERTY('MachineName') AS ComputerName,
  SERVERPROPERTY('ServerName') AS InstanceName,  
  SERVERPROPERTY('Edition') AS Edition,
  SERVERPROPERTY('ProductVersion') AS ProductVersion,  
  SERVERPROPERTY('ProductLevel') AS ProductLevel,
  SERVERPROPERTY('ProductUpdateLevel') AS ProductUpdateLevel,
  SERVERPROPERTY('ProductUpdateReference') AS ProductUpdateReference,
  SERVERPROPERTY('ProductMajorVersion') AS ProductMajorVersion,
  SERVERPROPERTY('ProductMinorVersion') AS ProductMinorVersion,
  SERVERPROPERTY('ProductBuild') AS ProductBuild,
  SERVERPROPERTY('IsClustered') AS IsClustered,
  SERVERPROPERTY('BuildClrVersion') AS BuildClrVersion,
  SERVERPROPERTY('InstanceDefaultDataPath') InstanceDefaultDataPath,
  SERVERPROPERTY('InstanceDefaultLogPath') InstanceDefaultLogPath
;
GO  