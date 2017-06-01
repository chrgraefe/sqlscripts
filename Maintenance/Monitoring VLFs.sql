drop table #stage;
Create Table #stage(
    FileID      int
  , FileSize    bigint
  , StartOffset bigint
  , FSeqNo      bigint
  , [Status]    bigint
  , Parity      bigint
  , CreateLSN   numeric(38)
);
 
DECLARE @query NVARCHAR(MAX) = 'dbcc loginfo () '  ;
  
   

Insert Into #stage 
exec (@query) ;
 


SELECT
 FileId
,FileSize * 1.0 / 1024 / 1024 [FileSize in MB]
,StartOffset
,FSeqNo
,[Status]
,CASE [Status] 
	WHEN 2 THEN 'VLF is active'
	ELSE 'VLF is NOT active'
 END [Status description] 
,Parity
,CreateLSN
FROM #stage
ORDER BY FSeqNo



/*
Größenanpassung des TRANSACTION-Logs#

*/


SELECT * FROM sys.database_files df
where
	type_desc = 'LOG'
;


/*
DBCC SHRINKFILE(transactionloglogicalfilename, TRUNCATEONLY)


--Alter the database to modify the transaction log file to the appropriate size – in one step

ALTER DATABASE [DPS]
MODIFY FILE 
( 
      NAME = transactionloglogicalfilename 
    , SIZE = [newtotalsize]
    , FILEGROWTH = [growth_increment in ]GB 
);
*/