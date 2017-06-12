USE master;
GO
-- Create the Event Session
IF EXISTS ( SELECT *
				FROM sys.server_event_sessions
				WHERE name = 'Recompile_Histogram' )
	DROP EVENT SESSION Recompile_Histogram
    ON SERVER;
GO

CREATE EVENT SESSION Recompile_Histogram ON SERVER 
  ADD EVENT sqlserver.sql_statement_recompile
  ADD TARGET 
    package0.asynchronous_file_target (
        SET filename = N'D:\LOG\XEvents\Recompile_Histogram.xel'
          , max_rollover_files = ( 25 ) )
;
 
ALTER EVENT SESSION Recompile_Histogram ON SERVER STATE = START;


 /* ====================================================================================*/
 /* ====================================================================================*/
 /* ====================================================================================*/
IF EXISTS (SELECT OBJECT_ID('tempdb..#xmlprocess'))
BEGIN
	DROP TABLE #xmlprocess;
END

SELECT 
  CAST ([t2].[event_data] AS XML) AS event_data
, t2.file_offset
, t2.file_name
, cte1.event_session_id
--, ' AS event_predicate
INTO #xmlprocess
FROM ( 
	SELECT 
	  REPLACE(CONVERT(NVARCHAR(128),sesf.value),'.xel','*.xel') AS targetvalue
	, ses.event_session_id
	FROM sys.server_event_sessions ses
	INNER JOIN sys.server_event_session_fields sesf ON ses.event_session_id = sesf.event_session_id
	WHERE sesf.name = 'filename'
	AND ses.name = 'Recompile_Histogram'
	) cte1
OUTER APPLY sys.fn_xe_file_target_read_file(cte1.targetvalue,REPLACE(cte1.targetvalue, '*.xel', '*.xem'), NULL, NULL) t2
;



SELECT 
  sv.subclass_name as recompile_cause
, shredded.recompile_count
FROM sys.dm_xe_session_targets AS xet  
INNER JOIN sys.dm_xe_sessions AS xe  
       ON (xe.address = xet.event_session_address)  
 CROSS APPLY ( SELECT CAST(xet.target_data as xml) ) as target_data_xml ([xml])
 CROSS APPLY target_data_xml.[xml].nodes('/HistogramTarget/Slot') AS nodes (slot_data)
 CROSS APPLY (
         SELECT nodes.slot_data.value('(value)[1]', 'int') AS recompile_cause,
                nodes.slot_data.value('(@count)[1]', 'int') AS recompile_count
       ) as shredded
  JOIN sys.trace_subclass_values AS sv
       ON shredded.recompile_cause = sv.subclass_value
 WHERE xe.name = 'Recompile_Histogram' 
   AND sv.trace_event_id = 37 -- SP:Recompile