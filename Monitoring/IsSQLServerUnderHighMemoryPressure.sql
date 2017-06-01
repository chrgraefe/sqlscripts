
/*
    CMS, 05.12.2014:
    Is SQL Server under Memory Pressure?
     
    This check consists of 3 Steps:
    1) Check Actual Page Life Expectancy
    2) Check Top Wait Stat                  - with the help of Paul Randal's Wait Stats CHECK
                                              http://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/
    3) Check Buffer Pool Rate               - With the help of SQL Rockstars Buffer Pool Rate Calculation
                                              http://thomaslarock.com/2012/05/are-you-using-the-right-sql-server-performance-metrics/ -> Buffer Pool I/O Rate


	So if all of the three criteria equal to “true” the script will show ‘3 x YES’.
	If it’s Page Life Expectancy and PAGEIOLATCH_XX or Page Life Expectancy and Buffer Pool Rate, you will get ‘2 x YES’.
     
*/
 
SET NOCOUNT ON
 
DECLARE @MaxServerMemory FLOAT
DECLARE @ActualPageLifeExpectancy FLOAT
DECLARE @RecommendedPageLifeExpectancy FLOAT
DECLARE @RecommendedMemory FLOAT
DECLARE @TopWaitType sysname
DECLARE @BufferPoolRate FLOAT
 
-- ####################################################################################################
SELECT  @MaxServerMemory = (1.0 * cntr_value / 1024 / 1024)
        , @RecommendedPageLifeExpectancy = Convert(INT ,(1.0 * cntr_value) / 1024 / 1024 / 4.0 * 300)
FROM    sys.dm_os_performance_counters
WHERE   counter_name = 'Target Server Memory (KB)'
 
SELECT  @ActualPageLifeExpectancy = 1.0 * cntr_value
FROM    sys.dm_os_performance_counters
WHERE   object_name LIKE '%Buffer Manager%'
AND     LOWER(counter_name) = 'page life expectancy'
 
-- ####################################################################################################
/*
Check TOP Wait Type.
If the TOP 1 Wait Type is PAGEIOLATCH_SH it indicates that SQL Server is waiting on datapages to be read 
into the Buffer Pool.
Memory Pressure might not be the root cause, it can be a poor indexing strategy
because way too many pages have to be read into the buffer pool and they are deleted from the buffer pool too early.
*/
;WITH [Waits] AS
    (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
        100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER',             N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP',                N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER',              N'CHECKPOINT_QUEUE',
        N'CHKPT',                           N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT',                N'CLR_SEMAPHORE',
        N'DBMIRROR_DBM_EVENT',              N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE',           N'DBMIRRORING_CMD',
        N'DIRTY_PAGE_POLL',                 N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC',                        N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT',     N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL',               N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT',            N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK',                 N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP',                  N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE',                    N'ONDEMAND_TASK_QUEUE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'REQUEST_FOR_DEADLOCK_SEARCH',     N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK',               N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP',                 N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY',             N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED',            N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK',                N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP',             N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP',     N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES',           N'WAIT_FOR_RESULTS',
        N'WAITFOR',                         N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_HOST_WAIT',              N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE',             N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT',              N'XE_TIMER_EVENT')
    -- @cms4j: do not take BACKUP into Account, as it does not use the Buffer Cache
    AND  [wait_type] NOT IN (
        N'BACKUPBUFFER', N'BACKUPIO')
    AND [waiting_tasks_count] > 0
 )
SELECT @TopWaitType = (SELECT top 1
    MAX ([W1].[wait_type])
    FROM [Waits] AS [W1]
INNER JOIN [Waits] AS [W2]
    ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum]
HAVING SUM ([W2].[Percentage]) - MAX ([W1].[Percentage]) < 95); -- percentage threshold
 
 
-- ####################################################################################################
-- SQL Rockstar comes up with BUFFER POOL RATE. But that depends on SUPER DUPER STORAGE. If that is low, the BufferPoolRate will also be slow.
SELECT  @BufferPoolRate = ( 1.0 * cntr_value / 128.0 )
        / ( SELECT  1.0 * cntr_value
            FROM    sys.dm_os_performance_counters
            WHERE   object_name LIKE '%Buffer Manager%'
                    AND LOWER(counter_name) = 'page life expectancy' )
        FROM    sys.dm_os_performance_counters
WHERE   object_name LIKE '%Buffer Manager%'
        AND counter_name = 'Database pages'
 
-- ####################################################################################################
-- Calculate Recommended Max Memory
SELECT @RecommendedMemory = Convert(INT, @RecommendedPageLifeExpectancy / @ActualPageLifeExpectancy * @MaxServerMemory)
 
-- ####################################################################################################
-- Put all the things together...
SELECT  CASE
            WHEN @RecommendedMemory > @MaxServerMemory AND @TopWaitType LIKE 'PAGEIOLATCH_%' AND @BufferPoolRate > 20.0 THEN '3 x YES'
            WHEN
                (@RecommendedMemory > @MaxServerMemory AND @TopWaitType LIKE 'PAGEIOLATCH_%')
                OR
                (@RecommendedMemory > @MaxServerMemory AND @BufferPoolRate > 20.0) THEN '2 x YES'
            WHEN @RecommendedMemory > @MaxServerMemory AND @TopWaitType NOT LIKE 'PAGEIOLATCH_%' THEN '1 x YES, TOP Wait: ' + @TopWaitType
            WHEN @RecommendedMemory < @MaxServerMemory  THEN 'no'
        END AS [Is SQL Server under Memory Pressure?]
        , @MaxServerMemory AS [Max Server Memory (GB)]
        , @ActualPageLifeExpectancy AS [Actual PLE]
        , @RecommendedPageLifeExpectancy AS [Recommended PLE]
        , @RecommendedMemory AS [Recommended Memory (GB)]
        , @TopWaitType AS [Top Wait Type]
        , @BufferPoolRate AS [BufferPool Rate, you want < 20]