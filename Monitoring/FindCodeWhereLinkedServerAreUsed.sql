DECLARE @TABLE TABLE
(
	 LinkedServer VARCHAR(200)
	,[OBJECT_NAME] VARCHAR(200)
	,[JOBNAME] VARCHAR(200)
	,[OBJECT_TYPE] VARCHAR(200)
	,[COMMAND] VARCHAR(4000)
)

Declare @VName varchar(256)
Declare Findlinked cursor
LOCAL STATIC FORWARD_ONLY READ_ONLY
     FOR
Select name AS name
	From sys.servers
	Where is_linked = 1

Open Findlinked;
Fetch next from Findlinked into @VName;

while @@FETCH_STATUS = 0
Begin
	
		INSERT INTO @TABLE 
		(
			 LinkedServer
			,[OBJECT_NAME]
			,[OBJECT_TYPE] 
		)
	    SELECT @VName LinkedServer, OBJECT_NAME(object_id) [OBJECT_NAME], 'Procedure' [OBJECT_TYPE] 
		FROM sys.sql_modules 
		WHERE Definition LIKE '%'+@VName +'.%' 
		AND OBJECTPROPERTY(object_id, 'IsProcedure') = 1 ;

	Fetch next from Findlinked into @VName;
END
Close Findlinked

Open Findlinked;
Fetch next from Findlinked into @VName;

while @@FETCH_STATUS = 0
Begin
	INSERT INTO @TABLE 
		(
			 LinkedServer
			,[JOBNAME]
			,[COMMAND] 
		)
	SELECT @VName LinkedServer, j.name AS JobName,js.command 
		FROM msdb.dbo.sysjobsteps js
			INNER JOIN msdb.dbo.sysjobs j
				ON j.job_id = js.job_id
		WHERE js.command LIKE '%'+@VName +'.%'
	Fetch next from Findlinked into @VName;
END

Close Findlinked
Deallocate Findlinked


SELECT
*
FROM @TABLE;