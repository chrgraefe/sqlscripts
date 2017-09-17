#Create a new trigger that is configured to trigger at startup
$Triggers = @()
$Triggers += New-ScheduledTaskTrigger -Daily -At 06:00
$Triggers += New-ScheduledTaskTrigger -Daily -At 12:00
$Triggers += New-ScheduledTaskTrigger -Daily -At 18:00
#Name for the scheduled task
$Name = "Backup Working Directory"
#Action to run as
$Action = New-ScheduledTaskAction -Execute D:\BATCHES\WORKDIR_to_Synology.bat
#Configure when to stop the task and how long it can run for. In this example it does not stop on idle and uses the maximum possible duration by setting a timelimit of 0
$Settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -DontStopOnIdleEnd -ExecutionTimeLimit ([TimeSpan]::Zero)
#Configure the principal to use for the scheduled task and the level to run as
$Principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel "Highest"
#Create new scheduled task
$Task = New-ScheduledTask -Settings $Settings -Principal $Principal -Action $Action -Trigger $Triggers
#Register the new scheduled task
Register-ScheduledTask -InputObject $Task -TaskName $Name