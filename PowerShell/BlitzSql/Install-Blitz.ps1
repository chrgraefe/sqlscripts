param (
    [Parameter(Mandatory=$false)]
    [String[]] $Instances = "localhost\SQL2017"
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

$jobCmdCleanup = "CommandLog Cleanup"
$jobSystemDbFull = "DatabaseBackup - SYSTEM_DATABASES - FULL"
$jobUserDbDiff = "DatabaseBackup - USER_DATABASES - DIFF"
$jobUserDbFull = "DatabaseBackup - USER_DATABASES - FULL"
$jobUserDbLog = "DatabaseBackup - USER_DATABASES - LOG"
$jobSystemDbIntegrity = "DatabaseIntegrityCheck - SYSTEM_DATABASES"
$jobUserDbIntegrity = "DatabaseIntegrityCheck - USER_DATABASES"
$jobUserDbFullIndexOptimize = "IndexOptimize - USER_DATABASES"
$jobOutFileCleanup = "Output File Cleanup"
$jobDeleteBackupHistory = "sp_delete_backuphistory"
$jobPurgeJobHistory = "sp_purge_jobhistory"

#Get-ChildItem ".\" -Filter *.sql | 
#Foreach-Object {
 #   $_.FullName
    Foreach ($instance in $instances) 
    {
        #Set-DatabaseIfNotExists -SqlServer $instance -DatabaseName "DBA";        
        #Install-DbaFirstResponderKit -SqlInstance $instance -Database "DBA"
        #Install-DbaWhoIsActive -SqlInstance $instance -Database "DBA"
        Install-DbaMaintenanceSolution -SqlInstance $instance -Database "DBA" -BackupLocation "C:\TEMP\" -CleanupTime 2400 -InstallJobs -ReplaceExisting


        # DatabaseBackup - USER_DATABASES - FULL
        Remove-DbaAgentSchedule -SqlInstance $instance -Schedule "schedule_$jobUserDbFull" -Force
        New-DbaAgentSchedule -SqlInstance $instance -Job $jobUserDbFull -Schedule "schedule_$jobUserDbFull" -FrequencyType Weekly -FrequencyInterval Sunday -FrequencyRecurrenceFactor 1 -StartDate "20170101" -StartTime "000000" -EndDate "20991231" -EndTime "235959"

        # DatabaseBackup - USER_DATABASES - FULL
        Remove-DbaAgentSchedule -SqlInstance $instance -Schedule "schedule_$jobUserDbDiff" -Force
        New-DbaAgentSchedule -SqlInstance $instance -Job $jobUserDbDiff -Schedule "schedule_$jobUserDbDiff" -FrequencyType Weekly -FrequencyInterval Monday,Tuesday,Wednesday,Thursday,Friday,Saturday -FrequencyRecurrenceFactor 1 -StartDate "20170101" -StartTime "000000" -EndDate "20991231" -EndTime "235959"
        
        # DatabaseBackup - USER_DATABASES - LOG
        Remove-DbaAgentSchedule -SqlInstance $instance -Schedule "schedule_$jobUserDbLog" -Force
        New-DbaAgentSchedule -SqlInstance $instance -Job $jobUserDbLog -Schedule "schedule_$jobUserDbLog" -FrequencyType Daily -FrequencyInterval EveryDay -FrequencySubdayType Minutes -FrequencySubdayInterval 15 -StartDate "20170101" -StartTime "000000" -EndDate "20991231" -EndTime "235959"
        
        #Invoke-Sqlcmd -ServerInstance $instance -Database "DBA" -InputFile $_.FullName;
        #Install-SqlWhoIsActive -SqlServer $instance;
    }
#}






