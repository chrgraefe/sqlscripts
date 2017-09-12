WITH CTE AS
(
    SELECT 
      Operation
    , Context
    , [Transaction ID]
    , OBJECT_NAME(object_id) ObjectName
    , [Begin Time]
    , [Transaction SID]
    FROM fn_dblog(NULL, NULL)
    INNER JOIN sys.partitions ON fn_dblog.PartitionId = partitions.partition_id
    WHERE 
        OBJECT_NAME(object_id) = 'person'
    AND index_id = 1
)
SELECT 
  CTE.Operation
, CTE.Context
, CTE.[Transaction ID]
, CTE.ObjectName
, fn_dblog.[Begin Time]
, fn_dblog.[Transaction SID]
, SUSER_SNAME(fn_dblog.[Transaction SID]) AS UserName
FROM CTE
INNER JOIN fn_dblog(NULL,NULL) ON 
    CTE.[Transaction ID] = fn_dblog.[Transaction ID]
WHERE 
    fn_dblog.Operation = 'LOP_BEGIN_XACT'
;