DECLARE 
 @IndexName VARCHAR(255)
,@SchemaName VARCHAR(255)
,@TableName VARCHAR(255)
,@PartitionNumber INT
,@NumOfPartitions INT
,@SqlString VARCHAR(4000)
,@Fragmentation FLOAT
,@IndexReOrgType VARCHAR(20)
,@IndexPartitionClause VARCHAR(20)
 
DECLARE TableCursor CURSOR FOR
SELECT 
 si.[name] as index_name
,sdm.avg_fragmentation_in_percent
,sm.name as schemaname
,so.[name] as table_name
,sdm.partition_number
,NumOfPartitions = (SELECT COUNT(1) FROM sys.partitions p WHERE p.object_id = so.object_id And p.index_id = si.index_id)
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) sdm
inner join sys.indexes si ON 
		sdm.object_id = si.object_id 
	and si.index_id = sdm.index_id
inner join sys.objects so ON 
	so.object_id = si.object_id
inner join sys.schemas sm ON 
	sm.schema_id = so.schema_id
WHERE 
	si.[name] IS NOT NULL /* don't consider indexes on heap tables */
ORDER BY sm.[name], table_name, si.[name]

--Notice variable declarations and a cursor for a future loop. Since I already described this part of the query, let’s fast forward to second step. Here’s the code:
OPEN TableCursor
 
FETCH NEXT FROM TableCursor 
INTO @IndexName, @Fragmentation, @SchemaName, @TableName, @PartitionNumber, @NumOfPartitions

WHILE @@FETCH_STATUS = 0
BEGIN
	
	SET @SqlString = ''

	/* only reorganize indexes which are more the 5% fragmented */
	if @Fragmentation > 5.0 
	BEGIN

		/* Assign the best index reorganization type*/
		if @Fragmentation < 30.0 and @Fragmentation > 5
		begin
			SET @IndexReOrgType = 'REORGANIZE'	
		END
		else if @Fragmentation > 30.0
		begin
			SET @IndexReOrgType = 'REBUILD'
		End
		
		IF @NumOfPartitions > 1
			SET @IndexPartitionClause = ' PARTITION = ' + CAST(@PartitionNumber AS VARCHAR(10))	
		ELSE
			SET @IndexPartitionClause = ''
		

		SET @SqlString = 'ALTER INDEX ' + @IndexName + ' ON [' + @SchemaName + '].[' + @TableName + '] ' + @IndexReOrgType
		SET @SqlString += ' ' + @IndexPartitionClause
		SET @SqlString += ';' + CHAR(13)
		SET @SqlString += 'UPDATE STATISTICS [' + @SchemaName + '].[' + @TableName + '] ' + @IndexName + ';'
			
		PRINT (@SqlString)
		--EXEC  (@SqlString)

	END

	FETCH NEXT FROM TableCursor 
	INTO @IndexName, @Fragmentation, @SchemaName, @TableName, @PartitionNumber, @NumOfPartitions
END

CLOSE TableCursor
DEALLOCATE TableCursor