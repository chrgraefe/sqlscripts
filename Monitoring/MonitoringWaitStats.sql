USE DBA;
GO

INSERT INTO DBA.dbo.WaitStats
SELECT  wait_type as WaitType,
        waiting_tasks_count AS NumberOfWaits,
        signal_wait_time_ms AS SignalWaitTime,
        wait_time_ms - signal_wait_time_ms AS ResourceWaitTime,
        GETDATE() AS SampleTime
FROM    sys.dm_os_wait_stats
WHERE   wait_time_ms > 0
    AND wait_type NOT IN 
	(
N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE', N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',
N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE', N'EXECSYNC', N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT', N'ONDEMAND_TASK_QUEUE',
N'PREEMPTIVE_OS_LIBRARYOPS', N'PREEMPTIVE_OS_COMOPS', N'PREEMPTIVE_OS_CRYPTOPS', N'PREEMPTIVE_OS_PIPEOPS', N'PREEMPTIVE_OS_AUTHENTICATIONOPS',
N'PREEMPTIVE_OS_GENERICOPS', N'PREEMPTIVE_OS_VERIFYTRUST', N'PREEMPTIVE_OS_FILEOPS', N'PREEMPTIVE_OS_DEVICEOPS',
N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE', N'XE_DISPATCHER_WAIT', N'XE_LIVE_TARGET_TVF', N'XE_TIMER_EVENT',
N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',
N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY', N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES',
N'WAIT_FOR_RESULTS', N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN'
);



SELECT  WaitType,
        NumberOfWaits,
        SignalWaitTime,
        ResourceWaitTime,
        SampleTime,
        ROW_NUMBER() OVER (PARTITION BY WaitType ORDER BY SampleTime) AS Interval
FROM    dbo.WaitStats
WHERE   WaitType IN ('LCK_M_IX', 'PAGELATCH_EX', 'LATCH_EX', 'IO_COMPLETION');


WITH    RawWaits
          AS (SELECT    WaitType,
                        NumberOfWaits,
                        SignalWaitTime,
                        ResourceWaitTime,
                        SampleTime,
                        ROW_NUMBER() OVER (PARTITION BY WaitType ORDER BY SampleTime) AS Interval
              FROM      dbo.WaitStats
              WHERE     WaitType IN ('LCK_M_IX', 'PAGELATCH_EX', 'LATCH_EX', 'IO_COMPLETION')
             )
    SELECT  w1.SampleTime,
            w1.WaitType AS WaitType,
            w2.NumberOfWaits - w1.NumberOfWaits AS NumerOfWaitsInInterval,
            w2.ResourceWaitTime - w1.ResourceWaitTime AS WaitTimeInInterval,
            w2.SignalWaitTime - w1.SignalWaitTime AS SignalWaitTimeInInterval
    FROM    RawWaits w1
            LEFT OUTER JOIN RawWaits w2 ON w2.WaitType = w1.WaitType
                                           AND w2.Interval= w1.Interval + 1;



WITH    RawWaits
          AS (SELECT    WaitType,
                        NumberOfWaits,
                        SignalWaitTime,
                        ResourceWaitTime,
                        SampleTime,
                        ROW_NUMBER() OVER (PARTITION BY WaitType ORDER BY SampleTime) AS Interval
              FROM      dbo.WaitStats
              WHERE     WaitType IN ('LCK_M_IX', 'PAGELATCH_EX', 'LATCH_EX', 'IO_COMPLETION')
             ),
        WaitIntervals
          AS (SELECT    w1.SampleTime,
                        w1.WaitType AS WaitType,
                        w2.NumberOfWaits - w1.NumberOfWaits AS NumerOfWaitsInInterval,
                        w2.ResourceWaitTime - w1.ResourceWaitTime AS WaitTimeInInterval,
                        w2.SignalWaitTime - w1.SignalWaitTime AS SignalWaitTimeInInterval
              FROM      RawWaits w1
                        LEFT OUTER JOIN RawWaits w2 ON w2.WaitType = w1.WaitType
                                                       AND w2.Interval = w1.Interval + 1
             )
    SELECT  *
    FROM    (SELECT SampleTime, WaitType, WaitTimeInInterval FROM WaitIntervals
            ) p PIVOT ( AVG(WaitTimeInInterval) FOR WaitType IN ([LCK_M_IX], [PAGELATCH_EX], [LATCH_EX], [IO_COMPLETION]) ) AS pvt
    ORDER BY SampleTime;
										   