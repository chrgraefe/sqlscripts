
	EXEC sp_MSforeachtable @command1="print '?' DBCC DBREINDEX ('?')"

	CHECKPOINT 

	DBCC DROPCLEANBUFFERS

	DBCC FREEPROCCACHE

	DECLARE @intDBID INTEGER 
	SET @intDBID = DB_ID()

	DBCC FLUSHPROCINDB (@intDBID)

	declare @procNames Table (procName varchar(255))
	insert into @procNames
	select name from sysObjects where xtype in ('V','P','U','FN','TF','TR' ) and status > 0

	set nocount off
	--3. Run each command
	-- =============================================
	-- Declare and using a READ_ONLY cursor
	-- =============================================
	DECLARE RecompilableItemsCursor CURSOR
	READ_ONLY
	FOR select procName from @procNames

	DECLARE @RecompilableItem varchar(255)
	OPEN RecompilableItemsCursor

	FETCH NEXT FROM RecompilableItemsCursor INTO @RecompilableItem
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN
			DECLARE @sql varchar(300)
			select @sql = 'Exec sp_recompile ' + @RecompilableItem
			print @sql
			--exec (@sql)
		END
		FETCH NEXT FROM RecompilableItemsCursor INTO @RecompilableItem
	END

	CLOSE RecompilableItemsCursor
	DEALLOCATE RecompilableItemsCursor

	EXEC sp_updatestats
