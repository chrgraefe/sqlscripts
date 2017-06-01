/*
Abfragen mit Key-Lookup oder Clustered Index Scan
*/
WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT
  cp.query_hash
, cp.query_plan_hash
, PhysicalOperator = operators.value('@PhysicalOp','nvarchar(50)')
, LogicalOp = operators.value('@LogicalOp','nvarchar(50)')
, AvgRowSize = operators.value('@AvgRowSize','nvarchar(50)')
, EstimateCPU = operators.value('@EstimateCPU','nvarchar(50)')
, EstimateIO = operators.value('@EstimateIO','nvarchar(50)')
, EstimateRebinds = operators.value('@EstimateRebinds','nvarchar(50)')
, EstimateRewinds = operators.value('@EstimateRewinds','nvarchar(50)')
, EstimateRows = operators.value('@EstimateRows','nvarchar(50)')
, Parallel = operators.value('@Parallel','nvarchar(50)')
, NodeId = operators.value('@NodeId','nvarchar(50)')
, EstimatedTotalSubtreeCost =   operators.value('@EstimatedTotalSubtreeCost','nvarchar(50)')
FROM sys.dm_exec_query_stats cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
CROSS APPLY query_plan.nodes('//RelOp') rel(operators)
;