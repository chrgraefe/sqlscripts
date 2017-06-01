WITH MemBuffers AS ( 
	SELECT   
	 EventTime
	,record.value('(/Record/ResourceMonitor/Notification)[1]', 'varchar(max)') AS [Type]
	,record.value('(/Record/@id)[1]', 'int') AS RecordID
	,record.value('(/Record/MemoryNode/@id)[1]', 'int') AS MemoryNodeID
	FROM     
	( 
		SELECT    
		 DATEADD(ss, ( -1 * ( ( cpu_ticks / CONVERT (FLOAT, ( cpu_ticks / ms_ticks )) ) - [timestamp] ) / 1000 ), GETDATE()) AS EventTime 
		,CONVERT (XML, record) AS record
		FROM sys.dm_os_ring_buffers
		CROSS JOIN sys.dm_os_sys_info
		WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
	) AS tab
)
,OrderedBuffers AS 
( 
	SELECT   
	 EventTime
	,Type
	,RecordID
	,MemoryNodeID
	,ROW_NUMBER() OVER ( ORDER BY MemoryNodeID, MemBuffers.RecordID DESC, MemBuffers.EventTime DESC ) AS RowNum
	FROM MemBuffers
	WHERE    
		EventTime > DATEADD(DAY, -1, GETDATE())
    AND Type IN ( 'RESOURCE_MEMPHYSICAL_LOW', 'RESOURCE_MEM_STEADY' )

    UNION

	SELECT DISTINCT
	 GETDATE() 
	,'Header' 
	,0 
	,MemoryNodeID 
	,0
	FROM MemBuffers
)
SELECT  
SUM(CONVERT(INT, ABS(CONVERT(FLOAT, ob1.EventTime - ob.EventTime) * 24 * 60 * 60))) AS SecondsPressure
FROM OrderedBuffers ob
LEFT JOIN OrderedBuffers ob1 ON 
		ob.RowNum = ob1.RowNum + 1
	AND ob.MemoryNodeID = ob1.MemoryNodeID
WHERE
	ob.Type = 'RESOURCE_MEMPHYSICAL_LOW'
;