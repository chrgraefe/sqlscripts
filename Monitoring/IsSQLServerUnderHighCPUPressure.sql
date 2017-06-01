-- Is SQL Server under CPU Pressure right now?
 
IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
WHERE [name] = N'##CMSWaitStatsCPU1')
DROP TABLE [##CMSWaitStatsCPU1];
 
IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
WHERE [name] = N'##CMSWaitStatsCPU2')
DROP TABLE [##CMSWaitStatsCPU2];
GO
 
;WITH [Waits] AS
(SELECT
[wait_type],
[wait_time_ms] / 1000.0 AS [WaitS],
([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
[signal_wait_time_ms] / 1000.0 AS [SignalS],
[waiting_tasks_count] AS [WaitCount],
100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage]
FROM sys.dm_os_wait_stats
WHERE [wait_type] NOT IN (
N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
N'CHKPT', N'CLR_AUTO_EVENT',
N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
N'EXECSYNC', N'FSAGENT',
N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',
N'PWAIT_ALL_COMPONENTS_INITIALIZED',
N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
AND [waiting_tasks_count] > 0
)
 
SELECT [wait_type], [WaitS], [ResourceS], [SignalS], [WaitCount], [Percentage]
INTO [##CMSWaitStatsCPU1]
FROM [Waits]
 
WAITFOR DELAY '00:00:30'
GO
;WITH [Waits] AS
(SELECT
[wait_type],
[wait_time_ms] / 1000.0 AS [WaitS],
([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
[signal_wait_time_ms] / 1000.0 AS [SignalS],
[waiting_tasks_count] AS [WaitCount],
100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage]
FROM sys.dm_os_wait_stats
WHERE [wait_type] NOT IN (
N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
N'CHKPT', N'CLR_AUTO_EVENT',
N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
N'EXECSYNC', N'FSAGENT',
N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',
N'PWAIT_ALL_COMPONENTS_INITIALIZED',
N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
AND [waiting_tasks_count] > 0
)
SELECT [wait_type], [WaitS], [ResourceS], [SignalS], [WaitCount], [Percentage]
INTO [##CMSWaitStatsCPU2]
FROM [Waits]
 
DECLARE @SignalWait_2_TotalWait_Ratio DECIMAL (16,2)
DECLARE @TotalPercentageOfSOS_SCHEDULER_YIELD DECIMAL (16,2)
DECLARE @TotalWaits DECIMAL (16,2)
DECLARE @ResourceWait DECIMAL (16,2)
DECLARE @SignalWaits DECIMAL (16,2)
DECLARE @WaitCount INT
DECLARE @TopWaitType sysname
;WITH [DiffCPUWaits] AS
(
-- Waits that weren't in the first snapshot
SELECT [CPU2].[wait_type] ,
[CPU2].[WaitS] ,
[CPU2].[ResourceS] ,
[CPU2].[SignalS] ,
[CPU2].[WaitCount],
[CPU2].[Percentage]
FROM [##CMSWaitStatsCPU2] AS [CPU2]
LEFT OUTER JOIN [##CMSWaitStatsCPU1] AS [CPU1] ON [CPU1].[wait_type] = [CPU2].[wait_type]
WHERE [CPU1].[wait_type] IS NULL
 
UNION
-- Diff of Waits in both snapshots
SELECT [CPU2].[wait_type] ,
[CPU2].[WaitS] - [CPU1].[WaitS],
[CPU2].[ResourceS] - [CPU1].[ResourceS],
[CPU2].[SignalS] - [CPU1].[SignalS],
[CPU2].[WaitCount] - [CPU1].[WaitCount],
[CPU2].[Percentage]
FROM [##CMSWaitStatsCPU2] AS [CPU2]
LEFT OUTER JOIN [##CMSWaitStatsCPU1] AS [CPU1] ON [CPU1].[wait_type] = [CPU2].[wait_type]
WHERE [CPU1].[wait_type] IS NOT NULL
)
 
-- as we run snapshots with a time difference of 30 seconds,
-- the Signal Wait Time has to be at least 15% of that --> 4.5 seconds.
 
-- COLLECT the results
SELECT
@SignalWait_2_TotalWait_Ratio = (CAST ( (SUM([DiffCPUWaits].[SignalS]) / SUM([DiffCPUWaits].[WaitS])) * 100.0 AS DECIMAL(16,2)))
, @TotalWaits = (CAST (SUM([DiffCPUWaits].[WaitS]) AS DECIMAL(16,2)))
, @ResourceWait = (CAST (SUM([DiffCPUWaits].[ResourceS]) AS DECIMAL(16,2)))
, @SignalWaits = (CAST (SUM([DiffCPUWaits].[SignalS]) AS DECIMAL(16,2)))
, @WaitCount = (CAST (SUM([DiffCPUWaits].[WaitCount]) AS INTEGER))
, @TopWaitType = (SELECT TOP 1 wait_type FROM [DiffCPUWaits] ORDER BY [WaitS])
, @TotalPercentageOfSOS_SCHEDULER_YIELD = (SELECT [Percentage] FROM [DiffCPUWaits] WHERE [DiffCPUWaits].[wait_type] = 'SOS_SCHEDULER_YIELD')
FROM [DiffCPUWaits]
-- INTERPRET the results
SELECT CASE
 
WHEN @SignalWait_2_TotalWait_Ratio < 15.0
AND @SignalWaits < 4.5 THEN 'no' WHEN @SignalWait_2_TotalWait_Ratio > 15.0
AND @SignalWaits < 4.5
THEN '1 x YES'
 
WHEN @SignalWait_2_TotalWait_Ratio < 15.0 AND @SignalWaits > 4.5
THEN '1 x YES'
 
WHEN @SignalWait_2_TotalWait_Ratio > 15.0
AND @SignalWaits > 4.5
AND @TotalPercentageOfSOS_SCHEDULER_YIELD < 10.0 THEN '2 x YES' WHEN @SignalWait_2_TotalWait_Ratio > 15.0
AND @SignalWaits > 4.5
AND @TotalPercentageOfSOS_SCHEDULER_YIELD > 10.0
THEN '3 x YES - INTERNAL CPU PRESSURE'
WHEN @SignalWait_2_TotalWait_Ratio > 15.0
AND @SignalWaits > 4.5
AND @TotalPercentageOfSOS_SCHEDULER_YIELD > 10.0
AND @TopWaitType = 'SOS_SCHEDULER_YIELD'
THEN '4 x YES - HIGH INTERNAL CPU PRESSURE'
 
END AS [Is SQL Server under CPU Pressure?]
, @SignalWait_2_TotalWait_Ratio AS [Signal Waits / Total Waits (%) < 15]
, @TotalWaits AS [Waits - from R.ing to R.ing (sec)]
, @ResourceWait AS [Ressource Waits - for Rescources (sec)]
, @SignalWaits AS [Signal Waits - from R.able to R.ing (sec) < 4.5]
, @TotalPercentageOfSOS_SCHEDULER_YIELD AS [SOS_SCHEDULER_YIELDS Waits Of Total (%) < 10]
 
-- Cleanup
IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
WHERE [name] = N'##CMSWaitStatsCPU1')
DROP TABLE [##CMSWaitStatsCPU1];
 
IF EXISTS (SELECT * FROM [tempdb].[sys].[objects]
WHERE [name] = N'##CMSWaitStatsCPU2')
DROP TABLE [##CMSWaitStatsCPU2];
 
GO