param (
    [Parameter(Mandatory=$true)]
    [String[]] $Instances
)

Import-Module dbatools;

function Set-DatabaseIfNotExists
{
 param( 
        [parameter(Mandatory=$true)]
        [string] $SqlServer, 
        [parameter(Mandatory=$true)]
        [string] $DatabaseName 
        )

    $query=
    "
    IF NOT EXISTS(SELECT 1 FROM sys.sysdatabases WHERE name = '$DatabaseName')
    BEGIN
	    CREATE DATABASE $DatabaseName;
    END";
    
    Invoke-Sqlcmd -ServerInstance $SqlServer -Database "master" -Query $query;
}

#use dba;
#go
#
#exec sp_Blitz
#
#exec sp_BlitzFirst @SinceStartup = 1#
#
#exec sp_BlitzIndex @GetAllDatabases = 1
#
#exec sp_BlitzCache @SortOrder = 'cpu'
#

Get-ChildItem ".\" -Filter *.sql | 
Foreach-Object {
    $_.FullName
    Foreach ($instance in $instances) 
    {
        Set-DatabaseIfNotExists -SqlServer $instance -DatabaseName "DBA";

        Invoke-Sqlcmd -ServerInstance $instance -Database "DBA" -InputFile $_.FullName;
        #Install-SqlWhoIsActive -SqlServer $instance;
    }
}

