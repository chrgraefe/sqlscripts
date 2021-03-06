/*
Brent Ozar Unlimited(TM)'s Temp Stored Procs for SQL 2008 and Newer
-------------------------------------------------------------------

If you're only allowed to create stored procedures in TempDB, execute this
file and you'll get all of our utility stored procedures. Keep in mind, of
course, that they won't be present on system restart.

Feb 23, 2015. For updated versions: http://www.BrentOzar.com/go/download
*/



IF OBJECT_ID('tempdb..##sp_BlitzCache') IS NULL
  EXEC ('CREATE PROCEDURE ##sp_BlitzCache AS RETURN 0;')
GO

IF OBJECT_ID('tempdb..##sp_BlitzCache') IS NOT NULL AND OBJECT_ID('##bou_BlitzCacheProcs') IS NOT NULL
    EXEC ('DROP TABLE ##bou_BlitzCacheProcs;')
GO

IF OBJECT_ID('tempdb..##sp_BlitzCache') IS NOT NULL AND OBJECT_ID('##bou_BlitzCacheResults') IS NOT NULL
    EXEC ('DROP TABLE ##bou_BlitzCacheResults;')
GO

ALTER PROCEDURE ##sp_BlitzCache
    @get_help BIT = 0,
    @top INT = 50,
    @sort_order VARCHAR(50) = 'CPU',
    @use_triggers_anyway BIT = NULL,
    @export_to_excel BIT = 0,
    @results VARCHAR(10) = 'simple',
    @output_database_name NVARCHAR(128) = NULL ,
    @output_schema_name NVARCHAR(256) = NULL ,
    @output_table_name NVARCHAR(256) = NULL ,
    @configuration_database_name NVARCHAR(128) = NULL ,
    @configuration_schema_name NVARCHAR(256) = NULL ,
    @configuration_table_name NVARCHAR(256) = NULL ,
    @duration_filter DECIMAL(38,4) = NULL ,
    @hide_summary BIT = 0 ,
    @ignore_system_db BIT = 1 ,
    @only_query_hashes VARCHAR(MAX) = NULL ,
    @ignore_query_hashes VARCHAR(MAX) = NULL ,
    @query_filter VARCHAR(10) = 'ALL' ,
    @reanalyze BIT = 0 ,
    @whole_cache BIT = 0 /* This will forcibly set @top to 2,147,483,647 */
WITH RECOMPILE
/******************************************
sp_BlitzCache (TM) 2014, Brent Ozar Unlimited.
(C) 2014, Brent Ozar Unlimited.
See http://BrentOzar.com/go/eula for the End User Licensing Agreement.



Description: Displays a server level view of the SQL Server plan cache.

Output: One result set is presented that contains data from the statement,
procedure, and trigger stats DMVs.

To learn more, visit http://brentozar.com/blitzcache/
where you can download new versions for free, watch training videos on
how it works, get more info on the findings, and more. To contribute
code and see your name in the change log, submit your improvements &
ideas to https://support.brentozar.com



KNOWN ISSUES:
- This query will not run on SQL Server 2005.
- SQL Server 2008 and 2008R2 have a bug in trigger stats (see below).
- @ignore_query_hashes and @only_query_hashes require a CSV list of hashes
  with no spaces between the hash values.

v2.4.5 - 2015-04-27
 - sp_BlitzCache will no longer fail if @reanalyze = 1 AND sp_BlitzCache has
   never been run.
 - sp_BlitzCache can be run from multiple SPIDs.
 - Triggers will no longer cause sp_BlitzCache to notice itself.
 - Fixed an int overflow when determining execution time. Now using DATEDIFF
   on minutes of execution time instead of seconds. Queries that have used 
   more than 28,000 days of CPU are safe!

v2.4.4 - 2015-01-09
 - Fixed output to table. Sort order wasn't being obeyed and users limting
   results weren't seeing the same results between displaying to screen and
   saving results to a table.
   Thanks to Gail Jurey for spotting this!
 - Fixed an error where running with reanalyze after export_to_excel would
   prevent a summary from being generated.
 - Added query plan cost to export_to_excel output.
 - Cleaned up export_to_excel output to match column order to screen display.

v2.4.3 - 2014-11-11
 - Fix to remove confusing implicit conversion checks. Warnings will only be
   generated when a plan affecting convert is in place.

v2.4.2 - 2014-11-04
 - Hotfix - Randall Petty found a stray comma in the export_to_excel output.

v2.4.1 - 2014-10-31
 - Hotfix - Denis Gobo pointed out that the global temp table names could
   conflict with everyone else's global temp table rates.

v2.4 - 2014-10-31
 - Fixed a logical error in output table detection - thanks to Michael
   Bluett for pointing that out.
 - Fixed a bug where sorting on average executions broke the query.
   Thanks to Andrew Notarian and Calvin Jones for submitting this.
 - Added @query_filter to allow output restrictions to only procedures
   or individual statements
 - Adds a check for trivial execution plans.
 - Adds @reanalyze. When set to 1, this re-scans existing results rather
   than running all of the logic again. Bonus: contains GOTO.
 - Now displaying set options!

v2.3 - 2014-06-07
 - Added opserver specific output
 - Adding a `@only_query_hashes` parameter to limit results to a select set of
   query hashes.
 - Adding a `@ignore_query_hashes` parameter to exclude specific queries from
   analysis.

v2.2 - 2014-05-20
 - Added sorting on averages
 - Added configuration table parameters. Includes help messages for the
   allowed parameters and default values.
 - Missing index warning now displays the number of missing indexes.
 - Changing display to milliseconds instead of microseconds.
 - Adding a flag to ignore system databases. This is on by default.
 - Correcting a typo found by Michael Zilberstein. Thanks!
 - Fixing an XML bug for implicit conversion detection - contributed by Michael Zilberstein.
 - Added a check for unparameterized queries.

v2.1 - 2014-04-30
 - Added @duration_filter. Queries are now filtered during collection based on duration.
 - Added results summary table and hide_summary parameter.
 - Added check for > 1000 executions per minute.
 - Added check for queries with missing indexes.
 - Added check for queries with warnings in the execution plan.
 - Added check for queries using cursors.
 - Query cost will be displayed next to the execution plan for a query.
 - Added a check for plan guides and forced plans.
 - An asterisk will be displayed next to the name of queries that have gone parallel.
 - Added a check for parallel plans.
 - Added @results parameter - options are 'narrow', 'simple', and 'expert'
 - Added a check for plans using a downlevel cardinality estimator
 - Added checks for plans with implicit conversions or plan affecting convert warnings
 - Added check for queries with spill warnings
 - Consolidated warning detection into a smaller number of T-SQL statements
 - Added a Warnings column
 - Added "busy loops" check
 - Fixed bug where long-running query threshold was 300 microseconds, not seconds

v2.0 - 2014-03-23
 - Created a stored procedure
 - Added write information
 - Added option to export to a single table
 - Corrected accidental exclusion of trigger information

v1.4 - 2014-02-17
 - MOAR BUG FIXES
 - Corrected multiple sorting bugs that cause confusing displays of query
   results that weren't necessarily the top anything.
 - Updated all modification timestamps to use ISO 8601 formatting because it's
   correct, sorry Britain.
 - Added a check for SQL Server 2008R2 build greater than SP1.
   Thanks to Kevan Riley for spotting this.
 - Added the stored procedure or trigger name to the Query Type column.
   Initial suggestion from Kevan Riley.
 - Corrected erronous math that could allow for % CPU/Duration/Executions/Reads
   being higher than 100% for batches/procedures with multiple poorly
   performing statements in them.

v1.3 - 2014-02-06
 - As they say on the app store, "Bug fixes"
 - Reorganized this to put the standard, gotta-run stuff at the top.
 - Switched to YYYY/MM/DD because Brits.

v1.2 - 2014-02-04
- Removed debug code
- Fixed output where SQL Server 2008 and early don't support min_rows,
  max_rows, and total_rows.
  SQL Server 2008 and earlier will now return NULL for those columns.

v1.1 - 2014-02-02
- Incorporated sys.dm_exec_plan_attributes as recommended by Andrey
  and Michael J. Swart.
- Added additional detail columns for plan cache analysis including
  min/max rows, total rows.
- Streamlined collection of data.



*******************************************/
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
/* VERSION! */
RAISERROR (N'Executing sp_BlitzCache v2.4.5', 0, 1) WITH NOWAIT ;

DECLARE @nl nvarchar(2) = NCHAR(13) + NCHAR(10) ;

IF @get_help = 1
BEGIN
    SELECT N'@get_help' AS [Parameter Name] ,
           N'BIT' AS [Data Type] ,
           N'Displays this help message.' AS [Parameter Description]

    UNION ALL
    SELECT N'@top',
           N'INT',
           N'The number of records to retrieve and analyze from the plan cache. The following DMVs are used as the plan cache: dm_exec_query_stats, dm_exec_procedure_stats, dm_exec_trigger_stats.'

    UNION ALL
    SELECT N'@sort_order',
           N'VARCHAR(10)',
           N'Data processing and display order. @sort_order will still be used, even when preparing output for a table or for excel. Possible values are: "CPU", "Reads", "Writes", "Duration", "Executions". Additionally, the word "Average" or "Avg" can be used to sort on averages rather than total. "Executions per minute" and "Executions / minute" can be used to sort by execution per minute. For the truly lazy, "xpm" can also be used.'

    UNION ALL
    SELECT N'@use_triggers_anyway',
           N'BIT',
           N'On SQL Server 2008R2 and earlier, trigger execution count is incorrect - trigger execution count is incremented once per execution of a SQL agent job. If you still want to see relative execution count of triggers, then you can force sp_BlitzCache to include this information.'

    UNION ALL
    SELECT N'@export_to_excel',
           N'BIT',
           N'Prepare output for exporting to Excel. Newlines and additional whitespace are removed from query text and the execution plan is not displayed.'

    UNION ALL
    SELECT N'@results',
           N'VARCHAR(10)',
           N'Results mode. Options are "Narrow", "Simple", or "Expert". This determines which columns will be displayed in the analysis of the plan cache.'

    UNION ALL
    SELECT N'@output_database_name',
           N'NVARCHAR(128)',
           N'The output database. If this does not exist SQL Server will divide by zero and everything will fall apart.'

    UNION ALL
    SELECT N'@output_schema_name',
           N'NVARCHAR(256)',
           N'The output schema. If this does not exist SQL Server will divide by zero and everything will fall apart.'

    UNION ALL
    SELECT N'@output_table_name',
           N'NVARCHAR(256)',
           N'The output table. If this does not exist, it will be created for you.'

    UNION ALL
    SELECT N'@duration_filter',
           N'DECIMAL(38,4)',
           N'Excludes queries with an average duration (in seconds) less than @duration_filter.'

    UNION ALL
    SELECT N'@hide_summary',
           N'BIT',
           N'Hides the findings summary result set.'

    UNION ALL
    SELECT N'@ignore_system_db',
           N'BIT',
           N'Ignores plans found in the system databases (master, model, msdb, tempdb, and resourcedb)'

    UNION ALL
    SELECT N'@only_query_hashes',
           N'VARCHAR(MAX)',
           N'A list of query hashes to query. All other query hashes will be ignored. Stored procedures and triggers will be ignored.'

    UNION ALL
    SELECT N'@ignore_query_hashes',
           N'VARCHAR(MAX)',
           N'A list of query hashes to ignore.'
           
    UNION ALL
    SELECT N'@whole_cache',
           N'BIT',
           N'This forces sp_BlitzCache to examine the entire plan cache. Be careful running this on servers with a lot of memory or a large execution plan cache.'

    UNION ALL
    SELECT N'@query_filter',
           N'VARCHAR(10)',
           N'Filter out stored procedures or statements. The default value is ''ALL''. Allowed values are ''procedures'', ''statements'', or ''all'' (any variation in capitalization is acceptable).'

    UNION ALL
    SELECT N'@reanalyze',
           N'BIT',
           N'The default is 0. When set to 0, sp_BlitzCache will re-evalute the plan cache. Set this to 1 to reanalyze existing results';
           


    /* Column definitions */
    SELECT N'# Executions' AS [Column Name],
           N'BIGINT' AS [Data Type],
           N'The number of executions of this particular query. This is computed across statements, procedures, and triggers and aggregated by the SQL handle.' AS [Column Description]

    UNION ALL
    SELECT N'Executions / Minute',
           N'MONEY',
           N'Number of executions per minute - calculated for the life of the current plan. Plan life is the last execution time minus the plan creation time.'

    UNION ALL
    SELECT N'Execution Weight',
           N'MONEY',
           N'An arbitrary metric of total "execution-ness". A weight of 2 is "one more" than a weight of 1.'

    UNION ALL
    SELECT N'Database',
           N'sysname',
           N'The name of the database where the plan was encountered. If the database name cannot be determined for some reason, a value of NA will be substituted. A value of 32767 indicates the plan comes from ResourceDB.'

    UNION ALL
    SELECT N'Total CPU',
           N'BIGINT',
           N'Total CPU time, reported in milliseconds, that was consumed by all executions of this query since the last compilation.'

    UNION ALL
    SELECT N'Avg CPU',
           N'BIGINT',
           N'Average CPU time, reported in milliseconds, consumed by each execution of this query since the last compilation.'

    UNION ALL
    SELECT N'CPU Weight',
           N'MONEY',
           N'An arbitrary metric of total "CPU-ness". A weight of 2 is "one more" than a weight of 1.'


    UNION ALL
    SELECT N'Total Duration',
           N'BIGINT',
           N'Total elapsed time, reported in milliseconds, consumed by all executions of this query since last compilation.'

    UNION ALL
    SELECT N'Avg Duration',
           N'BIGINT',
           N'Average elapsed time, reported in milliseconds, consumed by each execution of this query since the last compilation.'

    UNION ALL
    SELECT N'Duration Weight',
           N'MONEY',
           N'An arbitrary metric of total "Duration-ness". A weight of 2 is "one more" than a weight of 1.'

    UNION ALL
    SELECT N'Total Reads',
           N'BIGINT',
           N'Total logical reads performed by this query since last compilation.'

    UNION ALL
    SELECT N'Average Reads',
           N'BIGINT',
           N'Average logical reads performed by each execution of this query since the last compilation.'

    UNION ALL
    SELECT N'Read Weight',
           N'MONEY',
           N'An arbitrary metric of "Read-ness". A weight of 2 is "one more" than a weight of 1.'

    UNION ALL
    SELECT N'Total Writes',
           N'BIGINT',
           N'Total logical writes performed by this query since last compilation.'

    UNION ALL
    SELECT N'Average Writes',
           N'BIGINT',
           N'Average logical writes performed by each execution this query since last compilation.'

    UNION ALL
    SELECT N'Write Weight',
           N'MONEY',
           N'An arbitrary metric of "Write-ness". A weight of 2 is "one more" than a weight of 1.'

    UNION ALL
    SELECT N'Query Type',
           N'NVARCHAR(256)',
           N'The type of query being examined. This can be "Procedure", "Statement", or "Trigger".'

    UNION ALL
    SELECT N'Query Text',
           N'NVARCHAR(4000)',
           N'The text of the query. This may be truncated by either SQL Server or by sp_BlitzCache(tm) for display purposes.'

    UNION ALL
    SELECT N'% Executions (Type)',
           N'MONEY',
           N'Percent of executions relative to the type of query - e.g. 17.2% of all stored procedure executions.'

    UNION ALL
    SELECT N'% CPU (Type)',
           N'MONEY',
           N'Percent of CPU time consumed by this query for a given type of query - e.g. 22% of CPU of all stored procedures executed.'

    UNION ALL
    SELECT N'% Duration (Type)',
           N'MONEY',
           N'Percent of elapsed time consumed by this query for a given type of query - e.g. 12% of all statements executed.'

    UNION ALL
    SELECT N'% Reads (Type)',
           N'MONEY',
           N'Percent of reads consumed by this query for a given type of query - e.g. 34.2% of all stored procedures executed.'

    UNION ALL
    SELECT N'% Writes (Type)',
           N'MONEY',
           N'Percent of writes performed by this query for a given type of query - e.g. 43.2% of all statements executed.'

    UNION ALL
    SELECT N'Total Rows',
           N'BIGINT',
           N'Total number of rows returned for all executions of this query. This only applies to query level stats, not stored procedures or triggers.'

    UNION ALL
    SELECT N'Average Rows',
           N'MONEY',
           N'Average number of rows returned by each execution of the query.'

    UNION ALL
    SELECT N'Min Rows',
           N'BIGINT',
           N'The minimum number of rows returned by any execution of this query.'

    UNION ALL
    SELECT N'Max Rows',
           N'BIGINT',
           N'The maximum number of rows returned by any execution of this query.'

    UNION ALL
    SELECT N'# Plans',
           N'INT',
           N'The total number of execution plans found that match a given query.'

    UNION ALL
    SELECT N'# Distinct Plans',
           N'INT',
           N'The number of distinct execution plans that match a given query. '
            + NCHAR(13) + NCHAR(10)
            + N'This may be caused by running the same query across multiple databases or because of a lack of proper parameterization in the database.'

    UNION ALL
    SELECT N'Created At',
           N'DATETIME',
           N'Time that the execution plan was last compiled.'

    UNION ALL
    SELECT N'Last Execution',
           N'DATETIME',
           N'The last time that this query was executed.'

    UNION ALL
    SELECT N'Query Plan',
           N'XML',
           N'The query plan. Click to display a graphical plan or, if you need to patch SSMS, a pile of XML.'

    UNION ALL
    SELECT N'Plan Handle',
           N'VARBINARY(64)',
           N'An arbitrary identifier referring to the compiled plan this query is a part of.'

    UNION ALL
    SELECT N'SQL Handle',
           N'VARBINARY(64)',
           N'An arbitrary identifier referring to a batch or stored procedure that this query is a part of.'

    UNION ALL
    SELECT N'Query Hash',
           N'BINARY(8)',
           N'A hash of the query. Queries with the same query hash have similar logic but only differ by literal values or database.'

    UNION ALL
    SELECT N'Warnings',
           N'VARCHAR(MAX)',
           N'A list of individual warnings generated by this query.' ;


           
    /* Configuration table description */
    SELECT N'Frequent Execution Threshold' AS [Configuration Parameter] ,
           N'100' AS [Default Value] ,
           N'Executions / Minute' AS [Unit of Measure] ,
           N'Executions / Minute before a "Frequent Execution Threshold" warning is triggered.' AS [Description]

    UNION ALL
    SELECT N'Parameter Sniffing Variance Percent' ,
           N'30' ,
           N'Percent' ,
           N'Variance required between min/max values and average values before a "Parameter Sniffing" warning is triggered. Applies to worker time and returned rows.'

    UNION ALL
    SELECT N'Parameter Sniffing IO Threshold' ,
           N'100,000' ,
           N'Logical reads' ,
           N'Minimum number of average logical reads before parameter sniffing checks are evaluated.'

    UNION ALL
    SELECT N'Cost Threshold for Parallelism Warning' AS [Configuration Parameter] ,
           N'10' ,
           N'Percent' ,
           N'Trigger a "Nearly Parallel" warning when a query''s cost is within X percent of the cost threshold for parallelism.'

    UNION ALL
    SELECT N'Long Running Query Warning' AS [Configuration Parameter] ,
           N'300' ,
           N'Seconds' ,
           N'Triggers a "Long Running Query Warning" when average duration, max CPU time, or max clock time is higher than this number.'

    RETURN
END

DECLARE @duration_filter_i INT,
        @msg NVARCHAR(4000) ;

RAISERROR (N'Setting up temporary tables for sp_BlitzCache',0,1) WITH NOWAIT;

/* Change duration from seconds to milliseconds */
IF @duration_filter IS NOT NULL
  SET @duration_filter_i = CAST((@duration_filter * 1000.0) AS INT)

SET @sort_order = LOWER(@sort_order);
SET @sort_order = REPLACE(REPLACE(@sort_order, 'average', 'avg'), '.', '');
SET @sort_order = REPLACE(@sort_order, 'executions per minute', 'avg executions');
SET @sort_order = REPLACE(@sort_order, 'executions / minute', 'avg executions');
SET @sort_order = REPLACE(@sort_order, 'xpm', 'avg executions');


IF @sort_order NOT IN ('cpu', 'avg cpu', 'reads', 'avg reads', 'writes', 'avg writes',
                       'duration', 'avg duration', 'executions', 'avg executions')
  SET @sort_order = 'cpu';

SELECT @output_database_name = QUOTENAME(@output_database_name),
       @output_schema_name   = QUOTENAME(@output_schema_name),
       @output_table_name    = QUOTENAME(@output_table_name);

SET @query_filter = LOWER(@query_filter);

IF LEFT(@query_filter, 3) NOT IN ('all', 'sta', 'pro')
  SET @query_filter = 'all';

IF @reanalyze = 1 AND OBJECT_ID('tempdb..##bou_BlitzCacheResults') IS NULL
	SET @reanalyze = 0;

IF @reanalyze = 1 
    GOTO Results


IF OBJECT_ID('tempdb..#only_query_hashes') IS NOT NULL
    DROP TABLE #only_query_hashes ;

IF OBJECT_ID('tempdb..#ignore_query_hashes') IS NOT NULL
    DROP TABLE #ignore_query_hashes ;
   
IF OBJECT_ID('tempdb..##bou_BlitzCacheResults') IS NOT NULL
    DROP TABLE ##bou_BlitzCacheResults;

IF OBJECT_ID('tempdb..#p') IS NOT NULL
    DROP TABLE #p;

IF OBJECT_ID('tempdb..##bou_BlitzCacheProcs') IS NOT NULL
    DROP TABLE ##bou_BlitzCacheProcs;

IF OBJECT_ID ('tempdb..#checkversion') IS NOT NULL
    DROP TABLE #checkversion;

IF OBJECT_ID ('tempdb..#configuration') IS NOT NULL
    DROP TABLE #configuration;

CREATE TABLE #only_query_hashes (
    query_hash BINARY(8)
);

CREATE TABLE #ignore_query_hashes (
    query_hash BINARY(8)
);

CREATE TABLE ##bou_BlitzCacheResults (
	SPID INT,
    ID INT IDENTITY(1,1),
    CheckID INT,
    Priority TINYINT,
    FindingsGroup VARCHAR(50),
    Finding VARCHAR(200),
    URL VARCHAR(200),
    Details VARCHAR(4000)	
);

CREATE TABLE #p (
    SqlHandle varbinary(64),
    TotalCPU bigint,
    TotalDuration bigint,
    TotalReads bigint,
    TotalWrites bigint,
    ExecutionCount bigint
);

CREATE TABLE #checkversion (
    version nvarchar(128),
    maj_version AS SUBSTRING(version, 1,CHARINDEX('.', version) + 1 ),
    build AS PARSENAME(CONVERT(varchar(32), version), 2)
);

CREATE TABLE #configuration (
    parameter_name VARCHAR(100),
    value DECIMAL(38,0)
);

CREATE TABLE ##bou_BlitzCacheProcs (
	SPID INT ,
    QueryType nvarchar(256),
    DatabaseName sysname,
    AverageCPU decimal(38,4),
    AverageCPUPerMinute decimal(38,4),
    TotalCPU decimal(38,4),
    PercentCPUByType money,
    PercentCPU money,
    AverageDuration decimal(38,4),
    TotalDuration decimal(38,4),
    PercentDuration money,
    PercentDurationByType money,
    AverageReads bigint,
    TotalReads bigint,
    PercentReads money,
    PercentReadsByType money,
    ExecutionCount bigint,
    PercentExecutions money,
    PercentExecutionsByType money,
    ExecutionsPerMinute money,
    TotalWrites bigint,
    AverageWrites money,
    PercentWrites money,
    PercentWritesByType money,
    WritesPerMinute money,
    PlanCreationTime datetime,
    LastExecutionTime datetime,
    PlanHandle varbinary(64),
    SqlHandle varbinary(64),
    QueryHash binary(8),
    QueryPlanHash binary(8),
    StatementStartOffset int,
    StatementEndOffset int,
    MinReturnedRows bigint,
    MaxReturnedRows bigint,
    AverageReturnedRows money,
    TotalReturnedRows bigint,
    LastReturnedRows bigint,
    QueryText nvarchar(max),
    QueryPlan xml,
    /* these next four columns are the total for the type of query.
        don't actually use them for anything apart from math by type.
        */
    TotalWorkerTimeForType bigint,
    TotalElapsedTimeForType bigint,
    TotalReadsForType bigint,
    TotalExecutionCountForType bigint,
    TotalWritesForType bigint,
    NumberOfPlans int,
    NumberOfDistinctPlans int,
    min_worker_time bigint,
    max_worker_time bigint,
    is_forced_plan bit,
    is_forced_parameterized bit,
    is_cursor bit,
    is_parallel bit,
    frequent_execution bit,
    parameter_sniffing bit,
    unparameterized_query bit,
    near_parallel bit,
    plan_warnings bit,
    plan_multiple_plans bit,
    long_running bit,
    downlevel_estimator bit,
    implicit_conversions bit,
    tempdb_spill bit,
    busy_loops bit,
    tvf_join bit,
    tvf_estimate bit,
    compile_timeout bit,
    compile_memory_limit_exceeded bit,
    warning_no_join_predicate bit,
    QueryPlanCost float,
    missing_index_count int,
    unmatched_index_count int,
    min_elapsed_time bigint,
    max_elapsed_time bigint,
    age_minutes money,
    age_minutes_lifetime money,
    is_trivial bit,
    SetOptions VARCHAR(MAX),
    Warnings VARCHAR(MAX)
);

SET @only_query_hashes = LTRIM(RTRIM(@only_query_hashes)) ;
SET @ignore_query_hashes = LTRIM(RTRIM(@ignore_query_hashes)) ;

IF ((@only_query_hashes IS NOT NULL AND LEN(@only_query_hashes) > 0)
    OR (@ignore_query_hashes IS NOT NULL AND LEN(@ignore_query_hashes) > 0))
   AND LEFT(@query_filter, 3) = 'pro'
BEGIN
   RAISERROR('You cannot limit by query hash and filter by stored procedure', 16, 1);
   RETURN;
END

/* If the user is attempting to limit by query hash, set up the
   #only_query_hashes temp table. This will be used to narrow down
   results.

   Just a reminder: Using @only_query_hashes will ignore stored
   procedures and triggers.
 */
IF @only_query_hashes IS NOT NULL
   AND LEN(@only_query_hashes) > 0
BEGIN
   DECLARE @individual VARCHAR(50) ;

   WHILE LEN(@only_query_hashes) > 0
   BEGIN
        IF PATINDEX('%,%', @only_query_hashes) > 0
        BEGIN  
               SET @individual = SUBSTRING(@only_query_hashes, 0, PATINDEX('%,%',@only_query_hashes)) ;
               
               INSERT INTO #only_query_hashes
               select cast('' as xml).value('xs:hexBinary( substring(sql:variable("@individual"), sql:column("t.pos")) )', 'varbinary(max)')
               from (select case substring(@individual, 1, 2) when '0x' then 3 else 0 end) as t(pos)
               
               --SELECT CAST(SUBSTRING(@individual, 1, 2) AS BINARY(8));

               SET @only_query_hashes = SUBSTRING(@only_query_hashes, LEN(@individual + ',') + 1, LEN(@only_query_hashes)) ;
        END
        ELSE
        BEGIN
               SET @individual = @only_query_hashes
               SET @only_query_hashes = NULL

               INSERT INTO #only_query_hashes
               select cast('' as xml).value('xs:hexBinary( substring(sql:variable("@individual"), sql:column("t.pos")) )', 'varbinary(max)')
               from (select case substring(@individual, 1, 2) when '0x' then 3 else 0 end) as t(pos)

               --SELECT CAST(SUBSTRING(@individual, 1, 2) AS VARBINARY(MAX)) ;
        END
   END
END

/* If the user is setting up a list of query hashes to ignore, those
   values will be inserted into #ignore_query_hashes. This is used to
   exclude values from query results.

   Stored procedures and triggers will still be queried.
 */
IF @ignore_query_hashes IS NOT NULL
   AND LEN(@ignore_query_hashes) > 0
BEGIN
   SET @individual = '' ;

   WHILE LEN(@ignore_query_hashes) > 0
   BEGIN
        IF PATINDEX('%,%', @ignore_query_hashes) > 0
        BEGIN  
               SET @individual = SUBSTRING(@ignore_query_hashes, 0, PATINDEX('%,%',@ignore_query_hashes)) ;
               
               INSERT INTO #ignore_query_hashes
               SELECT CAST('' AS XML).value('xs:hexBinary( substring(sql:variable("@individual"), sql:column("t.pos")) )', 'varbinary(max)')
               FROM (SELECT CASE SUBSTRING(@individual, 1, 2) WHEN '0x' THEN 3 ELSE 0 END) AS t(pos) ;
               
               SET @ignore_query_hashes = SUBSTRING(@ignore_query_hashes, LEN(@individual + ',') + 1, LEN(@ignore_query_hashes)) ;
        END
        ELSE
        BEGIN
               SET @individual = @ignore_query_hashes ;
               SET @ignore_query_hashes = NULL ;

               INSERT INTO #ignore_query_hashes
               SELECT CAST('' AS XML).value('xs:hexBinary( substring(sql:variable("@individual"), sql:column("t.pos")) )', 'varbinary(max)')
               FROM (SELECT CASE SUBSTRING(@individual, 1, 2) WHEN '0x' THEN 3 ELSE 0 END) AS t(pos) ;
        END
   END
END

IF @configuration_database_name IS NOT NULL
BEGIN
   DECLARE @config_sql NVARCHAR(MAX) = N'INSERT INTO #configuration SELECT parameter_name, value FROM '
        + QUOTENAME(@configuration_database_name)
        + '.' + QUOTENAME(@configuration_schema_name)
        + '.' + QUOTENAME(@configuration_table_name)
        + ' ; ' ;
   EXEC(@config_sql);
END

DECLARE @sql nvarchar(MAX) = N'',
        @insert_list nvarchar(MAX) = N'',
        @plans_triggers_select_list nvarchar(MAX) = N'',
        @body nvarchar(MAX) = N'',
        @body_where nvarchar(MAX) = N'',
        @body_order nvarchar(MAX) = N'ORDER BY #sortable# DESC OPTION (RECOMPILE) ',
        
        @q nvarchar(1) = N'''',
        @pv varchar(20),
        @pos tinyint,
        @v decimal(6,2),
        @build int;


RAISERROR (N'Determining SQL Server version.',0,1) WITH NOWAIT;

INSERT INTO #checkversion (version)
SELECT CAST(SERVERPROPERTY('ProductVersion') as nvarchar(128))
OPTION (RECOMPILE);


SELECT @v = maj_version ,
       @build = build
FROM   #checkversion
OPTION (RECOMPILE);

RAISERROR (N'Creating dynamic SQL based on SQL Server version.',0,1) WITH NOWAIT;

SET @insert_list += N'
INSERT INTO ##bou_BlitzCacheProcs (SPID, QueryType, DatabaseName, AverageCPU, TotalCPU, AverageCPUPerMinute, PercentCPUByType, PercentDurationByType,
                    PercentReadsByType, PercentExecutionsByType, AverageDuration, TotalDuration, AverageReads, TotalReads, ExecutionCount,
                    ExecutionsPerMinute, TotalWrites, AverageWrites, PercentWritesByType, WritesPerMinute, PlanCreationTime,
                    LastExecutionTime, StatementStartOffset, StatementEndOffset, MinReturnedRows, MaxReturnedRows, AverageReturnedRows, TotalReturnedRows,
                    LastReturnedRows, QueryText, QueryPlan, TotalWorkerTimeForType, TotalElapsedTimeForType, TotalReadsForType,
                    TotalExecutionCountForType, TotalWritesForType, SqlHandle, PlanHandle, QueryHash, QueryPlanHash,
                    min_worker_time, max_worker_time, is_parallel, min_elapsed_time, max_elapsed_time, age_minutes, age_minutes_lifetime) ' ;

SET @body += N'
FROM   (SELECT *,
               CAST((CASE WHEN DATEDIFF(mi, cached_time, GETDATE()) > 0 AND execution_count > 1
                          THEN DATEDIFF(mi, cached_time, GETDATE()) 
                          ELSE NULL END) as MONEY) as age_minutes,
               CAST((CASE WHEN DATEDIFF(mi, cached_time, last_execution_time) > 0 AND execution_count > 1
                          THEN DATEDIFF(mi, cached_time, last_execution_time) 
                          ELSE Null END) as MONEY) as age_minutes_lifetime
        FROM   sys.#view# x ' + @nl ;

IF (SELECT COUNT(*) FROM #only_query_hashes) > 0
   AND (SELECT COUNT(*) FROM #ignore_query_hashes) = 0
BEGIN
    SET @body += N'        WHERE  EXISTS(SELECT 1/0 FROM #only_query_hashes q WHERE q.query_hash = x.query_hash) ' + @nl
END

                          
SET @body += N') AS qs
       CROSS JOIN(SELECT SUM(execution_count) AS t_TotalExecs,
                         SUM(total_elapsed_time) / 1000.0 AS t_TotalElapsed,
                         SUM(total_worker_time) / 1000.0 AS t_TotalWorker,
                         SUM(total_logical_reads) AS t_TotalReads,
                         SUM(total_logical_writes) AS t_TotalWrites
                  FROM   sys.#view#) AS t
       CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) AS pa
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
       CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp ' + @nl ;

SET @body_where = N'WHERE  pa.attribute = ' + QUOTENAME('dbid', @q) + @nl ;

IF @duration_filter IS NOT NULL
   SET @body_where += N'       AND (total_elapsed_time / 1000.0) / execution_count > @min_duration ' + @nl ;

SET @plans_triggers_select_list += N'
SELECT TOP (@top)
       @@SPID ,
       ''Procedure: '' + COALESCE(OBJECT_NAME(qs.object_id, qs.database_id),'''') AS QueryType,
       COALESCE(DB_NAME(database_id), CAST(pa.value AS sysname), ''-- N/A --'') AS DatabaseName,
       (total_worker_time / 1000.0) / execution_count AS AvgCPU ,
       (total_worker_time / 1000.0) AS TotalCPU ,
       CASE WHEN total_worker_time = 0 THEN 0
            WHEN COALESCE(age_minutes, DATEDIFF(mi, qs.cached_time, qs.last_execution_time), 0) = 0 THEN 0
            ELSE CAST((total_worker_time / 1000.0) / COALESCE(age_minutes, DATEDIFF(mi, qs.cached_time, qs.last_execution_time)) AS MONEY)
            END AS AverageCPUPerMinute ,
       CASE WHEN t.t_TotalWorker = 0 THEN 0
            ELSE CAST(ROUND(100.00 * (total_worker_time / 1000.0) / t.t_TotalWorker, 2) AS MONEY)
            END AS PercentCPUByType,
       CASE WHEN t.t_TotalElapsed = 0 THEN 0
            ELSE CAST(ROUND(100.00 * (total_elapsed_time / 1000.0) / t.t_TotalElapsed, 2) AS MONEY)
            END AS PercentDurationByType,
       CASE WHEN t.t_TotalReads = 0 THEN 0
            ELSE CAST(ROUND(100.00 * total_logical_reads / t.t_TotalReads, 2) AS MONEY)
            END AS PercentReadsByType,
       CASE WHEN t.t_TotalExecs = 0 THEN 0
            ELSE CAST(ROUND(100.00 * execution_count / t.t_TotalExecs, 2) AS MONEY)
            END AS PercentExecutionsByType,
       (total_elapsed_time / 1000.0) / execution_count AS AvgDuration ,
       (total_elapsed_time / 1000.0) AS TotalDuration ,
       total_logical_reads / execution_count AS AvgReads ,
       total_logical_reads AS TotalReads ,
       execution_count AS ExecutionCount ,
       CASE WHEN execution_count = 0 THEN 0
            WHEN COALESCE(age_minutes, DATEDIFF(mi, qs.cached_time, qs.last_execution_time), 0) = 0 THEN 0
            ELSE CAST((1.00 * execution_count / COALESCE(age_minutes, DATEDIFF(mi, qs.cached_time, qs.last_execution_time))) AS money)
            END AS ExecutionsPerMinute ,
       total_logical_writes AS TotalWrites ,
       total_logical_writes / execution_count AS AverageWrites ,
       CASE WHEN t.t_TotalWrites = 0 THEN 0
            ELSE CAST(ROUND(100.00 * total_logical_writes / t.t_TotalWrites, 2) AS MONEY)
            END AS PercentWritesByType,
       CASE WHEN total_logical_writes = 0 THEN 0
            WHEN COALESCE(age_minutes, DATEDIFF(mi, qs.cached_time, qs.last_execution_time), 0) = 0 THEN 0
            ELSE CAST((1.00 * total_logical_writes / COALESCE(age_minutes, DATEDIFF(mi, qs.cached_time, qs.last_execution_time), 0)) AS money)
            END AS WritesPerMinute,
       qs.cached_time AS PlanCreationTime,
       qs.last_execution_time AS LastExecutionTime,
       NULL AS StatementStartOffset,
       NULL AS StatementEndOffset,
       NULL AS MinReturnedRows,
       NULL AS MaxReturnedRows,
       NULL AS AvgReturnedRows,
       NULL AS TotalReturnedRows,
       NULL AS LastReturnedRows,
       st.text AS QueryText ,
       query_plan AS QueryPlan,
       t.t_TotalWorker,
       t.t_TotalElapsed,
       t.t_TotalReads,
       t.t_TotalExecs,
       t.t_TotalWrites,
       qs.sql_handle AS SqlHandle,
       qs.plan_handle AS PlanHandle,
       NULL AS QueryHash,
       NULL AS QueryPlanHash,
       qs.min_worker_time / 1000.0,
       qs.max_worker_time / 1000.0,
       CASE WHEN qp.query_plan.value(''declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";max(//p:RelOp/@Parallel)'', ''float'')  > 0 THEN 1 ELSE 0 END,
       qs.min_elapsed_time / 1000.0,
       qs.max_elapsed_time / 1000.0,
       age_minutes, 
       age_minutes_lifetime '


IF LEFT(@query_filter, 3) IN ('all', 'sta')
BEGIN
    SET @sql += @insert_list;
    
    SET @sql += N'
    SELECT TOP (@top)
           @@SPID ,
           ''Statement'' AS QueryType,
           COALESCE(DB_NAME(CAST(pa.value AS INT)), ''-- N/A --'') AS DatabaseName,
           (total_worker_time / 1000.0) / execution_count AS AvgCPU ,
           (total_worker_time / 1000.0) AS TotalCPU ,
           CASE WHEN total_worker_time = 0 THEN 0
                WHEN COALESCE(age_minutes, DATEDIFF(mi, qs.creation_time, qs.last_execution_time), 0) = 0 THEN 0
                ELSE CAST((total_worker_time / 1000.0) / COALESCE(age_minutes, DATEDIFF(mi, qs.creation_time, qs.last_execution_time)) AS MONEY)
                END AS AverageCPUPerMinute ,
           CAST(ROUND(100.00 * (total_worker_time / 1000.0) / t.t_TotalWorker, 2) AS MONEY) AS PercentCPUByType,
           CAST(ROUND(100.00 * (total_elapsed_time / 1000.0) / t.t_TotalElapsed, 2) AS MONEY) AS PercentDurationByType,
           CAST(ROUND(100.00 * total_logical_reads / t.t_TotalReads, 2) AS MONEY) AS PercentReadsByType,
           CAST(ROUND(100.00 * execution_count / t.t_TotalExecs, 2) AS MONEY) AS PercentExecutionsByType,
           (total_elapsed_time / 1000.0) / execution_count AS AvgDuration ,
           (total_elapsed_time / 1000.0) AS TotalDuration ,
           total_logical_reads / execution_count AS AvgReads ,
           total_logical_reads AS TotalReads ,
           execution_count AS ExecutionCount ,
           CASE WHEN execution_count = 0 THEN 0
                WHEN COALESCE(age_minutes, DATEDIFF(mi, qs.creation_time, qs.last_execution_time), 0) = 0 THEN 0
                ELSE CAST((1.00 * execution_count / COALESCE(age_minutes, DATEDIFF(mi, qs.creation_time, qs.last_execution_time))) AS money)
                END AS ExecutionsPerMinute ,
           total_logical_writes AS TotalWrites ,
           total_logical_writes / execution_count AS AverageWrites ,
           CASE WHEN t.t_TotalWrites = 0 THEN 0
                ELSE CAST(ROUND(100.00 * total_logical_writes / t.t_TotalWrites, 2) AS MONEY)
                END AS PercentWritesByType,
           CASE WHEN total_logical_writes = 0 THEN 0
                WHEN COALESCE(age_minutes, DATEDIFF(mi, qs.creation_time, qs.last_execution_time), 0) = 0 THEN 0
                ELSE CAST((1.00 * total_logical_writes / COALESCE(age_minutes, DATEDIFF(mi, qs.creation_time, qs.last_execution_time), 0)) AS money)
                END AS WritesPerMinute,
           qs.creation_time AS PlanCreationTime,
           qs.last_execution_time AS LastExecutionTime,
           qs.statement_start_offset AS StatementStartOffset,
           qs.statement_end_offset AS StatementEndOffset, '
    
    IF (@v >= 11) OR (@v >= 10.5 AND @build >= 2500)
    BEGIN
        SET @sql += N'
           qs.min_rows AS MinReturnedRows,
           qs.max_rows AS MaxReturnedRows,
           CAST(qs.total_rows as MONEY) / execution_count AS AvgReturnedRows,
           qs.total_rows AS TotalReturnedRows,
           qs.last_rows AS LastReturnedRows, ' ;
    END
    ELSE
    BEGIN
        SET @sql += N'
           NULL AS MinReturnedRows,
           NULL AS MaxReturnedRows,
           NULL AS AvgReturnedRows,
           NULL AS TotalReturnedRows,
           NULL AS LastReturnedRows, ' ;
    END
    
    SET @sql += N'
           SUBSTRING(st.text, ( qs.statement_start_offset / 2 ) + 1, ( ( CASE qs.statement_end_offset
                                                                            WHEN -1 THEN DATALENGTH(st.text)
                                                                            ELSE qs.statement_end_offset
                                                                          END - qs.statement_start_offset ) / 2 ) + 1) AS QueryText ,
           query_plan AS QueryPlan,
           t.t_TotalWorker,
           t.t_TotalElapsed,
           t.t_TotalReads,
           t.t_TotalExecs,
           t.t_TotalWrites,
           qs.sql_handle AS SqlHandle,
           NULL AS PlanHandle,
           qs.query_hash AS QueryHash,
           qs.query_plan_hash AS QueryPlanHash,
           qs.min_worker_time / 1000.0,
           qs.max_worker_time / 1000.0,
           CASE WHEN qp.query_plan.value(''declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";max(//p:RelOp/@Parallel)'', ''float'')  > 0 THEN 1 ELSE 0 END,
           qs.min_elapsed_time / 1000.0,
           qs.max_worker_time  / 1000.0,
           age_minutes,
           age_minutes_lifetime '
    
    SET @sql += REPLACE(REPLACE(@body, '#view#', 'dm_exec_query_stats'), 'cached_time', 'creation_time') ;
    
    IF (SELECT COUNT(*) FROM #ignore_query_hashes) > 0
       AND (SELECT COUNT(*) FROM #only_query_hashes) = 0
    BEGIN
        SET @sql += REPLACE(@sql, ') AS qs', ') AS qs
        LEFT JOIN #ignore_query_hashes iqh ON iqh.query_hash = qs.query_hash ' + @nl) ;
    END
    
    
    
    
    SET @sql += @body_where ;
    
    IF @ignore_system_db = 1
        SET @sql += 'AND COALESCE(DB_NAME(CAST(pa.value AS INT)), '''') NOT IN (''master'', ''model'', ''msdb'', ''tempdb'', ''32767'') ' + @nl ;
    
    IF (SELECT COUNT(*) FROM #ignore_query_hashes) > 0
       AND (SELECT COUNT(*) FROM #only_query_hashes) = 0
    BEGIN
        SET @sql += ' AND iqh.query_hash IS NULL ' + @nl ;
    END
    
    SET @sql += @body_order + @nl + @nl + @nl;
END


IF (@query_filter = 'all' AND (SELECT COUNT(*) FROM #only_query_hashes) = 0)
   OR (LEFT(@query_filter, 3) = 'pro')
BEGIN
    SET @sql += @insert_list;
    SET @sql += REPLACE(@plans_triggers_select_list, '#query_type#', 'Stored Procedure') ;

    SET @sql += REPLACE(@body, '#view#', 'dm_exec_procedure_stats') ; 
    SET @sql += @body_where ;

    IF @ignore_system_db = 1
       SET @sql += ' AND COALESCE(DB_NAME(database_id), CAST(pa.value AS sysname), '''') NOT IN (''master'', ''model'', ''msdb'', ''tempdb'', ''32767'') ' + @nl ;

    SET @sql += @body_order + @nl + @nl + @nl ;
END



/*******************************************************************************
 *
 * Because the trigger execution count in SQL Server 2008R2 and earlier is not
 * correct, we ignore triggers for these versions of SQL Server. If you'd like
 * to include trigger numbers, just know that the ExecutionCount,
 * PercentExecutions, and ExecutionsPerMinute are wildly inaccurate for
 * triggers on these versions of SQL Server.
 *
 * This is why we can't have nice things.
 *
 ******************************************************************************/
IF (@use_triggers_anyway = 1 OR @v >= 11)
   AND (SELECT COUNT(*) FROM #only_query_hashes) = 0
   AND (@query_filter = 'all')
BEGIN
   RAISERROR (N'Adding SQL to collect trigger stats.',0,1) WITH NOWAIT;

   /* Trigger level information from the plan cache */
   SET @sql += @insert_list ;

   SET @sql += REPLACE(@plans_triggers_select_list, '#query_type#', 'Trigger') ;

   SET @sql += REPLACE(@body, '#view#', 'dm_exec_trigger_stats') ;

   SET @sql += @body_where ;

   IF @ignore_system_db = 1
      SET @sql += ' AND COALESCE(DB_NAME(database_id), CAST(pa.value AS sysname), '''') NOT IN (''master'', ''model'', ''msdb'', ''tempdb'', ''32767'') ' + @nl ;
   
   SET @sql += @body_order + @nl + @nl + @nl ;
END




DECLARE @sort NVARCHAR(MAX);

SELECT @sort = CASE @sort_order WHEN 'cpu' THEN 'total_worker_time'
                                WHEN 'reads' THEN 'total_logical_reads'
                                WHEN 'writes' THEN 'total_logical_writes'
                                WHEN 'duration' THEN 'total_elapsed_time'
                                WHEN 'executions' THEN 'execution_count'
                                /* And now the averages */
                                WHEN 'avg cpu' THEN 'total_worker_time / execution_count'
                                WHEN 'avg reads' THEN 'total_logical_reads / execution_count'
                                WHEN 'avg writes' THEN 'total_logical_writes / execution_count'
                                WHEN 'avg duration' THEN 'total_elapsed_time / execution_count'
                                WHEN 'avg executions' THEN 'CASE WHEN execution_count = 0 THEN 0
            WHEN COALESCE(age_minutes, age_minutes_lifetime, 0) = 0 THEN 0
            ELSE CAST((1.00 * execution_count / COALESCE(age_minutes, age_minutes_lifetime)) AS money)
            END'
               END ;

SELECT @sql = REPLACE(@sql, '#sortable#', @sort);

SET @sql += N'
INSERT INTO #p (SqlHandle, TotalCPU, TotalReads, TotalDuration, TotalWrites, ExecutionCount)
SELECT  SqlHandle,
        TotalCPU,
        TotalReads,
        TotalDuration,
        TotalWrites,
        ExecutionCount
FROM    (SELECT  SqlHandle,
                 TotalCPU,
                 TotalReads,
                 TotalDuration,
                 TotalWrites,
                 ExecutionCount,
                 ROW_NUMBER() OVER (PARTITION BY SqlHandle ORDER BY #sortable# DESC) AS rn
         FROM    ##bou_BlitzCacheProcs) AS x
WHERE x.rn = 1
OPTION (RECOMPILE);
';

SELECT @sort = CASE @sort_order WHEN 'cpu' THEN 'TotalCPU'
                                WHEN 'reads' THEN 'TotalReads'
                                WHEN 'writes' THEN 'TotalWrites'
                                WHEN 'duration' THEN 'TotalDuration'
                                WHEN 'executions' THEN 'ExecutionCount'
                                WHEN 'avg cpu' THEN 'TotalCPU / ExecutionCount'
                                WHEN 'avg reads' THEN 'TotalReads / ExecutionCount'
                                WHEN 'avg writes' THEN 'TotalWrites / ExecutionCount'
                                WHEN 'avg duration' THEN 'TotalDuration / ExecutionCount'
                                WHEN 'avg executions' THEN 'CASE WHEN ExecutionCount = 0 THEN 0
            WHEN COALESCE(age_minutes, age_minutes_lifetime, 0) = 0 THEN 0
            ELSE CAST((1.00 * ExecutionCount / COALESCE(age_minutes, age_minutes_lifetime)) AS money)
            END'
               END ;

SELECT @sql = REPLACE(@sql, '#sortable#', @sort);


IF @reanalyze = 0
BEGIN
    RAISERROR('Collecting execution plan information.', 0, 1) WITH NOWAIT;

    EXEC sp_executesql @sql, N'@top INT, @min_duration INT', @top, @duration_filter_i;
END



/* Compute the total CPU, etc across our active set of the plan cache.
 * Yes, there's a flaw - this doesn't include anything outside of our @top
 * metric.
 */
RAISERROR('Computing CPU, duration, read, and write metrics', 0, 1) WITH NOWAIT;
DECLARE @total_duration BIGINT,
        @total_cpu BIGINT,
        @total_reads BIGINT,
        @total_writes BIGINT,
        @total_execution_count BIGINT;

SELECT  @total_cpu = SUM(TotalCPU),
        @total_duration = SUM(TotalDuration),
        @total_reads = SUM(TotalReads),
        @total_writes = SUM(TotalWrites),
        @total_execution_count = SUM(ExecutionCount)
FROM    #p
OPTION (RECOMPILE) ;

DECLARE @cr NVARCHAR(1) = NCHAR(13);
DECLARE @lf NVARCHAR(1) = NCHAR(10);
DECLARE @tab NVARCHAR(1) = NCHAR(9);

/* Update CPU percentage for stored procedures */
UPDATE ##bou_BlitzCacheProcs
SET     PercentCPU = y.PercentCPU,
        PercentDuration = y.PercentDuration,
        PercentReads = y.PercentReads,
        PercentWrites = y.PercentWrites,
        PercentExecutions = y.PercentExecutions,
        ExecutionsPerMinute = y.ExecutionsPerMinute,
        /* Strip newlines and tabs. Tabs are replaced with multiple spaces
           so that the later whitespace trim will completely eliminate them
         */
        QueryText = REPLACE(REPLACE(REPLACE(QueryText, @cr, ' '), @lf, ' '), @tab, '  ')
FROM (
    SELECT  PlanHandle,
            CASE @total_cpu WHEN 0 THEN 0
                 ELSE CAST((100. * TotalCPU) / @total_cpu AS MONEY) END AS PercentCPU,
            CASE @total_duration WHEN 0 THEN 0
                 ELSE CAST((100. * TotalDuration) / @total_duration AS MONEY) END AS PercentDuration,
            CASE @total_reads WHEN 0 THEN 0
                 ELSE CAST((100. * TotalReads) / @total_reads AS MONEY) END AS PercentReads,
            CASE @total_writes WHEN 0 THEN 0
                 ELSE CAST((100. * TotalWrites) / @total_writes AS MONEY) END AS PercentWrites,
            CASE @total_execution_count WHEN 0 THEN 0
                 ELSE CAST((100. * ExecutionCount) / @total_execution_count AS MONEY) END AS PercentExecutions,
            CASE DATEDIFF(mi, PlanCreationTime, LastExecutionTime)
                WHEN 0 THEN 0
                ELSE CAST((1.00 * ExecutionCount / DATEDIFF(mi, PlanCreationTime, LastExecutionTime)) AS money)
            END AS ExecutionsPerMinute
    FROM (
        SELECT  PlanHandle,
                TotalCPU,
                TotalDuration,
                TotalReads,
                TotalWrites,
                ExecutionCount,
                PlanCreationTime,
                LastExecutionTime
        FROM    ##bou_BlitzCacheProcs
        WHERE   PlanHandle IS NOT NULL
        GROUP BY PlanHandle,
                TotalCPU,
                TotalDuration,
                TotalReads,
                TotalWrites,
                ExecutionCount,
                PlanCreationTime,
                LastExecutionTime
    ) AS x
) AS y
WHERE ##bou_BlitzCacheProcs.PlanHandle = y.PlanHandle
      AND ##bou_BlitzCacheProcs.PlanHandle IS NOT NULL
OPTION (RECOMPILE) ;



UPDATE ##bou_BlitzCacheProcs
SET     PercentCPU = y.PercentCPU,
        PercentDuration = y.PercentDuration,
        PercentReads = y.PercentReads,
        PercentWrites = y.PercentWrites,
        PercentExecutions = y.PercentExecutions,
        ExecutionsPerMinute = y.ExecutionsPerMinute,
        /* Strip newlines and tabs. Tabs are replaced with multiple spaces
           so that the later whitespace trim will completely eliminate them
         */
        QueryText = REPLACE(REPLACE(REPLACE(QueryText, @cr, ' '), @lf, ' '), @tab, '  ')
FROM (
    SELECT  DatabaseName,
            SqlHandle,
            QueryHash,
            CASE @total_cpu WHEN 0 THEN 0
                 ELSE CAST((100. * TotalCPU) / @total_cpu AS MONEY) END AS PercentCPU,
            CASE @total_duration WHEN 0 THEN 0
                 ELSE CAST((100. * TotalDuration) / @total_duration AS MONEY) END AS PercentDuration,
            CASE @total_reads WHEN 0 THEN 0
                 ELSE CAST((100. * TotalReads) / @total_reads AS MONEY) END AS PercentReads,
            CASE @total_writes WHEN 0 THEN 0
                 ELSE CAST((100. * TotalWrites) / @total_writes AS MONEY) END AS PercentWrites,
            CASE @total_execution_count WHEN 0 THEN 0
                 ELSE CAST((100. * ExecutionCount) / @total_execution_count AS MONEY) END AS PercentExecutions,
            CASE  DATEDIFF(mi, PlanCreationTime, LastExecutionTime)
                WHEN 0 THEN 0
                ELSE CAST((1.00 * ExecutionCount / DATEDIFF(mi, PlanCreationTime, LastExecutionTime)) AS money)
            END AS ExecutionsPerMinute
    FROM (
        SELECT  DatabaseName,
                SqlHandle,
                QueryHash,
                TotalCPU,
                TotalDuration,
                TotalReads,
                TotalWrites,
                ExecutionCount,
                PlanCreationTime,
                LastExecutionTime
        FROM    ##bou_BlitzCacheProcs
        GROUP BY DatabaseName,
                SqlHandle,
                QueryHash,
                TotalCPU,
                TotalDuration,
                TotalReads,
                TotalWrites,
                ExecutionCount,
                PlanCreationTime,
                LastExecutionTime
    ) AS x
) AS y
WHERE   ##bou_BlitzCacheProcs.SqlHandle = y.SqlHandle
        AND ##bou_BlitzCacheProcs.QueryHash = y.QueryHash
        AND ##bou_BlitzCacheProcs.DatabaseName = y.DatabaseName
        AND ##bou_BlitzCacheProcs.PlanHandle IS NULL
OPTION (RECOMPILE) ;



WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
UPDATE ##bou_BlitzCacheProcs
SET NumberOfDistinctPlans = distinct_plan_count,
    NumberOfPlans = number_of_plans,
    QueryPlanCost = CASE WHEN QueryType LIKE '%Stored Procedure%' THEN
        QueryPlan.value('sum(//p:StmtSimple/@StatementSubTreeCost)', 'float')
        ELSE
        QueryPlan.value('sum(//p:StmtSimple[xs:hexBinary(substring(@QueryPlanHash, 3)) = xs:hexBinary(sql:column("QueryPlanHash"))]/@StatementSubTreeCost)', 'float')
        END,
    missing_index_count = QueryPlan.value('count(//p:MissingIndexGroup)', 'int') ,
    unmatched_index_count = QueryPlan.value('count(//p:UnmatchedIndexes/p:Parameterization/p:Object)', 'int') ,
    plan_multiple_plans = CASE WHEN distinct_plan_count < number_of_plans THEN 1 END ,
    is_trivial = CASE WHEN QueryPlan.exist('//p:StmtSimple[@StatementOptmLevel[.="TRIVIAL"]]/p:QueryPlan/p:ParameterList') = 1 THEN 1 END
FROM (
SELECT COUNT(DISTINCT QueryHash) AS distinct_plan_count,
       COUNT(QueryHash) AS number_of_plans,
       QueryHash
FROM   ##bou_BlitzCacheProcs
GROUP BY QueryHash
) AS x
WHERE ##bou_BlitzCacheProcs.QueryHash = x.QueryHash
OPTION (RECOMPILE) ;



/* Set configuration values */
DECLARE @execution_threshold INT = 1000 ,
        @parameter_sniffing_warning_pct TINYINT = 30,
        /* This is in average reads */
        @parameter_sniffing_io_threshold BIGINT = 100000 ,
        @ctp_threshold_pct TINYINT = 10,
        @long_running_query_warning_seconds BIGINT = 300 * 1000 ;

IF EXISTS (SELECT 1/0 FROM #configuration WHERE 'frequent execution threshold' = LOWER(parameter_name))
BEGIN
    SELECT @execution_threshold = CAST(value AS INT)
    FROM   #configuration
    WHERE  'frequent execution threshold' = LOWER(parameter_name) ;

    SET @msg = ' Setting "frequent execution threshold" to ' + CAST(@execution_threshold AS VARCHAR(10)) ;

    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END

IF EXISTS (SELECT 1/0 FROM #configuration WHERE 'parameter sniffing variance percent' = LOWER(parameter_name))
BEGIN
    SELECT @parameter_sniffing_warning_pct = CAST(value AS TINYINT)
    FROM   #configuration
    WHERE  'parameter sniffing variance percent' = LOWER(parameter_name) ;

    SET @msg = ' Setting "parameter sniffing variance percent" to ' + CAST(@parameter_sniffing_warning_pct AS VARCHAR(3)) ;

    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END

IF EXISTS (SELECT 1/0 FROM #configuration WHERE 'parameter sniffing io threshold' = LOWER(parameter_name))
BEGIN
    SELECT @parameter_sniffing_io_threshold = CAST(value AS BIGINT)
    FROM   #configuration
    WHERE 'parameter sniffing io threshold' = LOWER(parameter_name) ;

    SET @msg = ' Setting "parameter sniffing io threshold" to ' + CAST(@parameter_sniffing_io_threshold AS VARCHAR(10));

    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END

IF EXISTS (SELECT 1/0 FROM #configuration WHERE 'cost threshold for parallelism warning' = LOWER(parameter_name))
BEGIN
    SELECT @ctp_threshold_pct = CAST(value AS TINYINT)
    FROM   #configuration
    WHERE 'cost threshold for parallelism warning' = LOWER(parameter_name) ;

    SET @msg = ' Setting "cost threshold for parallelism warning" to ' + CAST(@ctp_threshold_pct AS VARCHAR(3));

    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END

IF EXISTS (SELECT 1/0 FROM #configuration WHERE 'long running query warning (seconds)' = LOWER(parameter_name))
BEGIN
    SELECT @long_running_query_warning_seconds = CAST(value * 1000 AS BIGINT)
    FROM   #configuration
    WHERE 'long running query warning (seconds)' = LOWER(parameter_name) ;

    SET @msg = ' Setting "long running query warning (seconds)" to ' + CAST(@long_running_query_warning_seconds AS VARCHAR(10));

    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END

DECLARE @ctp INT ;

SELECT  @ctp = CAST(value AS INT)
FROM    sys.configurations
WHERE   name = 'cost threshold for parallelism'
OPTION (RECOMPILE);



/* Update to populate checks columns */
RAISERROR('Checking for query level SQL Server issues.', 0, 1) WITH NOWAIT;

WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
UPDATE ##bou_BlitzCacheProcs
SET    frequent_execution = CASE WHEN ExecutionsPerMinute > @execution_threshold THEN 1 END ,
       parameter_sniffing = CASE WHEN AverageReads > @parameter_sniffing_io_threshold
                                      AND min_worker_time < ((1.0 - (@parameter_sniffing_warning_pct / 100.0)) * AverageCPU) THEN 1
                                 WHEN AverageReads > @parameter_sniffing_io_threshold
                                      AND max_worker_time > ((1.0 + (@parameter_sniffing_warning_pct / 100.0)) * AverageCPU) THEN 1
                                 WHEN AverageReads > @parameter_sniffing_io_threshold
                                      AND MinReturnedRows < ((1.0 - (@parameter_sniffing_warning_pct / 100.0)) * AverageReturnedRows) THEN 1
                                 WHEN AverageReads > @parameter_sniffing_io_threshold
                                      AND MaxReturnedRows > ((1.0 + (@parameter_sniffing_warning_pct / 100.0)) * AverageReturnedRows) THEN 1 END ,
       near_parallel = CASE WHEN QueryPlanCost BETWEEN @ctp * (1 - (@ctp_threshold_pct / 100.0)) AND @ctp THEN 1 END,
       plan_warnings = CASE WHEN QueryPlan.value('count(//p:Warnings)', 'int') > 0 THEN 1 END,
       long_running = CASE WHEN AverageDuration > @long_running_query_warning_seconds THEN 1
                           WHEN max_worker_time > @long_running_query_warning_seconds THEN 1
                           WHEN max_elapsed_time > @long_running_query_warning_seconds THEN 1 END ,
       implicit_conversions = CASE WHEN QueryPlan.exist('
                                        //p:PlanAffectingConvert/@Expression
                                        [contains(., "CONVERT_IMPLICIT")]') = 1 THEN 1
                                   END ,
       tempdb_spill = CASE WHEN QueryPlan.value('max(//p:SpillToTempDb/@SpillLevel)', 'int') > 0 THEN 1 END ,
       unparameterized_query = CASE WHEN QueryPlan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList') = 1 AND
                                         QueryPlan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList/p:ColumnReference') = 0 THEN 1
                                    WHEN QueryPlan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/p:QueryPlan/p:ParameterList') = 0 AND
                                         QueryPlan.exist('//p:StmtSimple[@StatementOptmLevel[.="FULL"]]/*/p:RelOp/descendant::p:ScalarOperator/p:Identifier/p:ColumnReference[contains(@Column, "@")]')
                                         = 1 THEN 1 END ;



/* Checks that require examining individual plan nodes, as opposed to
   the entire plan
 */
RAISERROR('Scanning individual plan nodes for query issues.', 0, 1) WITH NOWAIT;

WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
UPDATE p
SET    busy_loops = CASE WHEN (x.estimated_executions / 100.0) > x.estimated_rows THEN 1 END ,
       tvf_join = CASE WHEN x.tvf_join = 1 THEN 1 END ,
       warning_no_join_predicate = CASE WHEN x.no_join_warning = 1 THEN 1 END
FROM   ##bou_BlitzCacheProcs p
       JOIN (
            SELECT qs.SqlHandle,
                   n.value('@EstimateRows', 'float') AS estimated_rows ,
                   n.value('@EstimateRewinds', 'float') + n.value('@EstimateRebinds', 'float') + 1.0 AS estimated_executions ,
                   n.query('.').exist('/p:RelOp[contains(@LogicalOp, "Join")]/*/p:RelOp[(@LogicalOp[.="Table-valued function"])]') AS tvf_join,
                   n.query('.').exist('//p:RelOp/p:Warnings[(@NoJoinPredicate[.="1"])]') AS no_join_warning
            FROM   ##bou_BlitzCacheProcs qs
                   OUTER APPLY qs.QueryPlan.nodes('//p:RelOp') AS q(n)
       ) AS x ON p.SqlHandle = x.SqlHandle ;



/* Check for timeout plan termination */
RAISERROR('Checking for plan compilation timeouts.', 0, 1) WITH NOWAIT;

WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
UPDATE p
SET    compile_timeout = CASE WHEN n.query('.').exist('/p:StmtSimple/@StatementOptmEarlyAbortReason[.="TimeOut"]') = 1 THEN 1 END ,
       compile_memory_limit_exceeded = CASE WHEN n.query('.').exist('/p:StmtSimple/@StatementOptmEarlyAbortReason[.="MemoryLimitExceeded"]') = 1 THEN 1 END
FROM   ##bou_BlitzCacheProcs p
       CROSS APPLY p.QueryPlan.nodes('//p:StmtSimple') AS q(n) ;



RAISERROR('Checking for forced parameterization and cursors.', 0, 1) WITH NOWAIT;

/* Set options checks */
UPDATE p
SET    is_forced_parameterized = CASE WHEN (CAST(pa.value AS INT) & 131072 = 131072) THEN 1
                                      END ,
       is_forced_plan = CASE WHEN (CAST(pa.value AS INT) & 131072 = 131072) THEN 1
                             WHEN (CAST(pa.value AS INT) & 4 = 4) THEN 1 
                             END ,
       SetOptions = SUBSTRING(
                    CASE WHEN (CAST(pa.value AS INT) & 1 = 1) THEN ', ANSI_PADDING' ELSE '' END +
                    CASE WHEN (CAST(pa.value AS INT) & 8 = 8) THEN ', CONCAT_NULL_YIELDS_NULL' ELSE '' END +
                    CASE WHEN (CAST(pa.value AS INT) & 16 = 16) THEN ', ANSI_WARNINGS' ELSE '' END +
                    CASE WHEN (CAST(pa.value AS INT) & 32 = 32) THEN ', ANSI_NULLS' ELSE '' END +
                    CASE WHEN (CAST(pa.value AS INT) & 64 = 64) THEN ', QUOTED_IDENTIFIER' ELSE '' END +
                    CASE WHEN (CAST(pa.value AS INT) & 4096 = 4096) THEN ', ARITH_ABORT' ELSE '' END +
                    CASE WHEN (CAST(pa.value AS INT) & 8192 = 8191) THEN ', NUMERIC_ROUNDABORT' ELSE '' END 
                    , 2, 200000)
FROM   ##bou_BlitzCacheProcs p
       CROSS APPLY sys.dm_exec_plan_attributes(p.PlanHandle) pa
WHERE  pa.attribute = 'set_options' ;



/* Cursor checks */
UPDATE p
SET    is_cursor = CASE WHEN CAST(pa.value AS INT) <> 0 THEN 1 END
FROM   ##bou_BlitzCacheProcs p
       CROSS APPLY sys.dm_exec_plan_attributes(p.PlanHandle) pa
WHERE  pa.attribute LIKE '%cursor%' ;



/* Downlevel cardinality estimator */
IF @v >= 12
BEGIN
    RAISERROR('Checking for downlevel cardinality estimators being used on SQL Server 2014.', 0, 1) WITH NOWAIT;

    WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
    UPDATE ##bou_BlitzCacheProcs
    SET    downlevel_estimator = CASE WHEN QueryPlan.value('min(//p:StmtSimple/@CardinalityEstimationModelVersion)', 'int') < (@v * 10) THEN 1 END ;
END



RAISERROR('Populating Warnings column', 0, 1) WITH NOWAIT;

/* Populate warnings */
UPDATE ##bou_BlitzCacheProcs
SET    Warnings = SUBSTRING(
                  CASE WHEN warning_no_join_predicate = 1 THEN ', No Join Predicate' ELSE '' END +
                  CASE WHEN compile_timeout = 1 THEN ', Compilation Timeout' ELSE '' END +
                  CASE WHEN compile_memory_limit_exceeded = 1 THEN ', Compile Memory Limit Exceeded' ELSE '' END +
                  CASE WHEN busy_loops = 1 THEN ', Busy Loops' ELSE '' END +
                  CASE WHEN is_forced_plan = 1 THEN ', Forced Plan' ELSE '' END +
                  CASE WHEN is_forced_parameterized = 1 THEN ', Forced Parameterization' ELSE '' END +
                  CASE WHEN unparameterized_query = 1 THEN ', Unparameterized Query' ELSE '' END +
                  CASE WHEN missing_index_count > 0 THEN ', Missing Indexes (' + CAST(missing_index_count AS VARCHAR(3)) + ')' ELSE '' END +
                  CASE WHEN unmatched_index_count > 0 THEN ', Unmatched Indexes (' + CAST(unmatched_index_count AS VARCHAR(3)) + ')' ELSE '' END +                  
                  CASE WHEN is_cursor = 1 THEN ', Cursor' ELSE '' END +
                  CASE WHEN is_parallel = 1 THEN ', Parallel' ELSE '' END +
                  CASE WHEN near_parallel = 1 THEN ', Nearly Parallel' ELSE '' END +
                  CASE WHEN frequent_execution = 1 THEN ', Frequent Execution' ELSE '' END +
                  CASE WHEN plan_warnings = 1 THEN ', Plan Warnings' ELSE '' END +
                  CASE WHEN parameter_sniffing = 1 THEN ', Parameter Sniffing' ELSE '' END +
                  CASE WHEN long_running = 1 THEN ', Long Running Query' ELSE '' END +
                  CASE WHEN downlevel_estimator = 1 THEN ', Downlevel CE' ELSE '' END +
                  CASE WHEN implicit_conversions = 1 THEN ', Implicit Conversions' ELSE '' END +
                  CASE WHEN tempdb_spill = 1 THEN ', TempDB Spills' ELSE '' END +
                  CASE WHEN tvf_join = 1 THEN ', Function Join' ELSE '' END +
                  CASE WHEN plan_multiple_plans = 1 THEN ', Multiple Plans' ELSE '' END +
                  CASE WHEN is_trivial = 1 THEN ', Trivial Plans' ELSE '' END 
                  , 2, 200000) ;












Results:
IF @output_database_name IS NOT NULL
   AND @output_schema_name IS NOT NULL
   AND @output_table_name IS NOT NULL
BEGIN
    RAISERROR('Writing results to table.', 0, 1) WITH NOWAIT;

    /* send results to a table */
    DECLARE @insert_sql NVARCHAR(MAX) = N'' ;

    SET @insert_sql = 'USE '
        + @output_database_name
        + '; IF EXISTS(SELECT * FROM '
        + @output_database_name
        + '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
        + @output_schema_name
        + ''') AND NOT EXISTS (SELECT * FROM '
        + @output_database_name
        + '.INFORMATION_SCHEMA.TABLES WHERE QUOTENAME(TABLE_SCHEMA) = '''
        + @output_schema_name + ''' AND QUOTENAME(TABLE_NAME) = '''
        + @output_table_name + ''') CREATE TABLE '
        + @output_schema_name + '.'
        + @output_table_name
        + N'(ID bigint NOT NULL IDENTITY(1,1),
          ServerName nvarchar(256),
          Version nvarchar(256),
          QueryType nvarchar(256),
          Warnings varchar(max),
          DatabaseName sysname,
          AverageCPU bigint,
          TotalCPU bigint,
          PercentCPUByType money,
          CPUWeight money,
          AverageDuration bigint,
          TotalDuration bigint,
          DurationWeight money,
          PercentDurationByType money,
          AverageReads bigint,
          TotalReads bigint,
          ReadWeight money,
          PercentReadsByType money,
          AverageWrites bigint,
          TotalWrites bigint,
          WriteWeight money,
          PercentWritesByType money,
          ExecutionCount bigint,
          ExecutionWeight money,
          PercentExecutionsByType money,' + N'
          ExecutionsPerMinute money,
          PlanCreationTime datetime,
          LastExecutionTime datetime,
          PlanHandle varbinary(64),
          SqlHandle varbinary(64),
          QueryHash binary(8),
          StatementStartOffset int,
          StatementEndOffset int,
          MinReturnedRows bigint,
          MaxReturnedRows bigint,
          AverageReturnedRows money,
          TotalReturnedRows bigint,
          QueryText nvarchar(max),
          QueryPlan xml,
          NumberOfPlans int,
          NumberOfDistinctPlans int,
          SampleTime DATETIME DEFAULT(GETDATE())
          CONSTRAINT [PK_' +CAST(NEWID() AS NCHAR(36)) + '] PRIMARY KEY CLUSTERED(ID))';

    EXEC sp_executesql @insert_sql ;

    SET @insert_sql =N' IF EXISTS(SELECT * FROM '
          + @output_database_name
          + N'.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
          + @output_schema_name + N''') '
          + 'INSERT '
          + @output_database_name + '.'
          + @output_schema_name + '.'
          + @output_table_name
          + N' (ServerName, Version, QueryType, DatabaseName, AverageCPU, TotalCPU, PercentCPUByType, CPUWeight, AverageDuration, TotalDuration, DurationWeight, PercentDurationByType, AverageReads, TotalReads, ReadWeight, PercentReadsByType, '
          + N' AverageWrites, TotalWrites, WriteWeight, PercentWritesByType, ExecutionCount, ExecutionWeight, PercentExecutionsByType, '
          + N' ExecutionsPerMinute, PlanCreationTime, LastExecutionTime, PlanHandle, SqlHandle, QueryHash, StatementStartOffset, StatementEndOffset, MinReturnedRows, MaxReturnedRows, AverageReturnedRows, TotalReturnedRows, QueryText, QueryPlan, NumberOfPlans, NumberOfDistinctPlans, Warnings) '
          + N'SELECT TOP (@top) '
          + QUOTENAME(CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)), N'''') + N', '
          + QUOTENAME(CAST(SERVERPROPERTY('ProductVersion') as nvarchar(128)), N'''') + ', '
          + N' QueryType, DatabaseName, AverageCPU, TotalCPU, PercentCPUByType, PercentCPU, AverageDuration, TotalDuration, PercentDuration, PercentDurationByType, AverageReads, TotalReads, PercentReads, PercentReadsByType, '
          + N' AverageWrites, TotalWrites, PercentWrites, PercentWritesByType, ExecutionCount, PercentExecutions, PercentExecutionsByType, '
          + N' ExecutionsPerMinute, PlanCreationTime, LastExecutionTime, PlanHandle, SqlHandle, QueryHash, StatementStartOffset, StatementEndOffset, MinReturnedRows, MaxReturnedRows, AverageReturnedRows, TotalReturnedRows, QueryText, QueryPlan, NumberOfPlans, NumberOfDistinctPlans, Warnings '
          + N' FROM ##bou_BlitzCacheProcs '
          
    SELECT @insert_sql += N' ORDER BY ' + CASE @sort_order WHEN 'cpu' THEN ' TotalCPU '
                                                    WHEN 'reads' THEN ' TotalReads '
                                                    WHEN 'writes' THEN ' TotalWrites '
                                                    WHEN 'duration' THEN ' TotalDuration '
                                                    WHEN 'executions' THEN ' ExecutionCount '
                                                    WHEN 'avg cpu' THEN 'AverageCPU'
                                                    WHEN 'avg reads' THEN 'AverageReads'
                                                    WHEN 'avg writes' THEN 'AverageWrites'
                                                    WHEN 'avg duration' THEN 'AverageDuration'
                                                    WHEN 'avg executions' THEN 'ExecutionsPerMinute'
                                                    END + N' DESC '

    SET @insert_sql += N' OPTION (RECOMPILE) ; '    
    
    EXEC sp_executesql @insert_sql, N'@top INT', @top;

    RETURN
END
ELSE IF @export_to_excel = 1
BEGIN
    RAISERROR('Displaying results with Excel formatting (no plans).', 0, 1) WITH NOWAIT;

    /* excel output */
    UPDATE ##bou_BlitzCacheProcs
    SET QueryText = SUBSTRING(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(QueryText)),' ','<>'),'><',''),'<>',' '), 1, 32000);

    SET @sql = N'
    SELECT  TOP (@top)
            DatabaseName AS [Database Name],
            QueryPlanCost AS [Cost],
            QueryText,
            QueryType AS [Query Type],
            Warnings,
            ExecutionCount,
            ExecutionsPerMinute AS [Executions / Minute],
            PercentExecutions AS [Execution Weight],
            PercentExecutionsByType AS [% Executions (Type)],
            TotalCPU AS [Total CPU (ms)],
            AverageCPU AS [Avg CPU (ms)],
            PercentCPU AS [CPU Weight],
            PercentCPUByType AS [% CPU (Type)],
            TotalDuration AS [Total Duration (ms)],
            AverageDuration AS [Avg Duration (ms)],
            PercentDuration AS [Duration Weight],
            PercentDurationByType AS [% Duration (Type)],
            TotalReads AS [Total Reads],
            AverageReads AS [Average Reads],
            PercentReads AS [Read Weight],
            PercentReadsByType AS [% Reads (Type)],
            TotalWrites AS [Total Writes],
            AverageWrites AS [Average Writes],
            PercentWrites AS [Write Weight],
            PercentWritesByType AS [% Writes (Type)],
            TotalReturnedRows,
            AverageReturnedRows,
            MinReturnedRows,
            MaxReturnedRows,
            NumberOfPlans,
            NumberOfDistinctPlans,
            PlanCreationTime AS [Created At],
            LastExecutionTime AS [Last Execution],
            StatementStartOffset,
            StatementEndOffset,
            COALESCE(SetOptions, '''') AS [SET Options]
    FROM    ##bou_BlitzCacheProcs
    WHERE   1 = 1 ' + @nl

    SELECT @sql += N' ORDER BY ' + CASE @sort_order WHEN 'cpu' THEN ' TotalCPU '
                              WHEN 'reads' THEN ' TotalReads '
                              WHEN 'writes' THEN ' TotalWrites '
                              WHEN 'duration' THEN ' TotalDuration '
                              WHEN 'executions' THEN ' ExecutionCount '
                              WHEN 'avg cpu' THEN 'AverageCPU'
                              WHEN 'avg reads' THEN 'AverageReads'
                              WHEN 'avg writes' THEN 'AverageWrites'
                              WHEN 'avg duration' THEN 'AverageDuration'
                              WHEN 'avg executions' THEN 'ExecutionsPerMinute'
                              END + N' DESC '

    SET @sql += N' OPTION (RECOMPILE) ; '

    EXEC sp_executesql @sql, N'@top INT', @top ;
END

IF @hide_summary = 0
BEGIN
    IF @reanalyze = 0
    BEGIN
        RAISERROR('Building query plan summary data.', 0, 1) WITH NOWAIT;

        /* Build summary data */
        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE frequent_execution =1)
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    1,
                    100,
                    'Execution Pattern',
                    'Frequently Executed Queries',
                    'http://brentozar.com/blitzcache/frequently-executed-queries/',
                    'Queries are being executed more than '
                    + CAST (@execution_threshold AS VARCHAR(5))
                    + ' times per minute. This can put additional load on the server, even when queries are lightweight.') ;

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  parameter_sniffing = 1
                  )
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    2,
                    50,
                    'Parameterization',
                    'Parameter Sniffing',
                    'http://brentozar.com/blitzcache/parameter-sniffing/',
                    'There are signs of parameter sniffing (wide variance in rows return or time to execute). Investigate query patterns and tune code appropriately.') ;

        /* Forced execution plans */
        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  is_forced_plan = 1
                  )
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    3,
                    5,
                    'Parameterization',
                    'Forced Plans',
                    'http://brentozar.com/blitzcache/forced-plans/',
                    'Execution plans have been compiled with forced plans, either through FORCEPLAN, plan guides, or forced parameterization. This will make general tuning efforts less effective.');

        /* Cursors */
        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  is_cursor = 1
                  )
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    4,
                    200,
                    'Cursors',
                    'Cursors',
                    'http://brentozar.com/blitzcache/cursors-found-slow-queries/',
                    'There are cursors in the plan cache. This is neither good nor bad, but it is a thing. Cursors are weird in SQL Server.');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  is_forced_parameterized = 1
                  )
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    5,
                    50,
                    'Parameterization',
                    'Forced Parameterization',
                    'http://brentozar.com/blitzcache/forced-parameterization/',
                    'Execution plans have been compiled with forced parameterization.') ;

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs p
                   WHERE  p.is_parallel = 1
                  )
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    6,
                    200,
                    'Execution Plans',
                    'Parallelism',
                    'http://brentozar.com/blitzcache/parallel-plans-detected/',
                    'Parallel plans detected. These warrant investigation, but are neither good nor bad.') ;

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs p
                   WHERE  near_parallel = 1
                  )
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    7,
                    200,
                    'Execution Plans',
                    'Nearly Parallel',
                    'http://brentozar.com/blitzcache/query-cost-near-cost-threshold-parallelism/',
                    'Queries near the cost threshold for parallelism. These may go parallel when you least expect it.') ;

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs p
                   WHERE  plan_warnings = 1
                  )
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    8,
                    50,
                    'Execution Plans',
                    'Query Plan Warnings',
                    'http://brentozar.com/blitzcache/query-plan-warnings/',
                    'Warnings detected in execution plans. SQL Server is telling you that something bad is going on that requires your attention.') ;

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs p
                   WHERE  long_running = 1
                  )
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    9,
                    50,
                    'Performance',
                    'Long Running Queries',
                    'http://brentozar.com/blitzcache/long-running-queries/',
                    'Long running queries have beend found. These are queries with an average duration longer than '
                    + CAST(@long_running_query_warning_seconds / 1000 / 1000 AS VARCHAR(5))
                    + ' second(s). These queries should be investigated for additional tuning options') ;

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs p
                   WHERE  p.missing_index_count > 0)
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    10,
                    50,
                    'Performance',
                    'Missing Index Request',
                    'http://brentozar.com/blitzcache/missing-index-request/',
                    'Queries found with missing indexes.');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs p
                   WHERE  p.downlevel_estimator = 1
                  )
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    13,
                    200,
                    'Cardinality',
                    'Legacy Cardinality Estimator in Use',
                    'http://brentozar.com/blitzcache/legacy-cardinality-estimator/',
                    'A legacy cardinality estimator is being used by one or more queries. Investigate whether you need to be using this cardinality estimator. This may be caused by compatibility levels, global trace flags, or query level trace flags.');

        IF EXISTS (SELECT 1/0
                   FROM ##bou_BlitzCacheProcs p
                   WHERE implicit_conversions = 1
                  )
            INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
            VALUES (@@SPID,
                    14,
                    50,
                    'Performance',
                    'Implicit Conversions',
                    'http://brentozar.com/go/implicit',
                    'One or more queries are comparing two fields that are not of the same data type.') ;

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  tempdb_spill = 1
                  )
        INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
        VALUES (@@SPID,
                15,
                10,
                'Performance',
                'TempDB Spills',
                'http://brentozar.com/blitzcache/tempdb-spills/',
                'TempDB spills detected. Queries are unable to allocate enough memory to proceed normally.');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  busy_loops = 1)
        INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
        VALUES (@@SPID,
                16,
                10,
                'Performance',
                'Frequently executed operators',
                'http://brentozar.com/blitzcache/busy-loops/',
                'Operations have been found that are executed 100 times more often than the number of rows returned by each iteration. This is an indicator that something is off in query execution.');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  tvf_join = 1)
        INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
        VALUES (@@SPID,
                17,
                50,
                'Performance',
                'Joining to table valued functions',
                'http://brentozar.com/blitzcache/tvf-join/',
                'Execution plans have been found that join to table valued functions (TVFs). TVFs produce inaccurate estimates of the number of rows returned and can lead to any number of query plan problems.');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  compile_timeout = 1)
        INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
        VALUES (@@SPID,
                18,
                50,
                'Execution Plans',
                'Compilation timeout',
                'http://brentozar.com/blitzcache/compilation-timeout/',
                'Query compilation timed out for one or more queries. SQL Server did not find a plan that meets acceptable performance criteria in the time allotted so the best guess was returned. There is a very good chance that this plan isn''t even below average - it''s probably terrible.');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  compile_memory_limit_exceeded = 1)
        INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
        VALUES (@@SPID,
                19,
                50,
                'Execution Plans',
                'Compilation memory limit exceeded',
                'http://brentozar.com/blitzcache/compile-memory-limit-exceeded/',
                'The optimizer has a limited amount of memory available. One or more queries are complex enough that SQL Server was unable to allocate enough memory to fully optimize the query. A best fit plan was found, and it''s probably terrible.');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  warning_no_join_predicate = 1)
        INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
        VALUES (@@SPID,
                20,
                10,
                'Execution Plans',
                'No join predicate',
                'http://brentozar.com/blitzcache/no-join-predicate/',
                'Operators in a query have no join predicate. This means that all rows from one table will be matched with all rows from anther table producing a Cartesian product. That''s a whole lot of rows. This may be your goal, but it''s important to investigate why this is happening.');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  plan_multiple_plans = 1)
        INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
        VALUES (@@SPID,
                21,
                200,
                'Execution Plans',
                'Multiple execution plans',
                'http://brentozar.com/blitzcache/multiple-plans/',
                'Queries exist with multiple execution plans (as determined by query_plan_hash). Investigate possible ways to parameterize these queries or otherwise reduce the plan count/');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  unmatched_index_count > 0)
        INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
        VALUES (@@SPID,
                22,
                100,
                'Performance',
                'Unmatched indexes',
                'http://brentozar.com/blitzcache/unmatched-indexes',
                'An index could have been used, but SQL Server chose not to use it - likely due to parameterization and filtered indexes.');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  unparameterized_query = 1)
        INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
        VALUES (@@SPID,
                23,
                100,
                'Parameterization',
                'Unparameterized queries',
                'http://brentozar.com/blitzcache/unparameterized-queries',
                'Unparameterized queries found. These could be ad hoc queries, data exploration, or queries using "OPTIMIZE FOR UNKNOWN".');

        IF EXISTS (SELECT 1/0
                   FROM   ##bou_BlitzCacheProcs
                   WHERE  is_trivial = 1)
        INSERT INTO ##bou_BlitzCacheResults (SPID, CheckID, Priority, FindingsGroup, Finding, URL, Details)
        VALUES (@@SPID,
                24,
                100,
                'Execution Plans',
                'Trivial Plans',
                'http://brentozar.com/blitzcache/trivial-plans',
                'Trivial plans get almost no optimization. If you''re finding these in the top worst queries, something may be going wrong.');
    END            
    
    IF @export_to_excel = 1
        RETURN

    SELECT  Priority,
            FindingsGroup,
            Finding,
            URL,
            Details,
            CheckID
    FROM    ##bou_BlitzCacheResults
    WHERE   SPID = @@SPID
    GROUP BY Priority,
            FindingsGroup,
            Finding,
            URL,
            Details,
            CheckID
    ORDER BY Priority ASC
    OPTION (RECOMPILE);
END



RAISERROR('Displaying analysis of plan cache.', 0, 1) WITH NOWAIT;

DECLARE @columns NVARCHAR(MAX) = N'' ;

IF LOWER(@results) = 'narrow'
BEGIN
    SET @columns = N' DatabaseName AS [Database],
    QueryPlanCost AS [Cost],
    QueryText AS [Query Text],
    QueryType AS [Query Type],
    Warnings AS [Warnings],
    ExecutionCount AS [# Executions],
    AverageCPU AS [Average CPU (ms)],
    AverageDuration AS [Average Duration (ms)],
    AverageReads AS [Average Reads],
    AverageWrites AS [Average Writes],
    AverageReturnedRows AS [Average Rows Returned],
    PlanCreationTime AS [Created At],
    LastExecutionTime AS [Last Execution],
    QueryPlan AS [Query] ';
END
ELSE IF LOWER(@results) = 'simple'
BEGIN
    SET @columns = N' DatabaseName AS [Database],
    QueryPlanCost AS [Cost],
    QueryText AS [Query Text],
    QueryType AS [Query Type],
    Warnings AS [Warnings],
    ExecutionCount AS [# Executions],
    ExecutionsPerMinute AS [Executions / Minute],
    PercentExecutions AS [Execution Weight],
    TotalCPU AS [Total CPU (ms)],
    AverageCPU AS [Avg CPU (ms)],
    PercentCPU AS [CPU Weight],
    TotalDuration AS [Total Duration (ms)],
    AverageDuration AS [Avg Duration (ms)],
    PercentDuration AS [Duration Weight],
    TotalReads AS [Total Reads],
    AverageReads AS [Avg Reads],
    PercentReads AS [Read Weight],
    TotalWrites AS [Total Writes],
    AverageWrites AS [Avg Writes],
    PercentWrites AS [Write Weight],
    AverageReturnedRows AS [Average Rows],
    PlanCreationTime AS [Created At],
    LastExecutionTime AS [Last Execution],
    QueryPlan AS [Query Plan],
    COALESCE(SetOptions, '''') AS [SET Options] ';
END
ELSE
BEGIN
    SET @columns = N' DatabaseName AS [Database],
        QueryText AS [Query Text],
        QueryType AS [Query Type],
        Warnings AS [Warnings], ' + @nl

    IF LOWER(@results) = 'opserver1'
    BEGIN
        SET @columns += '        SUBSTRING(
                  CASE WHEN warning_no_join_predicate = 1 THEN '', 20'' ELSE '''' END +
                  CASE WHEN compile_timeout = 1 THEN '', 18'' ELSE '''' END +
                  CASE WHEN compile_memory_limit_exceeded = 1 THEN '', 19'' ELSE '''' END +
                  CASE WHEN busy_loops = 1 THEN '', 16'' ELSE '''' END +
                  CASE WHEN is_forced_plan = 1 THEN '', 3'' ELSE '''' END +
                  CASE WHEN is_forced_parameterized = 1 THEN '', 5'' ELSE '''' END +
                  CASE WHEN unparameterized_query = 1 THEN '', 23'' ELSE '''' END +
                  CASE WHEN missing_index_count > 0 THEN '', 10'' ELSE '''' END +
                  CASE WHEN unmatched_index_count > 0 THEN '', 22'' ELSE '''' END +                  
                  CASE WHEN is_cursor = 1 THEN '', 4'' ELSE '''' END +
                  CASE WHEN is_parallel = 1 THEN '', 6'' ELSE '''' END +
                  CASE WHEN near_parallel = 1 THEN '', 7'' ELSE '''' END +
                  CASE WHEN frequent_execution = 1 THEN '', 1'' ELSE '''' END +
                  CASE WHEN plan_warnings = 1 THEN '', 8'' ELSE '''' END +
                  CASE WHEN parameter_sniffing = 1 THEN '', 2'' ELSE '''' END +
                  CASE WHEN long_running = 1 THEN '', 9'' ELSE '''' END +
                  CASE WHEN downlevel_estimator = 1 THEN '', 13'' ELSE '''' END +
                  CASE WHEN implicit_conversions = 1 THEN '', 14'' ELSE '''' END +
                  CASE WHEN tempdb_spill = 1 THEN '', 15'' ELSE '''' END +
                  CASE WHEN tvf_join = 1 THEN '', 17'' ELSE '''' END +
                  CASE WHEN plan_multiple_plans = 1 THEN '', 21'' ELSE '''' END +
                  CASE WHEN unmatched_index_count > 0 THEN '', 22'', ELSE '''' END + 
                  CASE WHEN unparameterized_query > 0 THEN '', 23'', ELSE '''' END + 
                  Case WHEN is_trivial = 1 THEN '', 24'', ELSE '''' END
                  , 2, 200000) AS opserver_warning , ' + @nl ;
    END
    
    SET @columns += N'        ExecutionCount AS [# Executions],
        ExecutionsPerMinute AS [Executions / Minute],
        PercentExecutions AS [Execution Weight],
        TotalCPU AS [Total CPU (ms)],
        AverageCPU AS [Avg CPU (ms)],
        PercentCPU AS [CPU Weight],
        TotalDuration AS [Total Duration (ms)],
        AverageDuration AS [Avg Duration (ms)],
        PercentDuration AS [Duration Weight],
        TotalReads AS [Total Reads],
        AverageReads AS [Average Reads],
        PercentReads AS [Read Weight],
        TotalWrites AS [Total Writes],
        AverageWrites AS [Average Writes],
        PercentWrites AS [Write Weight],
        PercentExecutionsByType AS [% Executions (Type)],
        PercentCPUByType AS [% CPU (Type)],
        PercentDurationByType AS [% Duration (Type)],
        PercentReadsByType AS [% Reads (Type)],
        PercentWritesByType AS [% Writes (Type)],
        TotalReturnedRows AS [Total Rows],
        AverageReturnedRows AS [Avg Rows],
        MinReturnedRows AS [Min Rows],
        MaxReturnedRows AS [Max Rows],
        NumberOfPlans AS [# Plans],
        NumberOfDistinctPlans AS [# Distinct Plans],
        PlanCreationTime AS [Created At],
        LastExecutionTime AS [Last Execution],
        QueryPlanCost AS [Query Plan Cost],
        QueryPlan AS [Query Plan],
        COALESCE(SetOptions, '''') AS [SET Options],
        PlanHandle AS [Plan Handle],
        SqlHandle AS [SQL Handle],
        QueryHash AS [Query Hash],
        StatementStartOffset,
        StatementEndOffset ';
END



SET @sql = N'
SELECT  TOP (@top) ' + @columns + @nl + N'
FROM    ##bou_BlitzCacheProcs
WHERE   SPID = @spid ' + @nl

SELECT @sql += N' ORDER BY ' + CASE @sort_order WHEN 'cpu' THEN ' TotalCPU '
                                                WHEN 'reads' THEN ' TotalReads '
                                                WHEN 'writes' THEN ' TotalWrites '
                                                WHEN 'duration' THEN ' TotalDuration '
                                                WHEN 'executions' THEN ' ExecutionCount '
                                                WHEN 'avg cpu' THEN 'AverageCPU'
                                                WHEN 'avg reads' THEN 'AverageReads'
                                                WHEN 'avg writes' THEN 'AverageWrites'
                                                WHEN 'avg duration' THEN 'AverageDuration'
                                                WHEN 'avg executions' THEN 'ExecutionsPerMinute'
                               END + N' DESC '
SET @sql += N' OPTION (RECOMPILE) ; '

EXEC sp_executesql @sql, N'@top INT, @spid INT', @top, @@SPID ;


GO










IF OBJECT_ID('tempdb..##sp_BlitzRS') IS NULL
  EXEC ('CREATE PROCEDURE ##sp_BlitzRS AS RETURN 0;')
GO


ALTER PROCEDURE [##sp_BlitzRS]
(@WhoGetsWhat TINYINT = 0)
WITH RECOMPILE
/******************************************
sp_BlitzRS (TM) 2014, Brent Ozar Unlimited.
(C) 2014, Brent Ozar Unlimited.
See http://BrentOzar.com/go/eula for the End User Licensing Agreement.



Description: Displays information about a single SQL Server Reporting
Services instance based on the ReportServer database contents. Run this 
against the server with the ReportServer database (usually, but not 
necessarily the server running the SSRS service).

Output: One result set is presented that contains data from the ReportServer
database tables. Other result sets can be included via parameter.

To learn more, visit http://brentozar.com/blitzRS/
where you can download new versions for free, watch training videos on
how it works, get more info on the findings, and more. To contribute
code, file bugs, and see your name in the change log, visit:
http://support.brentozar.com/


KNOWN ISSUES:
- This query will not run on SQL Server 2005.
- Looks for the ReportServer database only.
- May run for several minutes if the catalog is large (1,000+ items).
- Will not identify data-driven subscription source query information
  such as tables, parameters, or recipients.

v0.92 - 2014-09-22
 - Fixed issue where query would try to parse images and other objects as XML.
 - Lengthened dataset CommandText and subscription Parameter variables.

v0.91 - 2014-09-17
 - Corrected inconsistent case-sensitivity

v0.9 - 2014-09-16
 - Changed support links, added credit.

v0.8 - 2014-08-29
 - Added "who gets what" parameter and query.



*******************************************/
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF OBJECT_ID('tempdb..#BlitzRSResults') IS NOT NULL
    DROP TABLE #BlitzRSResults;

CREATE TABLE #BlitzRSResults
    (
      ID INT IDENTITY(1, 1) ,
      CheckID INT ,
      [Priority] TINYINT ,
      FindingsGroup VARCHAR(50) ,
      Finding VARCHAR(200) ,
      URL VARCHAR(200) ,
      Details NVARCHAR(4000)
    )

/* Parameter variables */

DECLARE @DeadReportThreshold SMALLINT = 0

/* 
-------------------------------------------------------------------
CHECK #1
Find reports that don't have any stored procs or shared datasets.
-------------------------------------------------------------------
*/

DECLARE @DataSetContent TABLE
    (
      ItemID UNIQUEIDENTIFIER ,
      ReportName NVARCHAR(200) ,
      DataSetName NVARCHAR(200) ,
      DataSourceName NVARCHAR(200) ,
      CommandText NVARCHAR(MAX) ,
      SharedDataSetRef NVARCHAR(80)
    );
DECLARE @DataSets TABLE
    (
      ItemID UNIQUEIDENTIFIER ,
      ReportName NVARCHAR(200) ,
      Content XML
    );

INSERT  @DataSets
        ( ItemID ,
          ReportName ,
          Content 
        )
        SELECT  ItemID ,
                [Name] AS ReportName ,
                CAST(CAST(Content AS VARBINARY(MAX)) AS XML)
        FROM    dbo.Catalog
		WHERE [Type] = 2;
		;
WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition' AS p
				 , 'http://schemas.microsoft.com/sqlserver/reporting/2010/01/reportdefinition' AS p1)
INSERT @DataSetContent
        ( ItemID, ReportName, DataSetName, DataSourceName, CommandText, SharedDataSetRef )
SELECT    ItemID , ReportName,
					AOP.Params.value('@Name', 'Varchar(800)') AS 'PDStName',
					AOP.Params.value('p:Query[1]/p:DataSourceName[1]', 'Varchar(800)') AS 'PName',
                    AOP.Params.value('p:Query[1]/p:CommandText[1]', 'Varchar(800)') AS 'PCmd',
					AOP.Params.value('p:SharedDataSet[1]/p:SharedDataSetReference[1]', 'Varchar(800)') AS 'PSDSR'
          FROM      @DataSets
          CROSS APPLY Content.nodes('/p:Report/p:DataSets/p:DataSet') AS AOP ( Params )
UNION
SELECT    ItemID , ReportName, AOP.Params.value('@Name', 'Varchar(800)') AS 'PDStName',
					AOP.Params.value('p1:Query[1]/p1:DataSourceName[1]', 'Varchar(800)') AS 'PName',
                    AOP.Params.value('p1:Query[1]/p1:CommandText[1]', 'Varchar(800)') AS 'PCmd',
					AOP.Params.value('p1:SharedDataSet[1]/p1:SharedDataSetReference[1]', 'Varchar(800)') AS 'PSDSR'
          FROM      @DataSets
          CROSS APPLY Content.nodes('/p1:Report/p1:DataSets/p1:DataSet') AS AOP ( Params )


INSERT  #BlitzRSResults
        ( CheckID ,
          [Priority] ,
          FindingsGroup ,
          Finding ,
          URL ,
          Details
        )
        SELECT  1 ,
                100 ,
                'Maintainability' ,
                'Reports with 100% inline T-SQL' ,
                'http://brentozar.com/BlitzRS/inlinetsql' ,
                'The datasets in the "' + ReportName
                + '" report all use inline T-SQL, rather that stored procs or shared datasets. This can make datasets harder to tune and schema changes harder to adapt to.'
        FROM    @DataSetContent
        GROUP BY ReportName
        HAVING  SUM(CASE WHEN CHARINDEX('SELECT', CommandText, 0) > 0 THEN 1
                         ELSE 0
                    END) > 1
                AND SUM(CASE WHEN CHARINDEX('SELECT', CommandText, 0) = 0
                                  AND SharedDataSetRef IS NULL THEN 1
                             ELSE 0
                        END)
                + SUM(CASE WHEN SharedDataSetRef IS NOT NULL THEN 1
                           ELSE 0
                      END) = 0


/* 
-------------------------------------------------------------------
CHECK #2
Finds data dumps (large, featureless reports) in disguise.
-------------------------------------------------------------------
*/


DECLARE @ContentFeatures TABLE
    (
      ItemID UNIQUEIDENTIFIER ,
      ReportName NVARCHAR(200) ,
      HasCharts BIT ,
      HasGauges BIT ,
      HasMaps BIT ,
      HasSubreports BIT ,
      HasDrillthroughs BIT ,
      HasToggles BIT
    );
DECLARE @ContentXML TABLE
    (
      ItemID UNIQUEIDENTIFIER ,
      ReportName NVARCHAR(200) ,
      Content XML
    );

INSERT  @ContentXML
        ( ItemID ,
          ReportName ,
          Content 
        )
        SELECT  ItemID ,
                [Name] AS ReportName ,
                CAST(CAST(Content AS VARBINARY(MAX)) AS XML)
        FROM    dbo.Catalog
        WHERE   [Type] = 2;
		;
WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition' AS p
				 , 'http://schemas.microsoft.com/sqlserver/reporting/2010/01/reportdefinition' AS p1)
INSERT @ContentFeatures
        ( ItemID, ReportName, HasCharts, HasGauges, HasMaps, HasSubreports, HasDrillthroughs, HasToggles )
SELECT    ItemID , ReportName,
		CASE WHEN Content.exist('//p:Chart') = 1 THEN 1 ELSE 0 END AS HasCharts,
		CASE WHEN Content.exist('//p:GaugePanel') = 1 THEN 1 ELSE 0 END AS HasGauges,
		CASE WHEN Content.exist('//p:Map') = 1 THEN 1 ELSE 0 END AS HasMaps,
		CASE WHEN Content.exist('//p:Subreport') = 1 THEN 1 ELSE 0 END AS HasSubreports,
		CASE WHEN Content.exist('//p:Drillthrough') = 1 THEN 1 ELSE 0 END AS HasDrillthroughs,
		CASE WHEN Content.exist('//p:ToggleItem') = 1 THEN 1 ELSE 0 END AS HasToggles
          FROM      @ContentXML
		 WHERE CHARINDEX('http://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition', CAST(Content AS NVARCHAR(MAX))) > 0 
UNION
SELECT    ItemID , ReportName,
		CASE WHEN Content.exist('//p1:Chart') = 1 THEN 1 ELSE 0 END  ,
		CASE WHEN Content.exist('//p1:GaugePanel') = 1 THEN 1 ELSE 0 END ,
		CASE WHEN Content.exist('//p1:Map') = 1 THEN 1 ELSE 0 END ,
		CASE WHEN Content.exist('//p1:Subreport') = 1 THEN 1 ELSE 0 END ,
		CASE WHEN Content.exist('//p1:Drillthrough') = 1 THEN 1 ELSE 0 END ,
		CASE WHEN Content.exist('//p1:ToggleItem') = 1 THEN 1 ELSE 0 END 
          FROM      @ContentXML
WHERE CHARINDEX('http://schemas.microsoft.com/sqlserver/reporting/2010/01/reportdefinition', CAST(Content AS NVARCHAR(MAX))) > 0 

INSERT  #BlitzRSResults
        ( CheckID ,
          [Priority] ,
          FindingsGroup ,
          Finding ,
          URL ,
          Details
        )
        SELECT DISTINCT
                2 ,
                50 ,
                'Performance' ,
                'Data Dumps in Disguise' ,
                'http://brentozar.com/BlitzRS/datadumps' ,
                'The "' + ReportName
                + '" report appears to be a data dump with no special SSRS features. If your server is under pressure, consider delivering this data through other means.'
        FROM    ExecutionLogStorage els WITH ( NOLOCK )
                JOIN Catalog C ON ( els.ReportID = C.ItemID )
                JOIN @ContentFeatures AS cf ON cf.ItemID = C.ItemID
        WHERE   [RowCount] >= 1000
                AND TimeDataRetrieval + TimeProcessing + TimeRendering > 5000
                AND ReportAction = 1
                AND RequestType IN ( 1, 2 )
                AND HasCharts = 0
                AND HasGauges = 0
                AND HasMaps = 0
                AND HasSubreports = 0
                AND HasDrillthroughs = 0
                AND HasToggles = 0;


/* 
-------------------------------------------------------------------
CHECK #3
Find reports needing a performance tune-up.
-------------------------------------------------------------------
*/

INSERT  #BlitzRSResults
        ( CheckID ,
          [Priority] ,
          FindingsGroup ,
          Finding ,
          URL ,
          Details
        )
        SELECT  3 AS CheckID ,
                60 AS [Priority] ,
                'Performance' AS FindingsGroup ,
                'Slow Datasets' AS Finding ,
                'http://brentozar.com/BlitzRS/slowdataset' AS URL ,
                'The "' + c.Path
                + '" report waits an average of 5+ seconds for query data to come back. There may be a query here that needs tuning. ' AS Details
        FROM    ExecutionLogStorage AS els
                JOIN Catalog AS c ON ( els.ReportID = c.ItemID )
        WHERE   ReportAction = 1
                AND RequestType IN ( 1, 2 )
        GROUP BY c.Path
        HAVING  AVG(TimeDataRetrieval) > 5000


/* 
-------------------------------------------------------------------
CHECK #4
Find reports that used to run but have failed from a certain point
forward.
-------------------------------------------------------------------
*/
;
WITH    cte
          AS ( SELECT   ReportID ,
                        c.Name AS ReportName ,
                        MAX(CASE WHEN [Status] = 'rsSuccess' THEN TimeStart
                            END) AS LastKnownSuccess
               FROM     dbo.ExecutionLogStorage AS els
                        JOIN dbo.Catalog AS c ON c.ItemID = els.ReportID
               GROUP BY ReportID ,
                        c.Name
             )
    INSERT  #BlitzRSResults
            ( CheckID ,
              [Priority] ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  4 AS CheckID ,
                    40 AS [Priority] ,
                    'Reliability' AS FindingsGroup ,
                    '"I''ve fallen and I can''t get up!"' AS Finding ,
                    'http://brentozar.com/BlitzRS/reportdown' AS URL ,
                    'The "' + cte.ReportName
                    + '" report last ran successfully at '
                    + CAST(cte.LastKnownSuccess AS VARCHAR(24))
                    + '. Since then, it''s had '
                    + CAST(COUNT([status]) AS VARCHAR(20))
                    + ' failed executions.' AS Details
            FROM    dbo.ExecutionLogStorage AS els
                    JOIN cte ON cte.ReportID = els.ReportID
                                AND els.TimeStart >= DATEADD(dd,
                                                             @DeadReportThreshold,
                                                             cte.LastKnownSuccess)
            WHERE   Status != 'rsSuccess'
            GROUP BY cte.ReportName ,
                    cte.LastKnownSuccess

/* 
-------------------------------------------------------------------
CHECK #5
Find altered role permissions and affected users.
-------------------------------------------------------------------
*/

IF OBJECT_ID('tempdb..#RoleDefault') IS NOT NULL
    DROP TABLE #RoleDefault;

CREATE TABLE #RoleDefault
    (
      RoleName NVARCHAR(32) ,
      RoleFlags TINYINT ,
      TaskMask NVARCHAR(32)
    )
INSERT  #RoleDefault
        ( RoleName, RoleFlags, TaskMask )
VALUES  ( N'Browser', 0, N'0010101001000100' )
		,
        ( N'Content Manager', 0, N'1111111111111111' )
		,
        ( N'Model Item Browser', 2, N'1' )
		,
        ( N'My Reports', 0, N'0111111111011000' )
		,
        ( N'Publisher', 0, N'0101010100001010' )
		,
        ( N'Report Builder', 0, N'0010101001000101' )
		,
        ( N'System Administrator', 1, N'110101011' )
		,
        ( N'System User', 1, N'001010001' )

IF OBJECT_ID('tempdb..#RoleDefaultTaskMask') IS NOT NULL
    DROP TABLE #RoleDefaultTaskMask;

CREATE TABLE #RoleDefaultTaskMask
    (
      RoleName NVARCHAR(32) ,
      RoleFlags TINYINT ,
      TaskMaskPos TINYINT ,
      TaskMaskValue TINYINT
    )
INSERT  #RoleDefaultTaskMask
        ( RoleName ,
          RoleFlags ,
          TaskMaskPos ,
          TaskMaskValue
        )
        SELECT  RoleName ,
                RoleFlags ,
                upvt.TaskMaskPos ,
                upvt.TaskMask AS TaskMaskValue
        FROM    ( SELECT    RoleName ,
                            RoleFlags ,
                            CAST(SUBSTRING(TaskMask, 1, 1) AS CHAR(1)) AS [1] ,
                            CAST(SUBSTRING(TaskMask, 2, 1) AS CHAR(1)) AS [2] ,
                            CAST(SUBSTRING(TaskMask, 3, 1) AS CHAR(1)) AS [3] ,
                            CAST(SUBSTRING(TaskMask, 4, 1) AS CHAR(1)) AS [4] ,
                            CAST(SUBSTRING(TaskMask, 5, 1) AS CHAR(1)) AS [5] ,
                            CAST(SUBSTRING(TaskMask, 6, 1) AS CHAR(1)) AS [6] ,
                            CAST(SUBSTRING(TaskMask, 7, 1) AS CHAR(1)) AS [7] ,
                            CAST(SUBSTRING(TaskMask, 8, 1) AS CHAR(1)) AS [8] ,
                            CAST(SUBSTRING(TaskMask, 9, 1) AS CHAR(1)) AS [9] ,
                            CAST(SUBSTRING(TaskMask, 10, 1) AS CHAR(1)) AS [10] ,
                            CAST(SUBSTRING(TaskMask, 11, 1) AS CHAR(1)) AS [11] ,
                            CAST(SUBSTRING(TaskMask, 12, 1) AS CHAR(1)) AS [12] ,
                            CAST(SUBSTRING(TaskMask, 13, 1) AS CHAR(1)) AS [13] ,
                            CAST(SUBSTRING(TaskMask, 14, 1) AS CHAR(1)) AS [14] ,
                            CAST(SUBSTRING(TaskMask, 15, 1) AS CHAR(1)) AS [15] ,
                            CAST(SUBSTRING(TaskMask, 16, 1) AS CHAR(1)) AS [16]
                  FROM      #RoleDefault
                ) AS r UNPIVOT
( TaskMask FOR TaskMaskPos IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9],
                                [10], [11], [12], [13], [14], [15], [16] ) ) AS upvt
        WHERE   TaskMask != ' '

IF OBJECT_ID('tempdb..#RolePermissions') IS NOT NULL
    DROP TABLE #RolePermissions;

CREATE TABLE #RolePermissions
    (
      RoleFlag TINYINT ,
      TaskMaskPos TINYINT ,
      Permission NVARCHAR(80)
    )
INSERT  #RolePermissions
        ( RoleFlag, TaskMaskPos, Permission )
VALUES  ( 0, 1, N'Set security for individual items' )
		,
        ( 0, 2, N'Create linked reports' )
		,
        ( 0, 3, N'View reports' )
		,
        ( 0, 4, N'Manage reports' )
		,
        ( 0, 5, N'View resources' )
		,
        ( 0, 6, N'Manage resources' )
		,
        ( 0, 7, N'View folders' )
		,
        ( 0, 8, N'Manage folders' )
		,
        ( 0, 9, N'Manage report history' )
		,
        ( 0, 10, N'Manage individual subscriptions' )
		,
        ( 0, 11, N'Manage all subscriptions' )
		,
        ( 0, 12, N'View data sources' )
		,
        ( 0, 13, N'Manage data sources' )
		,
        ( 0, 14, N'View models' )
		,
        ( 0, 15, N'Manage models' )
		,
        ( 0, 16, N'Consume reports' )
		,
        ( 1, 1, N'Manage roles' )
		,
        ( 1, 2, N'Manage report server security' )
		,
        ( 1, 3, N'View report server properties' )
		,
        ( 1, 4, N'Manage report server properties' )
		,
        ( 1, 5, N'View shared schedules' )
		,
        ( 1, 6, N'Manage shared schedules' )
		,
        ( 1, 7, N'Generate events' )
		,
        ( 1, 8, N'Manage jobs' )
		,
        ( 1, 9, N'Execute Report Definitions' )

IF OBJECT_ID('tempdb..#RoleTaskMask') IS NOT NULL
    DROP TABLE #RoleTaskMask;

CREATE TABLE #RoleTaskMask
    (
      RoleName NVARCHAR(32) ,
      RoleFlags TINYINT ,
      TaskMaskPos TINYINT ,
      TaskMaskValue TINYINT
    )

INSERT  #RoleTaskMask
        ( RoleName ,
          RoleFlags ,
          TaskMaskPos ,
          TaskMaskValue
        )
        SELECT  RoleName ,
                RoleFlags ,
                upvt.TaskMaskPos ,
                upvt.TaskMask AS TaskMaskValue
        FROM    ( SELECT    RoleName ,
                            RoleFlags ,
                            SUBSTRING(TaskMask, 1, 1) AS [1] ,
                            SUBSTRING(TaskMask, 2, 1) AS [2] ,
                            SUBSTRING(TaskMask, 3, 1) AS [3] ,
                            SUBSTRING(TaskMask, 4, 1) AS [4] ,
                            SUBSTRING(TaskMask, 5, 1) AS [5] ,
                            SUBSTRING(TaskMask, 6, 1) AS [6] ,
                            SUBSTRING(TaskMask, 7, 1) AS [7] ,
                            SUBSTRING(TaskMask, 8, 1) AS [8] ,
                            SUBSTRING(TaskMask, 9, 1) AS [9] ,
                            SUBSTRING(TaskMask, 10, 1) AS [10] ,
                            SUBSTRING(TaskMask, 11, 1) AS [11] ,
                            SUBSTRING(TaskMask, 12, 1) AS [12] ,
                            SUBSTRING(TaskMask, 13, 1) AS [13] ,
                            SUBSTRING(TaskMask, 14, 1) AS [14] ,
                            SUBSTRING(TaskMask, 15, 1) AS [15] ,
                            SUBSTRING(TaskMask, 16, 1) AS [16]
                  FROM      dbo.Roles
                ) AS r UNPIVOT
( TaskMask FOR TaskMaskPos IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9],
                                [10], [11], [12], [13], [14], [15], [16] ) ) AS upvt
        WHERE   TaskMask != ' '

INSERT  #BlitzRSResults
        ( CheckID ,
          [Priority] ,
          FindingsGroup ,
          Finding ,
          URL ,
          Details
        )
        SELECT  4 AS CheckID ,
                20 AS [Priority] ,
                'Security' AS FindingsGroup ,
                'Non-Default Role Permissions' AS Finding ,
                'http://brentozar.com/BlitzRS/roledefaults' AS URL ,
                'The user ' + u.UserName + ' has '
                + CASE WHEN r.TaskMaskValue = 0 THEN 'been denied '
                       ELSE ''
                  END + 'permission to "' + rp.Permission + '" because the '
                + r.RoleName
                + ' role''s default security settings have been changed.' AS Details
        FROM    #RoleTaskMask AS r
                JOIN #RoleDefaultTaskMask AS rd ON rd.RoleName = r.RoleName
                                                   AND rd.RoleFlags = r.RoleFlags
                                                   AND rd.TaskMaskPos = r.TaskMaskPos
                JOIN #RolePermissions AS rp ON rp.RoleFlag = r.RoleFlags
                                               AND rp.TaskMaskPos = r.TaskMaskPos
                JOIN dbo.Roles AS ro ON ro.RoleName COLLATE DATABASE_DEFAULT = r.RoleName
                LEFT JOIN dbo.PolicyUserRole AS pur ON ro.RoleID = pur.RoleID
                LEFT JOIN dbo.Users AS u ON pur.UserID = u.UserID
        WHERE   r.TaskMaskValue != rd.TaskMaskValue

/* 
-------------------------------------------------------------------
CHECK #6
Find accounts with administrator-like privileges.
-------------------------------------------------------------------
*/

INSERT  #BlitzRSResults
        ( CheckID ,
          [Priority] ,
          FindingsGroup ,
          Finding ,
          URL ,
          Details
        )
        SELECT DISTINCT
                5 AS CheckID ,
                30 AS [Priority] ,
                'Security' AS FindingsGroup ,
                'Accounts with admin privileges' AS Finding ,
                'http://brentozar.com/BlitzRS/admins' AS URL ,
                'The user ' + u.UserName + ' belongs to the ' + ro.RoleName
                + ' role. This role has some administrator-like privileges related to '
                + CASE WHEN ro.RoleName = 'Content Manager'
                       THEN 'reports, subscriptions, and datasets.'
                       WHEN ro.RoleName = 'System Administrator'
                       THEN 'schedules and security.'
                       ELSE 'something, but I'' not sure what.'
                  END AS Details
        FROM    dbo.Roles AS ro
                LEFT JOIN dbo.PolicyUserRole AS pur ON ro.RoleID = pur.RoleID
                LEFT JOIN dbo.Users AS u ON pur.UserID = u.UserID
        WHERE   ro.RoleName IN ( 'Content Manager', 'System Administrator' )

/* ------------------------------------------------------- */
/* SECTION IS FOR LATER USE */


--DECLARE @CatalogParams TABLE
--    (
--      ItemID UNIQUEIDENTIFIER ,
--	  ParamName NVARCHAR(80),
--	  DefaultValue NVARCHAR(80)
--    );
--DECLARE @Catalog TABLE
--    (
--      ItemID UNIQUEIDENTIFIER ,
--      ParamField XML
--    );

--INSERT  @Catalog
--        ( ItemID ,
--		  ParamField 
--        )
--        SELECT  ItemID ,
--                CAST([Parameter] AS XML)
--        FROM    dbo.Catalog
--		WHERE [Type] = 2;
--		;
--INSERT @CatalogParams
--        ( ItemID, ParamName, DefaultValue )
--SELECT    ItemID ,
--					AOP.Params.value('Name[1]', 'Varchar(800)') AS 'PName',
--					AOP.Params.value('DefaultValues[1]/Value[1]', 'Varchar(800)') AS 'PVal'
--          FROM      @Catalog
--          CROSS APPLY ParamField.nodes('//Parameters/Parameter') AS AOP ( Params )

--SELECT * FROM @CatalogParams

/* END SECTION */
/*---------------------------------------------------------*/

/* 
-------------------------------------------------------------------
CHECK #7
Find reports that may do better with snapshots.
-------------------------------------------------------------------
*/
;
WITH    cte
          AS ( SELECT   COUNT(LogEntryId) AS RenderCount ,
                        ReportID 
               FROM     dbo.ExecutionLogStorage AS els
               WHERE    TimeDataRetrieval + TimeProcessing + TimeDataRetrieval >= 5000
			   			AND RequestType IN (0, 1)
						AND els.[Format] IS NOT NULL
               GROUP BY ReportID 
             )
    INSERT  #BlitzRSResults
            ( CheckID ,
              [Priority] ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT
			  7 AS CheckID ,
                    70 AS [Priority] ,
                    'Performance' AS FindingsGroup ,
                    'Candidates for snapshots' AS Finding ,
                    'http://brentozar.com/BlitzRS/snapshots' AS URL ,
                    'When the ' + c.[Name] + ' report runs over 5 seconds, '
                    + CAST(CAST(( COUNT(els.LogEntryId) * 100.0 )
                    / ( cte.RenderCount * 1.0 ) AS DECIMAL(9, 0)) AS NVARCHAR(3))
                    + '% of the time it uses a distinct format and set of parameters. This makes it a candidate for rendering from a snapshot.'
            FROM    dbo.ExecutionLogStorage AS els
                    JOIN cte ON cte.ReportID = els.ReportID
                    JOIN dbo.Catalog AS c ON c.itemid = els.ReportID
            WHERE   TimeDataRetrieval + TimeProcessing + TimeDataRetrieval >= 5000
                    AND cte.RenderCount >= 20
					AND els.RequestType IN (0, 1)
					AND els.[Format] IS NOT NULL
            GROUP BY c.[Name] ,
                    CAST(els.[Parameters] AS NVARCHAR(2000)) ,
                    cte.RenderCount,
					els.[Format]
            HAVING  CAST(( COUNT(els.LogEntryId) * 100.0 ) / ( cte.RenderCount
                                                              * 1.0 ) AS DECIMAL(9,
                                                              0)) > 20
            ORDER BY COUNT(LogEntryId) DESC

/* 
-------------------------------------------------------------------
CHECK #8
Find reports that may be worth caching.
-------------------------------------------------------------------
*/

;
WITH    cte
          AS ( SELECT   ReportID ,
                        COUNT(LogEntryId) AS RenderCount
               FROM     dbo.ExecutionLogStorage
               WHERE    RequestType IN ( 1, 2 )
               GROUP BY ReportID
             )
    INSERT  #BlitzRSResults
            ( CheckID ,
              [Priority] ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  8 AS CheckID ,
                    80 AS [Priority] ,
                    'Performance' AS FindingsGroup ,
                    'Candidates for caching' AS Finding ,
                    'http://brentozar.com/BlitzRS/caching' AS URL ,
                    'When the ' + c.[Name] + ' report runs, '
                    + CAST(CAST(( COUNT(els.LogEntryId) * 100.0 )
                    / ( cte.RenderCount * 1.0 ) AS DECIMAL(9, 0)) AS NVARCHAR(3))
                    + '% of the time it starts during the '
                    + CAST(DATEPART(hh, TimeStart) AS NVARCHAR(12))
                    + ':00 hour. Caching these reports can improve performance during this hour.'
            FROM    dbo.ExecutionLogStorage AS els
                    JOIN cte ON cte.ReportID = els.ReportID
                    JOIN dbo.Catalog AS c ON c.itemid = els.ReportID
            WHERE   RequestType IN ( 1, 2 )
                    AND cte.RenderCount >= 20
            GROUP BY c.[Name] ,
                    DATEPART(hh, TimeStart) ,
                    cte.RenderCount
            HAVING  CAST(( COUNT(els.LogEntryId) * 100.0 ) / ( cte.RenderCount
                                                              * 1.0 ) AS DECIMAL(9,
                                                              0)) >= 10

/* 
-------------------------------------------------------------------
CHECK #9
See when the ReportServer database was last backed up.
-------------------------------------------------------------------
*/

INSERT  INTO #BlitzRSResults
        ( CheckID ,
          [Priority] ,
          FindingsGroup ,
          Finding ,
          URL ,
          Details
        )
        SELECT  10 AS CheckID ,
                10 AS [PRIORITY] ,
                'Backup' AS FindingsGroup ,
                'Backups Not Performed Recently' AS Finding ,
                'http://brentozar.com/BlitzRS/nobackup' AS URL ,
                'Database ' + d.Name + ' last backed up: '
                + CAST(COALESCE(MAX(b.backup_finish_date), ' never ') AS VARCHAR(200)) AS Details
        FROM    master.sys.databases d
                LEFT OUTER JOIN msdb.dbo.backupset b ON d.name COLLATE SQL_Latin1_General_CP1_CI_AS = b.database_name COLLATE SQL_Latin1_General_CP1_CI_AS
                                                        AND b.type = 'D'
                                                        AND b.server_name = SERVERPROPERTY('ServerName') /*Backupset ran on current server */
        WHERE   d.database_id <> 2  /* Bonus points if you know what that means */
                AND d.state <> 1 /* Not currently restoring, like log shipping databases */
                AND d.is_in_standby = 0 /* Not a log shipping target database */
                AND d.source_database_id IS NULL /* Excludes database snapshots */
                AND d.name = 'ReportServer'
		/*
		The above NOT IN filters out the databases we're not supposed to check.
		*/
        GROUP BY d.name
        HAVING  MAX(b.backup_finish_date) <= DATEADD(dd, -7, GETDATE());

/* 
-------------------------------------------------------------------
CHECK #10
Find who has a report subscription where the recipient is explicitly
stated (not in a data-driven result set).
-------------------------------------------------------------------
*/

IF OBJECT_ID('tempdb..#numbers') IS NOT NULL
    DROP TABLE #numbers;
IF OBJECT_ID('tempdb..#parms') IS NOT NULL
    DROP TABLE #parms;

/* Create a numbers table to cycle through number positions */

CREATE TABLE #numbers ( n SMALLINT )

DECLARE @x SMALLINT = 0
DECLARE @sql NVARCHAR(MAX)

SET @sql = N'INSERT #numbers VALUES '
WHILE @x < 800
    BEGIN
        SET @sql = @sql + '(' + CAST(@x AS VARCHAR(3)) + '),';
        SET @x = @x + 1
    END

SET @sql = @sql + '(' + CAST(@x AS VARCHAR(3)) + ')';

/* Populate the numbers table up to 800 */
EXEC sp_executesql @sql;

/* Fill a parameters table by changing ExtensionSettings to XML,
then parsing it, taking only the {to, cc, bcc} set.

*/

CREATE TABLE #parms
    (
      SubscriptionID UNIQUEIDENTIFIER ,
      parm NVARCHAR(3200) ,
      pos SMALLINT
    );
WITH    cte
          AS ( SELECT   SubscriptionID ,
                        CASE WHEN RIGHT(s.value('(Value/text())[1]',
                                                'nvarchar(800)'), 1) = ';'
                             THEN LEFT(s.value('(Value/text())[1]',
                                               'nvarchar(800)'),
                                       LEN(s.value('(Value/text())[1]',
                                                   'nvarchar(800)')) - 1)
                             ELSE s.value('(Value/text())[1]', 'nvarchar(800)')
                        END AS parm
               FROM     ( SELECT    SubscriptionID ,
                                    CAST(ExtensionSettings AS XML) AS ExtSettings
                          FROM      dbo.Subscriptions
                          WHERE     DeliveryExtension = 'Report Server Email'
                        ) AS subs
                        CROSS APPLY subs.ExtSettings.nodes('/ParameterValues/ParameterValue')
                        AS SubsX ( s )
               WHERE    s.value('(Name/text())[1]', 'nvarchar(800)') IN ( 'TO',
                                                              'CC', 'BCC' )
             )
    INSERT  #parms
            ( SubscriptionID ,
              parm ,
              pos
            )
            SELECT DISTINCT
                    cte.SubscriptionID ,
                    parm ,
                    n AS pos
            FROM    cte
                    CROSS JOIN #numbers
            WHERE   ( CHARINDEX(';', parm, n) = n
                      OR ( CHARINDEX(';', parm, n) = 0
                           AND n = 0
                         )
                      OR n = 0
                    )
                    AND LEN(parm) != n 

INSERT  #BlitzRSResults
        ( CheckID ,
          [Priority] ,
          FindingsGroup ,
          Finding ,
          URL ,
          Details
        )
        SELECT  10 AS CheckID ,
                150 AS [Priority] ,
                'Informational' AS FindingsGroup ,
                'E-mail accounts with subscriptions' AS Finding ,
                'http://brentozar.com/BlitzRS/emailsubs' AS URL ,
                'The e-mail address "'
                + CASE WHEN pos = 0
                            AND CHARINDEX(';', parm, pos) > 0
                       THEN SUBSTRING(parm, pos + 1,
                                      CHARINDEX(';', parm, pos) - 1)
                       WHEN pos = 0
                            AND CHARINDEX(';', parm, pos) = 0 THEN parm
                       ELSE SUBSTRING(parm, pos + 1, CHARINDEX(';', parm, pos))
                  END + '" is included in '
                + CAST(COUNT(p.SubscriptionID) AS NVARCHAR(8))
                + ' subscriptions'
                + CASE WHEN SUM(CASE WHEN s.DataSettings IS NULL THEN 0
                                     ELSE 1
                                END) > 0
                       THEN ', including at least one data-driven subscription'
                       ELSE ''
                  END + '.'
        FROM    #parms AS p
                JOIN dbo.Subscriptions AS s ON s.SubscriptionID = p.SubscriptionID
                JOIN dbo.Catalog AS c ON c.ItemID = s.Report_OID
                JOIN dbo.ReportSchedule AS rs ON rs.ReportID = s.Report_OID
                                                 AND rs.SubscriptionID = s.SubscriptionID
                JOIN dbo.Schedule AS sh ON sh.ScheduleID = rs.ScheduleID
        GROUP BY CASE WHEN pos = 0
                           AND CHARINDEX(';', parm, pos) > 0
                      THEN SUBSTRING(parm, pos + 1,
                                     CHARINDEX(';', parm, pos) - 1)
                      WHEN pos = 0
                           AND CHARINDEX(';', parm, pos) = 0 THEN parm
                      ELSE SUBSTRING(parm, pos + 1, CHARINDEX(';', parm, pos))
                 END
        ORDER BY SUM(CASE WHEN s.DataSettings IS NULL THEN 0
                          ELSE 1
                     END) DESC ,
                CASE WHEN pos = 0
                          AND CHARINDEX(';', parm, pos) > 0
                     THEN SUBSTRING(parm, pos + 1,
                                    CHARINDEX(';', parm, pos) - 1)
                     WHEN pos = 0
                          AND CHARINDEX(';', parm, pos) = 0 THEN parm
                     ELSE SUBSTRING(parm, pos + 1, CHARINDEX(';', parm, pos))
                END


				/* Add credits for the nice folks who put so much time into building and maintaining this for free: */
				INSERT  INTO #BlitzRSResults
						( CheckID ,
						  Priority ,
						  FindingsGroup ,
						  Finding ,
						  URL ,
						  Details
						)
				VALUES  ( -1 ,
						  255 ,
						  'Thanks!' ,
						  'From Brent Ozar Unlimited' ,
						  'http://www.BrentOzar.com/blitzrs/' ,
						  'Thanks from the Brent Ozar Unlimited team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'
						);



SELECT  [Priority] ,
        FindingsGroup ,
        Finding ,
        URL ,
        Details,
		CheckID
FROM    #BlitzRSResults
ORDER BY [Priority] ,
        FindingsGroup ,
        Finding


IF @WhoGetsWhat = 1
	SELECT 
	p.SubscriptionID
	, s.[Description] as SubscriptionName
	, c.[Name] as ReportName
	, sh.Name as ScheduleName
	, sh.LastRunTime
	, s.LastStatus
	, sh.NextRunTime
	, CASE WHEN pos = 0 AND CHARINDEX(';', parm, pos) > 0 THEN SUBSTRING(parm, pos + 1, CHARINDEX(';', parm, pos) -1)
		 WHEN pos = 0 AND CHARINDEX(';', parm, pos) = 0 THEN parm
		 ELSE SUBSTRING(parm, pos + 1, CHARINDEX(';', parm, pos)) 
		 END AS EmailAddress
	, CASE WHEN s.DataSettings IS NULL THEN 0 ELSE 1 END AS IsDataDrivenSubscription
	FROM #parms as p
	JOIN dbo.Subscriptions as s on s.SubscriptionID = p.SubscriptionID
	join dbo.Catalog as c on c.ItemID = s.Report_OID
	JOIN dbo.ReportSchedule as rs on rs.ReportID = s.Report_OID AND rs.SubscriptionID = s.SubscriptionID
	join dbo.Schedule as sh on sh.ScheduleID = rs.ScheduleID
	ORDER BY EmailAddress, p.SubscriptionID  

END
GO




/*
-- Welcome to the beta release of sp_BlitzTrace (TM) -- Version 0.2, released 2015-01-03
-- BrentOzar.com/BlitzTrace
-- Things you can do....

--List running sessions
exec sp_BlitzTrace @Action='start';

--Start a trace for a session. You specify the @SessionID and @TargetPath
exec sp_BlitzTrace @SessionId=52, @TargetPath='S:\XEvents\Traces\', @Action='start';

--Stop a session
exec sp_BlitzTrace @Action='stop';

--Read the results. You can move the files to another server and read there by specifying a @TargetPath.
exec sp_BlitzTrace @Action='read';

--Drop the session. This does NOT delete files created in @TargetPath.
exec sp_BlitzTrace @Action='drop';
*/

IF OBJECT_ID('tempdb..##sp_BlitzTrace') IS NOT NULL
    DROP PROCEDURE ##sp_BlitzTrace
GO
CREATE PROCEDURE ##sp_BlitzTrace
    @Debug BIT = 0 , /* 1 prints the statement and won't execute it */
    @SessionId INT = NULL ,
    @Action VARCHAR(5) = NULL ,  /* 'start', 'read', 'stop', 'drop'*/
    @TargetPath VARCHAR(528) = NULL,  /* Required for 'start'. 'Read' will look for a running sp_BlitzTrace session if not specified.*/
    @TraceRecompiles BIT = 1,
    @TraceObjectCreates BIT = 1,
    @TraceParallelism BIT = 1,
    @TraceSortWarnings BIT = 1,
    @TraceStatements BIT = 0,
    @MaxFileSizeMB INT = 256,
    @TraceExecutionPlansAndKillMyPerformance BIT = 0, /* Non-production environments only */
    @MaxRolloverFiles INT = 4,
    @MaxDispatchLatencySeconds INT = 5 /* 0 is unlimited! */

WITH RECOMPILE
AS
    /* (c) 2014 Brent Ozar Unlimited (R) */
    /* See http://BrentOzar.com/go/eula for the End User License Agreement */

    DECLARE @nl NVARCHAR(2) = NCHAR(13) + NCHAR(10) ;

    RAISERROR (N'*******************START HERE*******************',0,1) WITH NOWAIT;
    RAISERROR (N'(c) 2014 Brent Ozar Unlimited (R).',0,1) WITH NOWAIT;
    RAISERROR (N'See http://BrentOzar.com/go/eula for the End User License Agreement.',0,1) WITH NOWAIT;
    RAISERROR (N'Sp_BlitzTrace version 0.1, released on 2014-11-11.',0,1) WITH NOWAIT;
    RAISERROR (N'*****************Let''s Do This!*****************',0,1) WITH NOWAIT;
    RAISERROR (@nl,0,1) WITH NOWAIT;

    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET XACT_ABORT ON;

BEGIN TRY

    DECLARE @msg NVARCHAR(MAX);
    DECLARE @rowcount INT;
    DECLARE @v decimal(6,2);
    DECLARE @build int;
    DECLARE @datestamp VARCHAR(30);
    DECLARE @TargetPathFull NVARCHAR(MAX);
    DECLARE @filepathXML XML;
    DECLARE @filepath VARCHAR(1024);
    DECLARE @traceexists BIT = 0;
    DECLARE @tracerunning BIT = 0;



    /* Validate parameters */
    SET @msg = CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Validatin'' parameters.'
    RAISERROR (@msg,0,1) WITH NOWAIT;

    IF @Action NOT IN (N'start', N'read', N'stop', N'drop')  OR @Action is NULL
    BEGIN
        RAISERROR (N'You need to specify a valid @Action for sp_BlitzTrace: ''start'', ''read'', ''stop'', or ''drop''.',16,1) WITH NOWAIT;
    END

    IF @Action = N'start' AND @SessionId IS NULL
    BEGIN
        SELECT ses.session_id, con.last_read, con.last_write, ses.login_name, ses.host_name, ses.program_name,
            con.connect_time, con.protocol_type, con.encrypt_option,
            con.num_reads, con.num_writes, con.client_net_address,
            req.status, req.command, req.wait_type, req.last_wait_type, req.open_transaction_count
        FROM sys.dm_exec_sessions as ses
        JOIN sys.dm_exec_connections AS con ON
            con.session_id=ses.session_id
        LEFT JOIN sys.dm_exec_requests AS req ON
            con.session_id=req.session_id
        WHERE
            ses.session_id <> @@SPID
        ORDER BY last_read DESC

        RAISERROR (N'sp_BlitzTrace watches just one session, so you have to specify @SessionId. Check out the session list above for some ideas.',16,1) WITH NOWAIT;
    END

    IF @MaxDispatchLatencySeconds > 99
    BEGIN
        RAISERROR (N'@MaxDispatchLatencySeconds must be 99 or less. 5 is the default. 0 is unlimited latency.',16,1) WITH NOWAIT;
    END

    IF @MaxFileSizeMB > 9999
    BEGIN
        RAISERROR (N'@MaxFileSizeMB must be 9999 or smaller - 256MB is the default.',16,1) WITH NOWAIT;
    END

    IF @MaxRolloverFiles > 99
    BEGIN
        RAISERROR (N'@MaxRolloverFiles must be 99 or smaller. 4 is the default.',16,1) WITH NOWAIT;
    END

    IF @TargetPath IS NULL AND @Action = N'start'
    BEGIN
        RAISERROR (N'You gotta give a valid @TargetPath for ''start''.',16,1) WITH NOWAIT;
    END

    IF @TargetPath IS NOT NULL AND @Action=N'start' AND RIGHT(@TargetPath, 1) <> N'\'
    BEGIN
        RAISERROR (N'@TargetPath must be a directory ending in ''\'', like: ''S:\Xevents\''',16,1) WITH NOWAIT;
    END


    IF @TargetPath IS NOT NULL AND @Action='read' AND  ( RIGHT(@TargetPath, 1) <> '\' AND RIGHT(@TargetPath, 4) <> '.xel')
    BEGIN
        RAISERROR (N'To read, @TargetPath must be a directory ending in ''\'', like: ''S:\XEvents\'', or a file ending in .xel, like ''S:\XEvents\sp_BlitzTrace*.xel''',16,1) WITH NOWAIT;
    END

    /* Validate transaction state */
    SET @msg = CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Validatin'' transaction state.'
    RAISERROR (@msg,0,1) WITH NOWAIT;
    IF @@TRANCOUNT > 0
    BEGIN
        RAISERROR (N'@@TRANCOUNT > 0 not supported',16,1) WITH NOWAIT;
    END

    /* Check version */
    SET @msg = CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Determining SQL Server version.'
    RAISERROR (@msg,0,1) WITH NOWAIT;

    SELECT @v = SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') as NVARCHAR(128)), 1,CHARINDEX('.', CAST(SERVERPROPERTY('ProductVersion') as NVARCHAR(128))) + 1 )

    IF @v < N'11'
    BEGIN
        SET @msg = N'Sad news: most the events sp_BlitzTrace uses are only in SQL Server 2012 and higher-- so it''s not supported on SQL 2008/R2.'
        RAISERROR (@msg,16,1) WITH NOWAIT;
        RETURN;
    END


    /* Get current trace status */
    SELECT
        @traceexists = (CASE WHEN (s.name IS NULL) THEN 0 ELSE 1 END),
        @tracerunning = (CASE WHEN (r.create_time IS NULL) THEN 0 ELSE 1 END)
    FROM sys.server_event_sessions AS s
    LEFT OUTER JOIN sys.dm_xe_sessions AS r ON r.name = s.name
    WHERE s.name=N'sp_BlitzTrace'


    /* We use this to filter sp_BlitzTrace activity out of the results, */
    /* in case you're tracing your own session. */
    /* That's just to make the results less confusing */
    DECLARE @context VARBINARY(128);
    SET @context=CAST('sp_BlitzTrace IS THE BEST' as binary);
    SET CONTEXT_INFO @context;

    IF @Action = N'start'
    BEGIN
        SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Creating extended events trace.'
        RAISERROR (@msg,0,1) WITH NOWAIT;

        IF @traceexists = 1
        BEGIN
            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- A trace named sp_BlitzTrace already exists'
            RAISERROR (@msg,0,1) WITH NOWAIT;

            IF @tracerunning=1
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- sp_BlitzTrace is running, so stopping it before we recreate: ALTER EVENT SESSION sp_BlitzTrace ON SERVER STATE = STOP;'
                RAISERROR (@msg,0,1) WITH NOWAIT;

                ALTER EVENT SESSION sp_BlitzTrace ON SERVER STATE = STOP;

                SET @tracerunning=0;
            END

            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Dropping the trace: DROP EVENT SESSION sp_BlitzTrace ON SERVER; '
            RAISERROR (@msg,0,1) WITH NOWAIT;

            DROP EVENT SESSION sp_BlitzTrace ON SERVER;

            SET @traceexists=0;

        END

        IF @traceexists = 0
        BEGIN
            SELECT @datestamp = REPLACE(REPLACE( CONVERT(VARCHAR(26),getdate(),126),':','-'),'.','')
            SET @TargetPathFull=@TargetPath + N'sp_BlitzTrace-' + @datestamp

            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Target path = ' + @TargetPathFull;
            RAISERROR (@msg,0,1) WITH NOWAIT;


            DECLARE @dsql NVARCHAR(MAX);
            DECLARE @dsql1 NVARCHAR(MAX)=
                N'CREATE EVENT SESSION sp_BlitzTrace ON SERVER
                ' + case @TraceStatements when 1 then + N'
                ADD EVENT sqlserver.sp_statement_completed (
                    ACTION(sqlserver.context_info, sqlserver.sql_text, sqlserver.query_hash, sqlserver.query_plan_hash)
                    WHERE ([sqlserver].[session_id]=('+ CAST(@SessionId as NVARCHAR(6)) + N'))),
                ADD EVENT sqlserver.sql_statement_completed (
                    ACTION(sqlserver.context_info, sqlserver.sql_text, sqlserver.query_hash, sqlserver.query_plan_hash)
                    WHERE ([sqlserver].[session_id]=('+ CAST(@SessionId as NVARCHAR(6)) + N'))),
                ' ELSE N'' END + case @TraceSortWarnings when 1 then N'
                ADD EVENT sqlserver.sort_warning (
                    ACTION(sqlserver.context_info, sqlserver.sql_text, sqlserver.query_hash, sqlserver.query_plan_hash)
                    WHERE ([sqlserver].[session_id]=('+ CAST(@SessionId as NVARCHAR(6)) + N'))),
                ' ELSE N'' END + case @TraceParallelism when 1 then + N'
                ADD EVENT sqlserver.degree_of_parallelism (
                    ACTION(sqlserver.context_info, sqlserver.sql_text, sqlserver.query_hash, sqlserver.query_plan_hash)
                    WHERE ([sqlserver].[session_id]=('+ CAST(@SessionId as NVARCHAR(6)) + N'))),
                ' ELSE N'' END + N'
                ' + case @TraceObjectCreates when 1 then + N'
                ADD EVENT sqlserver.object_created (
                    ACTION(sqlserver.context_info, sqlserver.sql_text, sqlserver.query_hash, sqlserver.query_plan_hash)
                    WHERE ([sqlserver].[session_id]=('+ CAST(@SessionId as NVARCHAR(6)) + N'))),
                ' ELSE N'' END;

            DECLARE @dsql2 NVARCHAR(MAX)=
                N'ADD EVENT sqlserver.sql_batch_completed (
                    ACTION(sqlserver.sql_text, sqlserver.query_hash, sqlserver.query_plan_hash)
                    WHERE ([sqlserver].[session_id]=('+ CAST(@SessionId as NVARCHAR(6)) + N'))),
                ' + case @TraceRecompiles when 1 then + N'
                ADD EVENT sqlserver.sql_statement_recompile (
                    ACTION(sqlserver.context_info, sqlserver.sql_text, sqlserver.query_hash, sqlserver.query_plan_hash)
                    WHERE ([sqlserver].[session_id]=('+ CAST(@SessionId as NVARCHAR(6)) + N'))),
                ' ELSE N'' END
                + case @TraceExecutionPlansAndKillMyPerformance when 1 then + N'
                ADD EVENT sqlserver.query_post_execution_showplan (
                    ACTION(sqlserver.context_info, sqlserver.sql_text, sqlserver.query_hash, sqlserver.query_plan_hash)
                    WHERE ([sqlserver].[session_id]=('+ CAST(@SessionId as NVARCHAR(6)) + N'))),
                ' ELSE N'' END + N'
                ADD EVENT sqlserver.rpc_completed (
                    ACTION(sqlserver.sql_text, sqlserver.query_hash, sqlserver.query_plan_hash)
                    WHERE ([sqlserver].[session_id]=('+ CAST(@SessionId as NVARCHAR(6)) + N')))
                ADD TARGET package0.event_file(SET filename=''' + @TargetPathFull + N''',
                    MAX_FILE_SIZE=(' + CAST(@MaxFileSizeMB AS VARCHAR(4)) + N'),
                    MAX_ROLLOVER_FILES = ' + CAST(@MaxRolloverFiles as VARCHAR(2)) + N')
                WITH (
                    MAX_MEMORY = 128 MB,
                    EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS,
                    MAX_DISPATCH_LATENCY = ' + CAST(@MaxDispatchLatencySeconds AS NVARCHAR(2)) + N' SECONDS,
                    MEMORY_PARTITION_MODE=NONE,
                    TRACK_CAUSALITY=OFF,
                    STARTUP_STATE=OFF)';

            SET @dsql=@dsql1 + @dsql2;

            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Creating trace with dynamic SQL. I REGRET NOTHING!!!'
            RAISERROR (@msg,0,1) WITH NOWAIT;

            IF @Debug=1
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Debug mode, printing but not executing.'
                RAISERROR (@msg,0,1) WITH NOWAIT;

                RAISERROR (@nl,0,1) WITH NOWAIT;

                RAISERROR (@dsql1,0,0) WITH NOWAIT;
                RAISERROR (@dsql2,0,0) WITH NOWAIT;
            END
            ELSE
            BEGIN

                EXEC sp_executesql @dsql;

            END
            SET @traceexists = 1;
        END

        IF @tracerunning = 0
        BEGIN
            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- ALTER EVENT SESSION sp_BlitzTrace ON SERVER STATE = START;'
            RAISERROR (@msg,0,1) WITH NOWAIT;

            IF @Debug=0
            BEGIN
                ALTER EVENT SESSION sp_BlitzTrace ON SERVER STATE = START;

                SET @tracerunning = 1;
            END
            ELSE
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- @Debug=1, not starting trace;'
                RAISERROR (@msg,0,1) WITH NOWAIT;
            END
        END
    END
    IF @Action = 'read'
    BEGIN
        SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Reading, processing, and reporting.'
        RAISERROR (@msg,0,1) WITH NOWAIT;

        IF @traceexists = 0
        BEGIN
            SET @filepath=@TargetPath + N'*.xel';

        END

        /* Figure out the file name for current trace, if it's running */
        if @tracerunning=1
        BEGIN
            SELECT TOP 1 @filepathXML= x.target_data
            FROM sys.dm_xe_sessions as se
            JOIN sys.dm_xe_session_targets as t on
                se.address=t.event_session_address
            CROSS APPLY (SELECT cast(t.target_data as XML) AS target_data) as x
            WHERE se.name=N'sp_BlitzTrace'
            OPTION (RECOMPILE);

            SELECT @filepath=CAST(@filepathXML.query('data(EventFileTarget/File/@name)') AS VARCHAR(1024))
        END
        ELSE /* Figure out the file path for the trace if exists and isn't running */
        BEGIN
            SELECT TOP 1 @filepath=CAST(f.value AS VARCHAR(1024)) + N'*.xel'
            FROM sys.server_event_sessions AS ses
            LEFT OUTER JOIN sys.dm_xe_sessions AS running ON
                running.name = ses.name
            JOIN sys.server_event_session_targets AS t ON
                ses.event_session_id = t.event_session_id
                and t.package = 'package0'
                and t.name='event_file'
                and ses.name='sp_BlitzTrace'
            JOIN sys.dm_xe_objects AS o ON
                t.name = o.name
                AND o.object_type='target'
            JOIN sys.dm_xe_object_columns AS c ON
                t.name = c.object_name AND
                c.column_type = 'customizable' AND
                c.name='filename'
            JOIN sys.server_event_session_fields AS f ON
                t.event_session_id = f.event_session_id AND
                t.target_id = f.object_id
                AND c.name = f.name
        END

        SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Using filepath: ' + @filepath
        RAISERROR (@msg,0,1) WITH NOWAIT;

        IF @Debug = 0
        BEGIN
            CREATE TABLE #sp_BlitzTraceXML (
                event_data XML NOT NULL
            );

            CREATE TABLE #sp_BlitzTraceEvents (
                event_time DATETIME2 NOT NULL,
                event_type NVARCHAR(256) NOT NULL,
                batch_text VARCHAR(MAX) NULL,
                sql_text VARCHAR(MAX) NULL,
                [statement] VARCHAR(MAX) NULL,
                duration_micros INT NULL,
                cpu_micros INT NULL,
                physical_reads INT NULL,
                logical_reads INT NULL,
                writes INT NULL,
                row_count INT NULL,
                result NVARCHAR(256) NULL,
                dop_statement_type SYSNAME NULL,
                dop INT NULL,
                workspace_memory_grant_kb INT NULL,
                object_id INT NULL,
                object_type sysname NULL,
                object_name sysname NULL,
                ddl_phase sysname NULL,
                recompile_cause sysname NULL,
                sort_warning_type VARCHAR(256) NULL,
                query_operation_node_id INT NULL,
                query_hash varchar(256) NULL,
                query_plan_hash varchar(256) NULL,
                estimated_cost bigint NULL,
                [showplan_xml] XML NULL,
                context_info sysname NULL,
                event_data XML NOT NULL
            )

            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Populating #sp_BlitzTraceXML...'
            RAISERROR (@msg,0,1) WITH NOWAIT;

            INSERT #sp_BlitzTraceXML (event_data)
            SELECT
                x.event_data
            FROM  sys.fn_xe_file_target_read_file(@filepath,null,null,null) as xet
            CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as x
            OUTER APPLY x.event_data.nodes('//event') AS y(n) OPTION (RECOMPILE);

            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Started populating #sp_BlitzTraceEvents...'
            RAISERROR (@msg,0,1) WITH NOWAIT;

            INSERT #sp_BlitzTraceEvents (event_time, event_type, batch_text, sql_text, [statement], duration_micros, cpu_micros, physical_reads,
            logical_reads, writes, row_count, result, dop_statement_type, dop, workspace_memory_grant_kb, object_id, object_type,
            object_name, ddl_phase, recompile_cause, sort_warning_type, query_operation_node_id, query_hash, query_plan_hash,
            estimated_cost, [showplan_xml], context_info, event_data)
            SELECT
                DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), n.value('@timestamp', 'datetime2')) AS event_time,
                n.value('@name', 'NVARCHAR(max)') AS event_type,
                n.value('(data[@name="batch_text"]/value)[1]', 'varchar(max)') AS batch_text,
                n.value('(action[@name="sql_text"]/value)[1]', 'varchar(max)') AS sql_text,
                n.value('(data[@name="statement"]/value)[1]', 'varchar(max)') AS [statement],
                n.value('(data[@name="duration"]/value)[1]', 'int') AS duration_micros,
                n.value('(data[@name="cpu_time"]/value)[1]', 'int') AS cpu_micros,
                n.value('(data[@name="physical_reads"]/value)[1]', 'int') AS physical_reads,
                n.value('(data[@name="logical_reads"]/value)[1]', 'int') AS logical_reads,
                n.value('(data[@name="writes"]/value)[1]', 'int') AS writes,
                n.value('(data[@name="row_count"]/value)[1]', 'int') AS row_count,
                n.value('(data[@name="result"]/text)[1]', 'varchar(256)') AS result,

                /* Parallelism */
                n.value('(data[@name="statement_type"]/text)[1]', 'varchar(256)') AS dop_statement_type,
                n.value('(data[@name="dop"]/value)[1]', 'int') AS dop,
                n.value('(data[@name="workspace_memory_grant_kb"]/value)[1]', 'bigint') AS workspace_memory_grant_kb,

                /* Object create comes in pairs, begin and end */
                n.value('(data[@name="object_id"]/value)[1]', 'int') AS [object_id],
                n.value('(data[@name="object_type"]/value)[1]', 'varchar(256)') AS object_type,
                n.value('(data[@name="object_name"]/value)[1]', 'varchar(256)') AS [object_name],
                n.value('(data[@name="ddl_phase"]/value)[1]', 'varchar(256)') AS ddl_phase,

                /* Recompiles */
                n.value('(data[@name="recompile_cause"]/text)[1]', 'varchar(256)') AS recompile_cause,

                /* tempdb spills */
                n.value('(data[@name="sort_warning_type"]/text)[1]', 'varchar(256)') AS sort_warning_type,
                n.value('(data[@name="query_operation_node_id"]/value)[1]', 'varchar(256)') AS query_operation_node_id,

                /* query hash and query plan hash */
                n.value('(action[@name="query_hash"]/value)[1]', 'varchar(256)') AS query_hash,
                n.value('(action[@name="query_plan_hash"]/value)[1]', 'varchar(256)') AS query_plan_hash,

                /* actual execution plan */
                n.value('(data[@name="estimated_cost"]/value)[1]', 'bigint') AS estimated_cost,
                n.query('(data[@name="showplan_xml"]/value/*)[1]') AS [showplan_xml],

                /* Context info, for filtering */
                n.value('(action[@name="context_info"]/value)[1]', 'VARCHAR(MAX)') AS [context_info],
                x.event_data as event_data
            FROM #sp_BlitzTraceXML AS xet
            CROSS APPLY (SELECT CAST(xet.event_data AS XML) AS event_data) as x
            OUTER APPLY x.event_data.nodes('//event') AS y(n)
            OPTION (RECOMPILE);

            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Finished populating #sp_BlitzTraceEvents...'
            RAISERROR (@msg,0,1) WITH NOWAIT;

            SET @rowcount=@@ROWCOUNT;

            IF @rowcount = 0
            BEGIN
                RAISERROR('No rows found in the trace for these events for your session id',0,1) WITH NOWAIT;
            END
            ELSE
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- ' + CAST(@rowcount AS NVARCHAR(20)) + N' rows inserted into #sp_BlitzTraceEvents.'
                RAISERROR (@msg,0,1) WITH NOWAIT;
            END

            CREATE CLUSTERED INDEX cx_spBlitzTrace on #sp_BlitzTraceEvents (event_type, event_time)

            DELETE FROM #sp_BlitzTraceEvents
            WHERE (@SessionId=@@SPID and [context_info] = '73705f426c69747a5472616365204953205448452042455354')
            OR PATINDEX('%sp_BlitzTrace%',batch_text) <> 0
            OR PATINDEX('%sp_BlitzTrace%',sql_text) <> 0
                OPTION (RECOMPILE);

            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Querying sql_batch_completed, rpc_completed, sql_statement_completed, sp_statement_completed...'
            RAISERROR (@msg,0,1) WITH NOWAIT;
            /* sql_batch_completed, rpc_completed */
            SELECT
                event_time,
                event_type,
                batch_text,
                [statement],
                sql_text,
                duration_micros,
                cpu_micros,
                physical_reads,
                logical_reads,
                writes,
                row_count,
                result,
                query_hash,
                query_plan_hash,
                event_data
            FROM #sp_BlitzTraceEvents
            WHERE event_type in (N'sql_batch_completed',N'rpc_completed','sql_statement_completed', 'sp_statement_completed')
            ORDER BY 1;

            IF (SELECT TOP 1 event_time FROM #sp_BlitzTraceEvents WHERE event_type = N'degree_of_parallelism')
                IS NOT NULL
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Querying parallelism and memory grant...'
                RAISERROR (@msg,0,1) WITH NOWAIT;
                /* parallelism and memory grant */
                SELECT
                    event_time,
                    event_type,
                    sql_text,
                    dop_statement_type,
                    dop,
                    workspace_memory_grant_kb,
                    query_hash,
                    query_plan_hash,
                    event_data
                FROM #sp_BlitzTraceEvents
                WHERE event_type = 'degree_of_parallelism'
                  and query_hash <> '0'
                ORDER BY 1;
            END

            IF (SELECT TOP 1 event_time FROM #sp_BlitzTraceEvents WHERE event_type = N'object_created')
                IS NOT NULL
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Querying object_created ...'
                RAISERROR (@msg,0,1) WITH NOWAIT;
                /* object_created */
                SELECT
                    event_time,
                    event_type,
                    sql_text,
                    [object_id],
                    [object_name],
                    cpu_micros,
                    ddl_phase,
                    query_hash,
                    query_plan_hash,
                    event_data
                FROM #sp_BlitzTraceEvents
                WHERE event_type = 'object_created'
                ORDER BY 1;
            END

            IF (SELECT TOP 1 event_time FROM #sp_BlitzTraceEvents WHERE event_type = N'sql_statement_recompile')
                IS NOT NULL
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Querying sql_statement_recompile ...'
                RAISERROR (@msg,0,1) WITH NOWAIT;

                /* sql_statement_recompile */
                SELECT
                    event_time,
                    event_type,
                    sql_text,
                    recompile_cause,
                    query_hash,
                    query_plan_hash,
                    event_data
                FROM #sp_BlitzTraceEvents
                WHERE event_type = 'sql_statement_recompile'
                ORDER BY 1;
            END

            IF (SELECT TOP 1 event_time FROM #sp_BlitzTraceEvents WHERE event_type = N'sort_warning')
                IS NOT NULL
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Querying sort_warning ...'
                RAISERROR (@msg,0,1) WITH NOWAIT;

                /* sql_statement_recompile */
                SELECT
                    event_time,
                    event_type,
                    sort_warning_type,
                    query_operation_node_id,
                    query_hash,
                    query_plan_hash,
                    event_data
                FROM #sp_BlitzTraceEvents
                WHERE event_type = 'sort_warning'
                ORDER BY 1;
            END

            IF (SELECT TOP 1 event_time FROM #sp_BlitzTraceEvents WHERE event_type = N'query_post_execution_showplan')
                IS NOT NULL
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Querying actual execution plans ...'
                RAISERROR (@msg,0,1) WITH NOWAIT;

                /* sql_statement_recompile */
                SELECT
                    event_time,
                    estimated_cost,
                    [object_name],
                    sql_text,
                    [showplan_xml] as [hope_this_isn't_production],
                    event_data
                FROM #sp_BlitzTraceEvents
                WHERE event_type = 'query_post_execution_showplan'
                ORDER BY 1;
            END

        END
        ELSE /* We're in @Debug=1 mode */
        BEGIN
            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- @Debug=1, not reading sp_BlitzTrace Extended Events session files;'
            RAISERROR (@msg,0,1) WITH NOWAIT;
        END
    END

    IF @Action = 'stop'
    BEGIN
        IF @tracerunning = 1
        BEGIN
            IF @Debug = 0
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Stopping sp_BlitzTrace Extended Events session.'
                RAISERROR (@msg,0,1) WITH NOWAIT;

                ALTER EVENT SESSION sp_BlitzTrace ON SERVER STATE = STOP;

                SET @tracerunning = 0;
            END
            ELSE /* @Debug=1 */
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- @Debug=1, sp_BlitzTrace Extended Events session is running but we are NOT stopping it;'
                RAISERROR (@msg,0,1) WITH NOWAIT;
            END
        END
        ELSE
        BEGIN
            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- No running sp_BlitzTrace Extended Events session to stop.'
            RAISERROR (@msg,16,1) WITH NOWAIT;
        END
    END


    IF @Action = 'drop'
    BEGIN
        IF @traceexists = 1
        BEGIN
            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Dropping sp_BlitzTrace Extended Events session.'
            RAISERROR (@msg,0,1) WITH NOWAIT;

            IF @Debug=0
            BEGIN
                DROP EVENT SESSION sp_BlitzTrace ON SERVER;

                SET @traceexists=0;
            END
            ELSE /* @Debug=1 */
            BEGIN
                SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- @Debug=1, sp_BlitzTrace Extended Events session exists but we are NOT dropping it.'
                RAISERROR (@msg,0,1) WITH NOWAIT;
            END
        END
        ELSE
        BEGIN
            SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- No sp_BlitzTrace XEvents trace to drop.'
            RAISERROR (@msg,16,1) WITH NOWAIT;
        END
    END

    RAISERROR (@nl,0,1) WITH NOWAIT;
    RAISERROR (N'********************READ ME!********************',0,1) WITH NOWAIT;


    IF @traceexists = 1 and @tracerunning = 0
    BEGIN
        SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Extended Events session sp_BlitzTrace exists, but is stopped.'
        RAISERROR (@msg,0,1) WITH NOWAIT;

        SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- To drop sp_BlitzTrace, run: exec dbo.sp_BlitzTrace @Action=''drop'';'
        RAISERROR (@msg,0,1) WITH NOWAIT;

    END
    ELSE IF @traceexists = 1 and @tracerunning = 1
    BEGIN
        SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Extended Events session sp_BlitzTrace exists and is running' +
            CASE WHEN @SessionId is not null
               THEN N' for @SessionId=' + cast(@SessionId as NVARCHAR(5))
               ELSE N''
               END
        RAISERROR (@msg,0,1) WITH NOWAIT;

        SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Don''t leave the sp_BlitzTrace session running for long periods!'
        RAISERROR (@msg,0,1) WITH NOWAIT;

        SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- To stop sp_BlitzTrace, run: exec dbo.sp_BlitzTrace @Action=''stop'';'
        RAISERROR (@msg,0,1) WITH NOWAIT;
    END
    ELSE IF @traceexists = 0
    BEGIN
        SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Extended Events session sp_BlitzTrace doesn''t exist, we''re all cleaned up.'
        RAISERROR (@msg,0,1) WITH NOWAIT;
    END

    RAISERROR (N'********************SEE YA********************',0,1) WITH NOWAIT;

    SET CONTEXT_INFO 0x;
END TRY
BEGIN CATCH

    SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Catching error ...'
    RAISERROR (@msg,0,1) WITH NOWAIT;

    SELECT
        ERROR_NUMBER() AS ErrorNumber
        ,ERROR_SEVERITY() AS ErrorSeverity
        ,ERROR_STATE() AS ErrorState
        ,ERROR_PROCEDURE() AS ErrorProcedure
        ,ERROR_LINE() AS ErrorLine
        ,ERROR_MESSAGE() AS ErrorMessage;

    /* Re-check trace status */
    SELECT
        @traceexists = (CASE WHEN (s.name IS NULL) THEN 0 ELSE 1 END),
        @tracerunning = (CASE WHEN (r.create_time IS NULL) THEN 0 ELSE 1 END)
    FROM sys.server_event_sessions AS s
    LEFT OUTER JOIN sys.dm_xe_sessions AS r ON r.name = s.name
    WHERE s.name='sp_BlitzTrace'


    IF @Action='start' and @traceexists=1
    BEGIN
        SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- An error occurred starting the trace. Cleaning it up.'
        RAISERROR (@msg,0,1) WITH NOWAIT;

        DROP EVENT SESSION sp_BlitzTrace ON SERVER;
    END

    SET @msg= CONVERT(NVARCHAR(30), GETDATE(), 126) + N'- Resetting context and we''re outta here.'
    RAISERROR (@msg,0,1) WITH NOWAIT;

    SET CONTEXT_INFO 0x;

END CATCH

GO





IF OBJECT_ID('tempdb..##sp_AskBrent') IS NULL
  EXEC ('CREATE PROCEDURE ##sp_AskBrent AS RETURN 0;')
GO


ALTER PROCEDURE [##sp_AskBrent]
    @Question NVARCHAR(MAX) = NULL ,
    @AsOf DATETIME = NULL ,
    @ExpertMode TINYINT = 0 ,
    @Seconds INT = 5 ,
    @OutputType VARCHAR(20) = 'TABLE' ,
    @OutputDatabaseName NVARCHAR(128) = NULL ,
    @OutputSchemaName NVARCHAR(256) = NULL ,
    @OutputTableName NVARCHAR(256) = NULL ,
    @OutputTableNameFileStats NVARCHAR(256) = NULL ,
    @OutputTableNamePerfmonStats NVARCHAR(256) = NULL ,
    @OutputTableNameWaitStats NVARCHAR(256) = NULL ,
    @OutputXMLasNVARCHAR TINYINT = 0 ,
    @FilterPlansByDatabase VARCHAR(MAX) = NULL ,
    @SkipChecksQueries TINYINT = 1 ,
    @FileLatencyThresholdMS INT = 100 ,
    @Version INT = NULL OUTPUT,
    @VersionDate DATETIME = NULL OUTPUT
    WITH EXECUTE AS CALLER, RECOMPILE
AS 
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

/*
sp_AskBrent (TM)

(C) 2015, Brent Ozar Unlimited. 
See http://BrentOzar.com/go/eula for the End User Licensing Agreement.

Sure, the server needs tuning - but why is it slow RIGHT NOW?
sp_AskBrent performs quick checks for things like:

* Blocking queries that have been running a long time
* Backups, restores, DBCCs
* Recently cleared plan cache
* Transactions that are rolling back

To learn more, visit http://www.BrentOzar.com/askbrent/ where you can download
new versions for free, watch training videos on how it works, get more info on
the findings, and more.  To contribute code and see your name in the change
log, email your improvements & checks to Help@BrentOzar.com.

Known limitations of this version:
 - No support for SQL Server 2000 or compatibility mode 80.
 - If a temp table called #CustomPerfmonCounters exists for any other session,
   but not our session, this stored proc will fail with an error saying the
   temp table #CustomPerfmonCounters doesn't exist.

Unknown limitations of this version:
 - None. Like Zombo.com, the only limit is yourself.

Changes in v13 - Feb 22, 2015
 - Added Server Info output of priority 251 for Total Database Size and Total
   Databases (checks 21 and 22).
 - Added parameters @OutputTableNameFileStats, @OutputTableNamePerfmon, and
   @OutputTableNameWaitStats to persist these work tables to disk if you want
   to examine performance over time. I'd strongly recommend that you buy a
   real monitoring program, though. I'm only storing the second pass of each
   statistic, not the differentials. This is useful for doing your own deltas
   between passes of sp_AskBrent, like running sp_AskBrent every 5 minutes via
   a SQL Server Agent job. You can use any of the @OutputTableName params
   individually, or as a group - it's up to you which data you want to keep.
 - Bug fixes and improvements.

Changes in v12 - Feb 16, 2015
 - Added Server Info output of priority 250 for Batch Requests per Second and
   Wait Time per Core per Second (checks 19 and 20).

Changes in v11 - Nov 20, 2014
 - Jefferson Elias of Belgium added more Perfmon counters to ExpertMode output.
 - Added @FileLatencyThresholdMS to let you set the default read/write warning
   trigger in milliseconds. It's always been 100ms, so that's the default.
 - Added @SkipChecksQueries, defaults to on. Most folks seem to get confused by
   the detailed output of which queries ran the most often during the sample,
   so we're skipping that by default now - which also makes it go faster, too.
 - Bug fixes and improvements.

Changes in v10 - May 22, 2014
 - Added some new SQL 2014 harmless wait stats like 
   QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP.
 - Added ExpertMode columns for more plan cache metrics analysis on the query's
   percentage of the server's load during the sample, plus overall load.
 - Added @OutputType = 'Opserver1' to output results in a format that works
   better for Opserver, the open source monitoring tool of champions. Get it:
   https://github.com/opserver/Opserver
 - Added thresholds to Most Resource-Intensive Queries. Now requires 1000 page
   reads, 1 second of CPU time, or 1 second of duration before queries are
   shown. This prevents the "idle presenter laptop" problem where IntelliSense
   queries show up as resource-intensive.
 - Added DatabaseID, DatabaseName for query plans when ExpertMode = 1.
 - Added @FilterPlansByDatabase. Takes a comma-delimited list of database IDs
   and only looks for resource-intensive plans in those databases. Also takes
   the parameter 'USER' for only user databases.
 - Creation script now defaults to ALTER PROCEDURE instead of CREATE.
 - Raised compilations/sec and recompilations/sec thresholds to 100/sec.

Changes in v9 - Nov 3, 2013
 - Changed date format to accommodate the British. They gave us Gordon Ramsay,
   so it's the least I could do. Many folks reported this one.

Changes in v8 - October 21, 2013
 - Whoops! Left an extra line in check 8 that failed on SQL 2005.

Changes in v7 - October 21, 2013
 - Updated many of the links to point to newly published pages.
 - Performance tuning Check 8 (sleeping connections with open transactions).
   Went from >1 minute at StackExchange to <10 seconds.

Changes in v6 - October 11, 2013
 - Time travel enabled. Can log to database using the @Output* parameters, and
   you can go back in time with the @AsOf parameter.
 - Bug fixing for SQL Server 2005 compatibility.

Changes in v5 - September 16, 2013
 - Enabled @Question again.
 - Bail out of plan cache analysis if we're more than 10 seconds behind.

Changes in v4 - August 25, 2013
 - Added plan cache analysis.
 - Fixed checkid 8 (sleeping query with open transactions) for SQL 2005/08/R2.
 - Refactored a little for readability.
 - Added QueryPlan to the default results because the plan cache stuff is cool.

Changes in v3 - August 23, 2013
 - Added @OutputType = 'SCHEMA', which returns the version number and a list
   of columns for a CREATE TABLE definition for the default outputs. We don't
   include the actual CREATE TABLE part because you might want to use a table
   variable or whatever.
 - Added @OutputXMLasNVARCHAR. If 1, then the QueryPlan is outputted as an
   NVARCHAR(MAX) instead of XML. This helps if you want to insert the
   sp_AskBrent results into a temp table. For instructions, visit:

Changes in v2 - August 9, 2013
 - Added @Seconds to control the sampling time.
 - @ExpertMode now returns all work tables with no thresholds.
 - Added basic wait stats, file stats, Perfmon checks.

Changes in v1 - July 11, 2013
 - Initial bug-filled release. We purposely left extra errors on here so
   you could email bug reports to Help@BrentOzar.com, thereby increasing
   your self-esteem. It's all about you.
*/


SELECT @Version = 13, @VersionDate = '20150222'

DECLARE @StringToExecute NVARCHAR(4000),
	@ParmDefinitions NVARCHAR(4000),
	@Parm1 NVARCHAR(4000),
	@OurSessionID INT,
	@LineFeed NVARCHAR(10),
	@StockWarningHeader NVARCHAR(500),
	@StockWarningFooter NVARCHAR(100),
	@StockDetailsHeader NVARCHAR(100),
	@StockDetailsFooter NVARCHAR(100),
	@StartSampleTime DATETIME,
	@FinishSampleTime DATETIME,
	@ServiceName sysname;

/* Sanitize our inputs */
SELECT
	@OutputDatabaseName = QUOTENAME(@OutputDatabaseName),
	@OutputSchemaName = QUOTENAME(@OutputSchemaName),
	@OutputTableName = QUOTENAME(@OutputTableName),
	@OutputTableNameFileStats = QUOTENAME(@OutputTableNameFileStats),
	@OutputTableNamePerfmonStats = QUOTENAME(@OutputTableNamePerfmonStats),
	@OutputTableNameWaitStats = QUOTENAME(@OutputTableNameWaitStats),
	@LineFeed = CHAR(13) + CHAR(10),
	@StartSampleTime = GETDATE(),
	@FinishSampleTime = DATEADD(ss, @Seconds, GETDATE()),
	@OurSessionID = @@SPID,
	@ServiceName = CASE WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer' ELSE 'MSSQL$' + @@SERVICENAME END;

IF @OutputType = 'SCHEMA'
BEGIN
	SELECT @Version AS Version,
	FieldList = '[Priority] TINYINT, [FindingsGroup] VARCHAR(50), [Finding] VARCHAR(200), [URL] VARCHAR(200), [Details] NVARCHAR(4000), [HowToStopIt] NVARCHAR(MAX), [QueryPlan] XML, [QueryText] NVARCHAR(MAX)'

END
ELSE IF @AsOf IS NOT NULL AND @OutputDatabaseName IS NOT NULL AND @OutputSchemaName IS NOT NULL AND @OutputTableName IS NOT NULL
BEGIN
	/* They want to look into the past. */

		SET @StringToExecute = N' IF EXISTS(SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
			+ @OutputSchemaName + ''') SELECT CheckDate, [Priority], [FindingsGroup], [Finding], [URL], CAST([Details] AS [XML]) AS Details,'
			+ '[HowToStopIt], [CheckID], [StartTime], [LoginName], [NTUserName], [OriginalLoginName], [ProgramName], [HostName], [DatabaseID],'
			+ '[DatabaseName], [OpenTransactionCount], [QueryPlan], [QueryText] FROM '
			+ @OutputDatabaseName + '.'
			+ @OutputSchemaName + '.'
			+ @OutputTableName
			+ ' WHERE CheckDate >= DATEADD(mi, -15, ''' + CAST(@AsOf AS NVARCHAR(100)) + ''')'
			+ ' AND CheckDate <= DATEADD(mi, 15, ''' + CAST(@AsOf AS NVARCHAR(100)) + ''')'
			+ ' /*ORDER BY CheckDate, Priority , FindingsGroup , Finding , Details*/;';
		EXEC(@StringToExecute);


END /* IF @AsOf IS NOT NULL AND @OutputDatabaseName IS NOT NULL AND @OutputSchemaName IS NOT NULL AND @OutputTableName IS NOT NULL */
ELSE IF @Question IS NULL /* IF @OutputType = 'SCHEMA' */
BEGIN


	/*
	We start by creating #AskBrentResults. It's a temp table that will storef
	the results from our checks. Throughout the rest of this stored procedure,
	we're running a series of checks looking for dangerous things inside the SQL
	Server. When we find a problem, we insert rows into #BlitzResults. At the
	end, we return these results to the end user.

	#AskBrentResults has a CheckID field, but there's no Check table. As we do
	checks, we insert data into this table, and we manually put in the CheckID.
	We (Brent Ozar Unlimited) maintain a list of the checks by ID#. You can
	download that from http://www.BrentOzar.com/askbrent/documentation/ if you
	want to build a tool that relies on the output of sp_AskBrent.
	*/

	IF OBJECT_ID('tempdb..#AskBrentResults') IS NOT NULL 
		DROP TABLE #AskBrentResults;
	CREATE TABLE #AskBrentResults
		(
		  ID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
		  CheckID INT NOT NULL,
		  Priority TINYINT NOT NULL,
		  FindingsGroup VARCHAR(50) NOT NULL,
		  Finding VARCHAR(200) NOT NULL,
		  URL VARCHAR(200) NULL,
		  Details NVARCHAR(4000) NULL,
		  HowToStopIt NVARCHAR(MAX) NULL,
		  QueryPlan [XML] NULL,
		  QueryText NVARCHAR(MAX) NULL,
		  StartTime DATETIME NULL,
		  LoginName NVARCHAR(128) NULL,
		  NTUserName NVARCHAR(128) NULL,
		  OriginalLoginName NVARCHAR(128) NULL,
		  ProgramName NVARCHAR(128) NULL,
		  HostName NVARCHAR(128) NULL,
		  DatabaseID INT NULL,
		  DatabaseName NVARCHAR(128) NULL,
		  OpenTransactionCount INT NULL,
          QueryStatsNowID INT NULL,
          QueryStatsFirstID INT NULL,
          PlanHandle VARBINARY(64) NULL,
          DetailsInt INT NULL,
		);

	IF OBJECT_ID('tempdb..#WaitStats') IS NOT NULL 
		DROP TABLE #WaitStats;
	CREATE TABLE #WaitStats (Pass TINYINT NOT NULL, wait_type NVARCHAR(60), wait_time_ms BIGINT, signal_wait_time_ms BIGINT, waiting_tasks_count BIGINT, SampleTime DATETIME);

	IF OBJECT_ID('tempdb..#FileStats') IS NOT NULL 
		DROP TABLE #FileStats;
	CREATE TABLE #FileStats ( 
		ID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
		Pass TINYINT NOT NULL,
		SampleTime DATETIME NOT NULL,
		DatabaseID INT NOT NULL,
		FileID INT NOT NULL,
		DatabaseName NVARCHAR(256) ,
		FileLogicalName NVARCHAR(256) ,
		TypeDesc NVARCHAR(60) ,
		SizeOnDiskMB BIGINT ,
		io_stall_read_ms BIGINT ,
		num_of_reads BIGINT ,
		bytes_read BIGINT ,
		io_stall_write_ms BIGINT ,
		num_of_writes BIGINT ,
		bytes_written BIGINT, 
		PhysicalName NVARCHAR(520) ,
		avg_stall_read_ms INT ,
		avg_stall_write_ms INT
	);

	IF OBJECT_ID('tempdb..#QueryStats') IS NOT NULL 
		DROP TABLE #QueryStats;
	CREATE TABLE #QueryStats ( 
		ID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
		Pass INT NOT NULL,
		SampleTime DATETIME NOT NULL,
		[sql_handle] VARBINARY(64),
		statement_start_offset INT,
		statement_end_offset INT,
		plan_generation_num BIGINT,
		plan_handle VARBINARY(64),
		execution_count BIGINT,
		total_worker_time BIGINT,
		total_physical_reads BIGINT,
		total_logical_writes BIGINT,
		total_logical_reads BIGINT,
		total_clr_time BIGINT,
		total_elapsed_time BIGINT,
		creation_time DATETIME,
		query_hash BINARY(8),
		query_plan_hash BINARY(8),
		Points TINYINT
	);

	IF OBJECT_ID('tempdb..#PerfmonStats') IS NOT NULL 
		DROP TABLE #PerfmonStats;
	CREATE TABLE #PerfmonStats ( 
		ID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
		Pass TINYINT NOT NULL,
		SampleTime DATETIME NOT NULL,
		[object_name] NVARCHAR(128) NOT NULL,
		[counter_name] NVARCHAR(128) NOT NULL,
		[instance_name] NVARCHAR(128) NULL,
		[cntr_value] BIGINT NULL,
		[cntr_type] INT NOT NULL,
		[value_delta] BIGINT NULL,
		[value_per_second] DECIMAL(18,2) NULL
	);

	IF OBJECT_ID('tempdb..#PerfmonCounters') IS NOT NULL 
		DROP TABLE #PerfmonCounters;
	CREATE TABLE #PerfmonCounters ( 
		ID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED,
		[object_name] NVARCHAR(128) NOT NULL,
		[counter_name] NVARCHAR(128) NOT NULL,
		[instance_name] NVARCHAR(128) NULL
	);

	IF OBJECT_ID('tempdb..#FilterPlansByDatabase') IS NOT NULL 
		DROP TABLE #FilterPlansByDatabase;
	CREATE TABLE #FilterPlansByDatabase (DatabaseID INT PRIMARY KEY CLUSTERED);

	IF @FilterPlansByDatabase IS NOT NULL
		BEGIN
		IF UPPER(LEFT(@FilterPlansByDatabase,4)) = 'USER'
			BEGIN
			INSERT INTO #FilterPlansByDatabase (DatabaseID)
			SELECT database_id
				FROM sys.databases
				WHERE [name] NOT IN ('master', 'model', 'msdb', 'tempdb')
			END
		ELSE
			BEGIN
			SET @FilterPlansByDatabase = @FilterPlansByDatabase + ','
			;WITH a AS
				(
				SELECT CAST(1 AS BIGINT) f, CHARINDEX(',', @FilterPlansByDatabase) t, 1 SEQ
				UNION ALL
				SELECT t + 1, CHARINDEX(',', @FilterPlansByDatabase, t + 1), SEQ + 1
				FROM a
				WHERE CHARINDEX(',', @FilterPlansByDatabase, t + 1) > 0
				)
			INSERT #FilterPlansByDatabase (DatabaseID)
				SELECT SUBSTRING(@FilterPlansByDatabase, f, t - f) 
				FROM a
				WHERE SUBSTRING(@FilterPlansByDatabase, f, t - f) IS NOT NULL
				OPTION (MAXRECURSION 0)
			END
		END


	SET @StockWarningHeader = '<?ClickToSeeCommmand -- ' + @LineFeed + @LineFeed 
		+ 'WARNING: Running this command may result in data loss or an outage.' + @LineFeed
		+ 'This tool is meant as a shortcut to help generate scripts for DBAs.' + @LineFeed
		+ 'It is not a substitute for database training and experience.' + @LineFeed
		+ 'Now, having said that, here''s the details:' + @LineFeed + @LineFeed;

	SELECT @StockWarningFooter = @LineFeed + @LineFeed + '-- ?>',
		@StockDetailsHeader = '<?ClickToSeeDetails -- ' + @LineFeed,
		@StockDetailsFooter = @LineFeed + ' -- ?>';

	/* Build a list of queries that were run in the last 10 seconds.
	   We're looking for the death-by-a-thousand-small-cuts scenario
	   where a query is constantly running, and it doesn't have that
	   big of an impact individually, but it has a ton of impact
	   overall. We're going to build this list, and then after we
	   finish our @Seconds sample, we'll compare our plan cache to
	   this list to see what ran the most. */

	/* Populate #QueryStats. SQL 2005 doesn't have query hash or query plan hash. */
	IF @@VERSION LIKE 'Microsoft SQL Server 2005%'
		BEGIN
		IF @FilterPlansByDatabase IS NULL
			BEGIN
			SET @StringToExecute = N'INSERT INTO #QueryStats ([sql_handle], Pass, SampleTime, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, query_hash, query_plan_hash, Points)
										SELECT [sql_handle], 1 AS Pass, GETDATE(), statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, NULL AS query_hash, NULL AS query_plan_hash, 0
										FROM sys.dm_exec_query_stats qs
										WHERE qs.last_execution_time >= (DATEADD(ss, -10, GETDATE()));';
			END
		ELSE
			BEGIN
			SET @StringToExecute = N'INSERT INTO #QueryStats ([sql_handle], Pass, SampleTime, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, query_hash, query_plan_hash, Points)
										SELECT [sql_handle], 1 AS Pass, GETDATE(), statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, NULL AS query_hash, NULL AS query_plan_hash, 0
										FROM sys.dm_exec_query_stats qs
							                CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) AS attr
											INNER JOIN #FilterPlansByDatabase dbs ON CAST(attr.value AS INT) = dbs.DatabaseID
										WHERE qs.last_execution_time >= (DATEADD(ss, -10, GETDATE()))
											AND attr.attribute = ''dbid'';';
			END
		END
	ELSE
		BEGIN
		IF @FilterPlansByDatabase IS NULL
			BEGIN
			SET @StringToExecute = N'INSERT INTO #QueryStats ([sql_handle], Pass, SampleTime, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, query_hash, query_plan_hash, Points)
										SELECT [sql_handle], 1 AS Pass, GETDATE(), statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, query_hash, query_plan_hash, 0
										FROM sys.dm_exec_query_stats qs
										WHERE qs.last_execution_time >= (DATEADD(ss, -10, GETDATE()));';
			END
		ELSE
			BEGIN
			SET @StringToExecute = N'INSERT INTO #QueryStats ([sql_handle], Pass, SampleTime, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, query_hash, query_plan_hash, Points)
										SELECT [sql_handle], 1 AS Pass, GETDATE(), statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, query_hash, query_plan_hash, 0
										FROM sys.dm_exec_query_stats qs
						                CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) AS attr
										INNER JOIN #FilterPlansByDatabase dbs ON CAST(attr.value AS INT) = dbs.DatabaseID
										WHERE qs.last_execution_time >= (DATEADD(ss, -10, GETDATE()))
											AND attr.attribute = ''dbid'';';
			END
		END
	IF @SkipChecksQueries = 0 EXEC(@StringToExecute);

	/* Get the totals for the entire plan cache */
	INSERT INTO #QueryStats (Pass, SampleTime, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time)
	SELECT -1 AS Pass, GETDATE(), SUM(execution_count), SUM(total_worker_time), SUM(total_physical_reads), SUM(total_logical_writes), SUM(total_logical_reads), SUM(total_clr_time), SUM(total_elapsed_time), MIN(creation_time)
		FROM sys.dm_exec_query_stats qs;


	IF EXISTS (SELECT * 
					FROM tempdb.sys.all_objects obj
					INNER JOIN tempdb.sys.all_columns col1 ON obj.object_id = col1.object_id AND col1.name = 'object_name'
					INNER JOIN tempdb.sys.all_columns col2 ON obj.object_id = col2.object_id AND col2.name = 'counter_name'
					INNER JOIN tempdb.sys.all_columns col3 ON obj.object_id = col3.object_id AND col3.name = 'instance_name'
					WHERE obj.name LIKE '%CustomPerfmonCounters%') 
		BEGIN
		SET @StringToExecute = 'INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) SELECT [object_name],[counter_name],[instance_name] FROM #CustomPerfmonCounters'
		EXEC(@StringToExecute);
		END
	ELSE
		BEGIN
		/* Add our default Perfmon counters */
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Forwarded Records/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Page compression attempts/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Page Splits/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Skipped Ghosted Records/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Table Lock Escalations/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Worktables Created/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Page life expectancy', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Page reads/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Page writes/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Readahead pages/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Target pages', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Total pages', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Databases','', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Active Transactions','_Total')
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Databases','Log Growths', '_Total')
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Databases','Log Shrinks', '_Total')
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Exec Statistics','Distributed Query', 'Execs in progress')
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Exec Statistics','DTC calls', 'Execs in progress')
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Exec Statistics','Extended Procedures', 'Execs in progress')
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Exec Statistics','OLEDB calls', 'Execs in progress')
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':General Statistics','Active Temp Tables', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':General Statistics','Logins/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':General Statistics','Logouts/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':General Statistics','Mars Deadlocks', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':General Statistics','Processes blocked', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Locks','Number of Deadlocks/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Memory Manager','Memory Grants Pending', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Errors','Errors/sec', '_Total')
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Statistics','Batch Requests/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Statistics','Forced Parameterizations/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Statistics','Guided plan executions/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Statistics','SQL Attention rate', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Statistics','SQL Compilations/sec', NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Statistics','SQL Re-Compilations/sec', NULL)
		/* Below counters added by Jefferson Elias */
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Worktables From Cache Base',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Worktables From Cache Ratio',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Database pages',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Free pages',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Stolen pages',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Memory Manager','Granted Workspace Memory (KB)',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Memory Manager','Maximum Workspace Memory (KB)',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Memory Manager','Target Server Memory (KB)',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Memory Manager','Total Server Memory (KB)',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Buffer cache hit ratio',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Buffer cache hit ratio base',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Checkpoint pages/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Free list stalls/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Lazy writes/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Statistics','Auto-Param Attempts/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Statistics','Failed Auto-Params/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Statistics','Safe Auto-Params/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':SQL Statistics','Unsafe Auto-Params/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Workfiles Created/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':General Statistics','User Connections',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Latches','Average Latch Wait Time (ms)',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Latches','Average Latch Wait Time Base',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Latches','Latch Waits/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Latches','Total Latch Wait Time (ms)',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Locks','Average Wait Time (ms)',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Locks','Average Wait Time Base',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Locks','Lock Requests/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Locks','Lock Timeouts/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Locks','Lock Wait Time (ms)',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Locks','Lock Waits/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Transactions','Longest Transaction Running Time',NULL)	
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Full Scans/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Access Methods','Index Searches/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Buffer Manager','Page lookups/sec',NULL)
		INSERT INTO #PerfmonCounters ([object_name],[counter_name],[instance_name]) VALUES (@ServiceName + ':Cursor Manager by Type','Active cursors',NULL)
		END

	/* Populate #FileStats, #PerfmonStats, #WaitStats with DMV data. 
		After we finish doing our checks, we'll take another sample and compare them. */
	INSERT #WaitStats(Pass, SampleTime, wait_type, wait_time_ms, signal_wait_time_ms, waiting_tasks_count)
	SELECT
		1 AS Pass,
		GETDATE() AS SampleTime,
		os.wait_type,
		SUM(os.wait_time_ms) OVER (PARTITION BY os.wait_type) as sum_wait_time_ms,
		SUM(os.signal_wait_time_ms) OVER (PARTITION BY os.wait_type ) as sum_signal_wait_time_ms,
		SUM(os.waiting_tasks_count) OVER (PARTITION BY os.wait_type) AS sum_waiting_tasks
	FROM sys.dm_os_wait_stats os
	WHERE os.wait_type not in (
		'REQUEST_FOR_DEADLOCK_SEARCH',
		'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
		'SQLTRACE_BUFFER_FLUSH',
		'LAZYWRITER_SLEEP',
		'XE_TIMER_EVENT',
		'XE_DISPATCHER_WAIT',
		'FT_IFTS_SCHEDULER_IDLE_WAIT',
		'LOGMGR_QUEUE',
		'CHECKPOINT_QUEUE',
		'BROKER_TO_FLUSH',
		'BROKER_TASK_STOP',
		'BROKER_EVENTHANDLER',
		'SLEEP_TASK',
		'WAITFOR',
		'DBMIRROR_DBM_MUTEX',
		'DBMIRROR_EVENTS_QUEUE',
		'DBMIRRORING_CMD',
		'DISPATCHER_QUEUE_SEMAPHORE',
		'BROKER_RECEIVE_WAITFOR',
		'CLR_AUTO_EVENT',
		'DIRTY_PAGE_POLL',
		'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
		'ONDEMAND_TASK_QUEUE',
		'FT_IFTSHC_MUTEX',
		'CLR_MANUAL_EVENT',
		'CLR_SEMAPHORE',
		'DBMIRROR_WORKER_QUEUE',
		'DBMIRROR_DBM_EVENT',
		'SP_SERVER_DIAGNOSTICS_SLEEP',
		'HADR_CLUSAPI_CALL',
		'HADR_LOGCAPTURE_WAIT',
		'HADR_NOTIFICATION_DEQUEUE',
		'HADR_TIMER_TASK',
		'HADR_WORK_QUEUE',
		'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
		'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP'
	)
	ORDER BY sum_wait_time_ms DESC;


	INSERT INTO #FileStats (Pass, SampleTime, DatabaseID, FileID, DatabaseName, FileLogicalName, SizeOnDiskMB, io_stall_read_ms ,
		num_of_reads, [bytes_read] , io_stall_write_ms,num_of_writes, [bytes_written], PhysicalName, TypeDesc)
	SELECT 
		1 AS Pass,
		GETDATE() AS SampleTime,
		mf.[database_id],
		mf.[file_id],
		DB_NAME(vfs.database_id) AS [db_name], 
		mf.name + N' [' + mf.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS + N']' AS file_logical_name ,
		CAST(( ( vfs.size_on_disk_bytes / 1024.0 ) / 1024.0 ) AS INT) AS size_on_disk_mb ,
		vfs.io_stall_read_ms ,
		vfs.num_of_reads ,
		vfs.[num_of_bytes_read],
		vfs.io_stall_write_ms ,
		vfs.num_of_writes ,
		vfs.[num_of_bytes_written],
		mf.physical_name,
		mf.type_desc
	FROM sys.dm_io_virtual_file_stats (NULL, NULL) AS vfs
	INNER JOIN sys.master_files AS mf ON vfs.file_id = mf.file_id
		AND vfs.database_id = mf.database_id
	WHERE vfs.num_of_reads > 0
		OR vfs.num_of_writes > 0;

	INSERT INTO #PerfmonStats (Pass, SampleTime, [object_name],[counter_name],[instance_name],[cntr_value],[cntr_type])
	SELECT 		1 AS Pass,
		GETDATE() AS SampleTime, RTRIM(dmv.object_name), RTRIM(dmv.counter_name), RTRIM(dmv.instance_name), dmv.cntr_value, dmv.cntr_type
		FROM #PerfmonCounters counters
		INNER JOIN sys.dm_os_performance_counters dmv ON counters.counter_name = RTRIM(dmv.counter_name)
			AND counters.[object_name] = RTRIM(dmv.[object_name])
			AND (counters.[instance_name] IS NULL OR counters.[instance_name] = RTRIM(dmv.[instance_name]))

	/* Maintenance Tasks Running - Backup Running - CheckID 1 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, QueryPlan, StartTime, LoginName, NTUserName, ProgramName, HostName, DatabaseID, DatabaseName, OpenTransactionCount)
	SELECT 1 AS CheckID,
		1 AS Priority,
		'Maintenance Tasks Running' AS FindingGroup,
		'Backup Running' AS Finding,
		'http://BrentOzar.com/askbrent/backups/' AS URL,
		'Backup of ' + DB_NAME(db.resource_database_id) + ' database (' + (SELECT CAST(CAST(SUM(size * 8.0 / 1024 / 1024) AS BIGINT) AS NVARCHAR) FROM sys.master_files WHERE database_id = db.resource_database_id) + 'GB) is ' + CAST(r.percent_complete AS NVARCHAR(100)) + '% complete, has been running since ' + CAST(r.start_time AS NVARCHAR(100)) + '. ' AS Details,
		'KILL ' + CAST(r.session_id AS NVARCHAR(100)) + ';' AS HowToStopIt,
		pl.query_plan AS QueryPlan,
		r.start_time AS StartTime,
		s.login_name AS LoginName,
		s.nt_user_name AS NTUserName,
		s.[program_name] AS ProgramName,
		s.[host_name] AS HostName,
		db.[resource_database_id] AS DatabaseID,
		DB_NAME(db.resource_database_id) AS DatabaseName,
		0 AS OpenTransactionCount
	FROM sys.dm_exec_requests r
	INNER JOIN sys.dm_exec_connections c ON r.session_id = c.session_id
	INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
	INNER JOIN (
	SELECT DISTINCT request_session_id, resource_database_id
	FROM    sys.dm_tran_locks
	WHERE resource_type = N'DATABASE'
	AND     request_mode = N'S'
	AND     request_status = N'GRANT'
	AND     request_owner_type = N'SHARED_TRANSACTION_WORKSPACE') AS db ON s.session_id = db.request_session_id
	CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) pl
	WHERE r.command LIKE 'BACKUP%';


	/* If there's a backup running, add details explaining how long full backup has been taking in the last month. */
	UPDATE #AskBrentResults
	SET Details = Details + ' Over the last 60 days, the full backup usually takes ' + CAST((SELECT AVG(DATEDIFF(mi, bs.backup_start_date, bs.backup_finish_date)) FROM msdb.dbo.backupset bs WHERE abr.DatabaseName = bs.database_name AND bs.type = 'D' AND bs.backup_start_date > DATEADD(dd, -60, GETDATE()) AND bs.backup_finish_date IS NOT NULL) AS NVARCHAR(100)) + ' minutes.'
	FROM #AskBrentResults abr
	WHERE abr.CheckID = 1 AND EXISTS (SELECT * FROM msdb.dbo.backupset bs WHERE bs.type = 'D' AND bs.backup_start_date > DATEADD(dd, -60, GETDATE()) AND bs.backup_finish_date IS NOT NULL AND abr.DatabaseName = bs.database_name AND DATEDIFF(mi, bs.backup_start_date, bs.backup_finish_date) > 1)



	/* Maintenance Tasks Running - DBCC Running - CheckID 2 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, QueryPlan, StartTime, LoginName, NTUserName, ProgramName, HostName, DatabaseID, DatabaseName, OpenTransactionCount)
	SELECT 2 AS CheckID,
		1 AS Priority,
		'Maintenance Tasks Running' AS FindingGroup,
		'DBCC Running' AS Finding,
		'http://BrentOzar.com/askbrent/dbcc/' AS URL,
		'Corruption check of ' + DB_NAME(db.resource_database_id) + ' database (' + (SELECT CAST(CAST(SUM(size * 8.0 / 1024 / 1024) AS BIGINT) AS NVARCHAR) FROM sys.master_files WHERE database_id = db.resource_database_id) + 'GB) has been running since ' + CAST(r.start_time AS NVARCHAR(100)) + '. ' AS Details,
		'KILL ' + CAST(r.session_id AS NVARCHAR(100)) + ';' AS HowToStopIt,
		pl.query_plan AS QueryPlan,
		r.start_time AS StartTime,
		s.login_name AS LoginName,
		s.nt_user_name AS NTUserName,
		s.[program_name] AS ProgramName,
		s.[host_name] AS HostName,
		db.[resource_database_id] AS DatabaseID,
		DB_NAME(db.resource_database_id) AS DatabaseName,
		0 AS OpenTransactionCount
	FROM sys.dm_exec_requests r
	INNER JOIN sys.dm_exec_connections c ON r.session_id = c.session_id
	INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
	INNER JOIN (SELECT DISTINCT l.request_session_id, l.resource_database_id
	FROM    sys.dm_tran_locks l
	INNER JOIN sys.databases d ON l.resource_database_id = d.database_id
	WHERE l.resource_type = N'DATABASE'
	AND     l.request_mode = N'S'
	AND    l.request_status = N'GRANT'
	AND    l.request_owner_type = N'SHARED_TRANSACTION_WORKSPACE') AS db ON s.session_id = db.request_session_id
	CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) pl
	WHERE r.command LIKE 'DBCC%';


	/* Maintenance Tasks Running - Restore Running - CheckID 3 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, QueryPlan, StartTime, LoginName, NTUserName, ProgramName, HostName, DatabaseID, DatabaseName, OpenTransactionCount)
	SELECT 3 AS CheckID,
		1 AS Priority,
		'Maintenance Tasks Running' AS FindingGroup,
		'Restore Running' AS Finding,
		'http://BrentOzar.com/askbrent/backups/' AS URL,
		'Restore of ' + DB_NAME(db.resource_database_id) + ' database (' + (SELECT CAST(CAST(SUM(size * 8.0 / 1024 / 1024) AS BIGINT) AS NVARCHAR) FROM sys.master_files WHERE database_id = db.resource_database_id) + 'GB) is ' + CAST(r.percent_complete AS NVARCHAR(100)) + '% complete, has been running since ' + CAST(r.start_time AS NVARCHAR(100)) + '. ' AS Details,
		'KILL ' + CAST(r.session_id AS NVARCHAR(100)) + ';' AS HowToStopIt,
		pl.query_plan AS QueryPlan,
		r.start_time AS StartTime,
		s.login_name AS LoginName,
		s.nt_user_name AS NTUserName,
		s.[program_name] AS ProgramName,
		s.[host_name] AS HostName,
		db.[resource_database_id] AS DatabaseID,
		DB_NAME(db.resource_database_id) AS DatabaseName,
		0 AS OpenTransactionCount
	FROM sys.dm_exec_requests r
	INNER JOIN sys.dm_exec_connections c ON r.session_id = c.session_id
	INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
	INNER JOIN (
	SELECT DISTINCT request_session_id, resource_database_id
	FROM    sys.dm_tran_locks
	WHERE resource_type = N'DATABASE'
	AND     request_mode = N'S'
	AND     request_status = N'GRANT'
	AND     request_owner_type = N'SHARED_TRANSACTION_WORKSPACE') AS db ON s.session_id = db.request_session_id
	CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) pl
	WHERE r.command LIKE 'RESTORE%';


	/* SQL Server Internal Maintenance - Database File Growing - CheckID 4 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, QueryPlan, StartTime, LoginName, NTUserName, ProgramName, HostName, DatabaseID, DatabaseName, OpenTransactionCount)
	SELECT 4 AS CheckID,
		1 AS Priority,
		'SQL Server Internal Maintenance' AS FindingGroup,
		'Database File Growing' AS Finding,
		'http://BrentOzar.com/go/instant' AS URL,
		'SQL Server is waiting for Windows to provide storage space for a database restore, a data file growth, or a log file growth. This task has been running since ' + CAST(r.start_time AS NVARCHAR(100)) + '.' + @LineFeed + 'Check the query plan (expert mode) to identify the database involved.' AS Details,
		'Unfortunately, you can''t stop this, but you can prevent it next time. Check out http://BrentOzar.com/go/instant for details.' AS HowToStopIt,
		pl.query_plan AS QueryPlan,
		r.start_time AS StartTime,
		s.login_name AS LoginName,
		s.nt_user_name AS NTUserName,
		s.[program_name] AS ProgramName,
		s.[host_name] AS HostName,
		NULL AS DatabaseID,
		NULL AS DatabaseName,
		0 AS OpenTransactionCount
	FROM sys.dm_os_waiting_tasks t
	INNER JOIN sys.dm_exec_connections c ON t.session_id = c.session_id
	INNER JOIN sys.dm_exec_requests r ON t.session_id = r.session_id
	INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
	CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) pl
	WHERE t.wait_type = 'PREEMPTIVE_OS_WRITEFILEGATHER'


	/* Query Problems - Long-Running Query Blocking Others - CheckID 5 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, QueryPlan, QueryText, StartTime, LoginName, NTUserName, ProgramName, HostName, DatabaseID, DatabaseName, OpenTransactionCount)
	SELECT 5 AS CheckID,
		1 AS Priority,
		'Query Problems' AS FindingGroup,
		'Long-Running Query Blocking Others' AS Finding,
		'http://BrentOzar.com/go/blocking' AS URL,
		'Query in ' + DB_NAME(db.resource_database_id) + ' has been running since ' + CAST(r.start_time AS NVARCHAR(100)) + '. ' + @LineFeed + @LineFeed
			+ CAST(COALESCE((SELECT TOP 1 [text] FROM sys.dm_exec_sql_text(rBlocker.sql_handle)),
			(SELECT TOP 1 [text] FROM master..sysprocesses spBlocker CROSS APPLY ::fn_get_sql(spBlocker.sql_handle) WHERE spBlocker.spid = tBlocked.blocking_session_id), '') AS NVARCHAR(2000)) AS Details,
		'KILL ' + CAST(tBlocked.blocking_session_id AS NVARCHAR(100)) + ';' AS HowToStopIt,
		(SELECT TOP 1 query_plan FROM sys.dm_exec_query_plan(rBlocker.plan_handle)) AS QueryPlan,
		COALESCE((SELECT TOP 1 [text] FROM sys.dm_exec_sql_text(rBlocker.sql_handle)),
			(SELECT TOP 1 [text] FROM master..sysprocesses spBlocker CROSS APPLY ::fn_get_sql(spBlocker.sql_handle) WHERE spBlocker.spid = tBlocked.blocking_session_id)) AS QueryText,
		r.start_time AS StartTime,
		s.login_name AS LoginName,
		s.nt_user_name AS NTUserName,
		s.[program_name] AS ProgramName,
		s.[host_name] AS HostName,
		db.[resource_database_id] AS DatabaseID,
		DB_NAME(db.resource_database_id) AS DatabaseName,
		0 AS OpenTransactionCount
	FROM sys.dm_exec_sessions s
	INNER JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
	INNER JOIN sys.dm_exec_connections c ON s.session_id = c.session_id
	INNER JOIN sys.dm_os_waiting_tasks tBlocked ON tBlocked.session_id = s.session_id AND tBlocked.session_id <> s.session_id
	INNER JOIN (
	SELECT DISTINCT request_session_id, resource_database_id
	FROM    sys.dm_tran_locks
	WHERE resource_type = N'DATABASE'
	AND     request_mode = N'S'
	AND     request_status = N'GRANT'
	AND     request_owner_type = N'SHARED_TRANSACTION_WORKSPACE') AS db ON s.session_id = db.request_session_id
	LEFT OUTER JOIN sys.dm_exec_requests rBlocker ON tBlocked.blocking_session_id = rBlocker.session_id
	  WHERE NOT EXISTS (SELECT * FROM sys.dm_os_waiting_tasks tBlocker WHERE tBlocker.session_id = tBlocked.blocking_session_id AND tBlocker.blocking_session_id IS NOT NULL)
	  AND s.last_request_start_time < DATEADD(SECOND, -30, GETDATE())

	/* Query Problems - Plan Cache Erased Recently */
	IF DATEADD(mi, -15, GETDATE()) < (SELECT TOP 1 creation_time FROM sys.dm_exec_query_stats ORDER BY creation_time)
	BEGIN
		INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt)
		SELECT TOP 1 7 AS CheckID,
			50 AS Priority,
			'Query Problems' AS FindingGroup,
			'Plan Cache Erased Recently' AS Finding,
			'http://BrentOzar.com/askbrent/plan-cache-erased-recently/' AS URL,
			'The oldest query in the plan cache was created at ' + CAST(creation_time AS NVARCHAR(50)) + '. ' + @LineFeed + @LineFeed
				+ 'This indicates that someone ran DBCC FREEPROCCACHE at that time,' + @LineFeed
				+ 'Giving SQL Server temporary amnesia. Now, as queries come in,' + @LineFeed
				+ 'SQL Server has to use a lot of CPU power in order to build execution' + @LineFeed
				+ 'plans and put them in cache again. This causes high CPU loads.' AS Details,
			'Find who did that, and stop them from doing it again.' AS HowToStopIt
		FROM sys.dm_exec_query_stats 
		ORDER BY creation_time	
	END;


	/* Query Problems - Sleeping Query with Open Transactions - CheckID 8 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, StartTime, LoginName, NTUserName, ProgramName, HostName, DatabaseID, DatabaseName, QueryText, OpenTransactionCount)
	SELECT 8 AS CheckID,
		50 AS Priority,
		'Query Problems' AS FindingGroup,
		'Sleeping Query with Open Transactions' AS Finding,
		'http://www.brentozar.com/askbrent/sleeping-query-with-open-transactions/' AS URL,
		'Database: ' + DB_NAME(db.resource_database_id) + @LineFeed + 'Host: ' + s.[host_name] + @LineFeed + 'Program: ' + s.[program_name] + @LineFeed + 'Asleep with open transactions and locks since ' + CAST(s.last_request_end_time AS NVARCHAR(100)) + '. ' AS Details,
		'KILL ' + CAST(s.session_id AS NVARCHAR(100)) + ';' AS HowToStopIt,
		s.last_request_start_time AS StartTime,
		s.login_name AS LoginName,
		s.nt_user_name AS NTUserName,
		s.[program_name] AS ProgramName,
		s.[host_name] AS HostName,
		db.[resource_database_id] AS DatabaseID,
		DB_NAME(db.resource_database_id) AS DatabaseName,
		(SELECT TOP 1 [text] FROM sys.dm_exec_sql_text(c.most_recent_sql_handle)) AS QueryText,
		sessions_with_transactions.open_transaction_count AS OpenTransactionCount
	FROM (SELECT session_id, SUM(open_transaction_count) AS open_transaction_count FROM sys.dm_exec_requests WHERE open_transaction_count > 0 GROUP BY session_id) AS sessions_with_transactions
	INNER JOIN sys.dm_exec_sessions s ON sessions_with_transactions.session_id = s.session_id
	INNER JOIN sys.dm_exec_connections c ON s.session_id = c.session_id
	INNER JOIN (
	SELECT DISTINCT request_session_id, resource_database_id
	FROM    sys.dm_tran_locks
	WHERE resource_type = N'DATABASE'
	AND     request_mode = N'S'
	AND     request_status = N'GRANT'
	AND     request_owner_type = N'SHARED_TRANSACTION_WORKSPACE') AS db ON s.session_id = db.request_session_id
	WHERE s.status = 'sleeping'
	AND s.last_request_end_time < DATEADD(ss, -10, GETDATE())
	AND EXISTS(SELECT * FROM sys.dm_tran_locks WHERE request_session_id = s.session_id 
	AND NOT (resource_type = N'DATABASE' AND request_mode = N'S' AND request_status = N'GRANT' AND request_owner_type = N'SHARED_TRANSACTION_WORKSPACE'))


	/* Query Problems - Query Rolling Back - CheckID 9 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, StartTime, LoginName, NTUserName, ProgramName, HostName, DatabaseID, DatabaseName, QueryText)
	SELECT 9 AS CheckID,
		1 AS Priority,
		'Query Problems' AS FindingGroup,
		'Query Rolling Back' AS Finding,
		'http://BrentOzar.com/askbrent/rollback/' AS URL,
		'Rollback started at ' + CAST(r.start_time AS NVARCHAR(100)) + ', is ' + CAST(r.percent_complete AS NVARCHAR(100)) + '% complete.' AS Details,
		'Unfortunately, you can''t stop this. Whatever you do, don''t restart the server in an attempt to fix it - SQL Server will keep rolling back.' AS HowToStopIt,
		r.start_time AS StartTime,
		s.login_name AS LoginName,
		s.nt_user_name AS NTUserName,
		s.[program_name] AS ProgramName,
		s.[host_name] AS HostName,
		db.[resource_database_id] AS DatabaseID,
		DB_NAME(db.resource_database_id) AS DatabaseName,
		(SELECT TOP 1 [text] FROM sys.dm_exec_sql_text(c.most_recent_sql_handle)) AS QueryText
	FROM sys.dm_exec_sessions s 
	INNER JOIN sys.dm_exec_connections c ON s.session_id = c.session_id
	INNER JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
	LEFT OUTER JOIN (
		SELECT DISTINCT request_session_id, resource_database_id
		FROM    sys.dm_tran_locks
		WHERE resource_type = N'DATABASE'
		AND     request_mode = N'S'
		AND     request_status = N'GRANT'
		AND     request_owner_type = N'SHARED_TRANSACTION_WORKSPACE') AS db ON s.session_id = db.request_session_id
	WHERE r.status = 'rollback'


	/* Server Performance - Page Life Expectancy Low - CheckID 10 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt)
	SELECT 10 AS CheckID,
		50 AS Priority,
		'Server Performance' AS FindingGroup,
		'Page Life Expectancy Low' AS Finding,
		'http://BrentOzar.com/askbrent/page-life-expectancy/' AS URL,
		'SQL Server Buffer Manager:Page life expectancy is ' + CAST(c.cntr_value AS NVARCHAR(10)) + ' seconds.' + @LineFeed 
			+ 'This means SQL Server can only keep data pages in memory for that many seconds after reading those pages in from storage.' + @LineFeed 
			+ 'This is a symptom, not a cause - it indicates very read-intensive queries that need an index, or insufficient server memory.' AS Details,
		'Add more memory to the server, or find the queries reading a lot of data, and make them more efficient (or fix them with indexes).' AS HowToStopIt
	FROM sys.dm_os_performance_counters c
	WHERE object_name LIKE 'SQLServer:Buffer Manager%'
	AND counter_name LIKE 'Page life expectancy%'
	AND cntr_value < 300

	/* Server Info - Database Size, Total GB - CheckID 21 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, Details, DetailsInt, URL)
	SELECT 21 AS CheckID,
		251 AS Priority,
		'Server Info' AS FindingGroup,
		'Database Size, Total GB' AS Finding,
		CAST(CAST(SUM (size)*8./1024./1024. AS BIGINT) AS VARCHAR(100)) AS Details,
        SUM (size)*8./1024./1024. AS DetailsInt,
        'http://www.BrentOzar.com/askbrent/' AS URL
	FROM sys.master_files
	WHERE database_id > 4

	/* Server Info - Database Count - CheckID 22 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, Details, DetailsInt, URL)
	SELECT 22 AS CheckID,
		251 AS Priority,
		'Server Info' AS FindingGroup,
		'Database Count' AS Finding,
		CAST(SUM(1) AS VARCHAR(100)) AS Details,
        SUM (1) AS DetailsInt,
        'http://www.BrentOzar.com/askbrent/' AS URL
	FROM sys.databases
	WHERE database_id > 4

	/* End of checks. If we haven't waited @Seconds seconds, wait. */
	IF GETDATE() < @FinishSampleTime
		WAITFOR TIME @FinishSampleTime;


	/* Populate #FileStats, #PerfmonStats, #WaitStats with DMV data. In a second, we'll compare these. */
	INSERT #WaitStats(Pass, SampleTime, wait_type, wait_time_ms, signal_wait_time_ms, waiting_tasks_count)
	SELECT
		2 AS Pass,
		GETDATE() AS SampleTime,
		os.wait_type,
		SUM(os.wait_time_ms) OVER (PARTITION BY os.wait_type) as sum_wait_time_ms,
		SUM(os.signal_wait_time_ms) OVER (PARTITION BY os.wait_type ) as sum_signal_wait_time_ms,
		SUM(os.waiting_tasks_count) OVER (PARTITION BY os.wait_type) AS sum_waiting_tasks
	FROM sys.dm_os_wait_stats os
	WHERE os.wait_type not in (
		'REQUEST_FOR_DEADLOCK_SEARCH',
		'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
		'SQLTRACE_BUFFER_FLUSH',
		'LAZYWRITER_SLEEP',
		'XE_TIMER_EVENT',
		'XE_DISPATCHER_WAIT',
		'FT_IFTS_SCHEDULER_IDLE_WAIT',
		'LOGMGR_QUEUE',
		'CHECKPOINT_QUEUE',
		'BROKER_TO_FLUSH',
		'BROKER_TASK_STOP',
		'BROKER_EVENTHANDLER',
		'SLEEP_TASK',
		'WAITFOR',
		'DBMIRROR_DBM_MUTEX',
		'DBMIRROR_EVENTS_QUEUE',
		'DBMIRRORING_CMD',
		'DISPATCHER_QUEUE_SEMAPHORE',
		'BROKER_RECEIVE_WAITFOR',
		'CLR_AUTO_EVENT',
		'DIRTY_PAGE_POLL',
		'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
		'ONDEMAND_TASK_QUEUE',
		'FT_IFTSHC_MUTEX',
		'CLR_MANUAL_EVENT',
		'CLR_SEMAPHORE',
		'DBMIRROR_WORKER_QUEUE',
		'DBMIRROR_DBM_EVENT',
		'SP_SERVER_DIAGNOSTICS_SLEEP',
		'HADR_CLUSAPI_CALL',
		'HADR_LOGCAPTURE_WAIT',
		'HADR_NOTIFICATION_DEQUEUE',
		'HADR_TIMER_TASK',
		'HADR_WORK_QUEUE',
		'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
		'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP'
	)
	ORDER BY sum_wait_time_ms DESC;

	INSERT INTO #FileStats (Pass, SampleTime, DatabaseID, FileID, DatabaseName, FileLogicalName, SizeOnDiskMB, io_stall_read_ms ,
		num_of_reads, [bytes_read] , io_stall_write_ms,num_of_writes, [bytes_written], PhysicalName, TypeDesc, avg_stall_read_ms, avg_stall_write_ms)
	SELECT 		2 AS Pass,
		GETDATE() AS SampleTime,
		mf.[database_id],
		mf.[file_id],
		DB_NAME(vfs.database_id) AS [db_name], 
		mf.name + N' [' + mf.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS + N']' AS file_logical_name ,
		CAST(( ( vfs.size_on_disk_bytes / 1024.0 ) / 1024.0 ) AS INT) AS size_on_disk_mb ,
		vfs.io_stall_read_ms ,
		vfs.num_of_reads ,
		vfs.[num_of_bytes_read],
		vfs.io_stall_write_ms ,
		vfs.num_of_writes ,
		vfs.[num_of_bytes_written],
		mf.physical_name,
		mf.type_desc,
		0,
		0
	FROM sys.dm_io_virtual_file_stats (NULL, NULL) AS vfs
	INNER JOIN sys.master_files AS mf ON vfs.file_id = mf.file_id
		AND vfs.database_id = mf.database_id
	WHERE vfs.num_of_reads > 0
		OR vfs.num_of_writes > 0;

	INSERT INTO #PerfmonStats (Pass, SampleTime, [object_name],[counter_name],[instance_name],[cntr_value],[cntr_type])
	SELECT 		2 AS Pass,
		GETDATE() AS SampleTime,
		RTRIM(dmv.object_name), RTRIM(dmv.counter_name), RTRIM(dmv.instance_name), dmv.cntr_value, dmv.cntr_type
		FROM #PerfmonCounters counters
		INNER JOIN sys.dm_os_performance_counters dmv ON counters.counter_name = RTRIM(dmv.counter_name)
			AND counters.[object_name] = RTRIM(dmv.[object_name])
			AND (counters.[instance_name] IS NULL OR counters.[instance_name] = RTRIM(dmv.[instance_name]))

	/* Set the latencies and averages. We could do this with a CTE, but we're not ambitious today. */
	UPDATE fNow
	SET avg_stall_read_ms = ((fNow.io_stall_read_ms - fBase.io_stall_read_ms) / (fNow.num_of_reads - fBase.num_of_reads))
	FROM #FileStats fNow
	INNER JOIN #FileStats fBase ON fNow.DatabaseID = fBase.DatabaseID AND fNow.FileID = fBase.FileID AND fNow.SampleTime > fBase.SampleTime AND fNow.num_of_reads > fBase.num_of_reads AND fNow.io_stall_read_ms > fBase.io_stall_read_ms
	WHERE (fNow.num_of_reads - fBase.num_of_reads) > 0

	UPDATE fNow
	SET avg_stall_write_ms = ((fNow.io_stall_write_ms - fBase.io_stall_write_ms) / (fNow.num_of_writes - fBase.num_of_writes))
	FROM #FileStats fNow
	INNER JOIN #FileStats fBase ON fNow.DatabaseID = fBase.DatabaseID AND fNow.FileID = fBase.FileID AND fNow.SampleTime > fBase.SampleTime AND fNow.num_of_writes > fBase.num_of_writes AND fNow.io_stall_write_ms > fBase.io_stall_write_ms
	WHERE (fNow.num_of_writes - fBase.num_of_writes) > 0

	UPDATE pNow
		SET [value_delta] = pNow.cntr_value - pFirst.cntr_value,
			[value_per_second] = ((1.0 * pNow.cntr_value - pFirst.cntr_value) / DATEDIFF(ss, pFirst.SampleTime, pNow.SampleTime)) 
		FROM #PerfmonStats pNow
			INNER JOIN #PerfmonStats pFirst ON pFirst.[object_name] = pNow.[object_name] AND pFirst.counter_name = pNow.counter_name AND (pFirst.instance_name = pNow.instance_name OR (pFirst.instance_name IS NULL AND pNow.instance_name IS NULL))
				AND pNow.ID > pFirst.ID;


	/* If we're within 10 seconds of our projected finish time, do the plan cache analysis. */
	IF DATEDIFF(ss, @FinishSampleTime, GETDATE()) > 10 AND @ExpertMode = 0
		BEGIN
		
			INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			VALUES (18, 210, 'Query Stats', 'Plan Cache Analysis Skipped', 'http://BrentOzar.com/go/topqueries',
				'Due to excessive load, the plan cache analysis was skipped. To override this, use @ExpertMode = 1.')
		
		END
	ELSE /* IF DATEDIFF(ss, @FinishSampleTime, GETDATE()) > 10 AND @ExpertMode = 0 */
		BEGIN


		/* Populate #QueryStats. SQL 2005 doesn't have query hash or query plan hash. */
		IF @@VERSION LIKE 'Microsoft SQL Server 2005%'
			SET @StringToExecute = N'INSERT INTO #QueryStats ([sql_handle], Pass, SampleTime, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, query_hash, query_plan_hash, Points)
										SELECT [sql_handle], 2 AS Pass, GETDATE(), statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, NULL AS query_hash, NULL AS query_plan_hash, 0
										FROM sys.dm_exec_query_stats qs
										WHERE qs.last_execution_time >= @StartSampleTimeText;';
		ELSE
			SET @StringToExecute = N'INSERT INTO #QueryStats ([sql_handle], Pass, SampleTime, statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, query_hash, query_plan_hash, Points)
										SELECT [sql_handle], 2 AS Pass, GETDATE(), statement_start_offset, statement_end_offset, plan_generation_num, plan_handle, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time, query_hash, query_plan_hash, 0
										FROM sys.dm_exec_query_stats qs
										WHERE qs.last_execution_time >= @StartSampleTimeText;';
		SET @ParmDefinitions = N'@StartSampleTimeText NVARCHAR(100)';
		SET @Parm1 = CAST(@StartSampleTime AS NVARCHAR(100));
		EXECUTE sp_executesql @StringToExecute, @ParmDefinitions, @StartSampleTimeText = @Parm1;
		
		/* Get the totals for the entire plan cache */
		INSERT INTO #QueryStats (Pass, SampleTime, execution_count, total_worker_time, total_physical_reads, total_logical_writes, total_logical_reads, total_clr_time, total_elapsed_time, creation_time)
		SELECT 0 AS Pass, GETDATE(), SUM(execution_count), SUM(total_worker_time), SUM(total_physical_reads), SUM(total_logical_writes), SUM(total_logical_reads), SUM(total_clr_time), SUM(total_elapsed_time), MIN(creation_time)
			FROM sys.dm_exec_query_stats qs;

		/* 
		Pick the most resource-intensive queries to review. Update the Points field
		in #QueryStats - if a query is in the top 10 for logical reads, CPU time,
		duration, or execution, add 1 to its points.
		*/
		WITH qsTop AS (
		SELECT TOP 10 qsNow.ID
		FROM #QueryStats qsNow
		  INNER JOIN #QueryStats qsFirst ON qsNow.[sql_handle] = qsFirst.[sql_handle] AND qsNow.statement_start_offset = qsFirst.statement_start_offset AND qsNow.statement_end_offset = qsFirst.statement_end_offset AND qsNow.plan_generation_num = qsFirst.plan_generation_num AND qsNow.plan_handle = qsFirst.plan_handle AND qsFirst.Pass = 1
		WHERE qsNow.total_elapsed_time > qsFirst.total_elapsed_time
			AND qsNow.Pass = 2
			AND qsNow.total_elapsed_time - qsFirst.total_elapsed_time > 1000000 /* Only queries with over 1 second of runtime */
		ORDER BY (qsNow.total_elapsed_time - COALESCE(qsFirst.total_elapsed_time, 0)) DESC)
		UPDATE #QueryStats
			SET Points = Points + 1
			FROM #QueryStats qs
			INNER JOIN qsTop ON qs.ID = qsTop.ID;

		WITH qsTop AS (
		SELECT TOP 10 qsNow.ID
		FROM #QueryStats qsNow
		  INNER JOIN #QueryStats qsFirst ON qsNow.[sql_handle] = qsFirst.[sql_handle] AND qsNow.statement_start_offset = qsFirst.statement_start_offset AND qsNow.statement_end_offset = qsFirst.statement_end_offset AND qsNow.plan_generation_num = qsFirst.plan_generation_num AND qsNow.plan_handle = qsFirst.plan_handle AND qsFirst.Pass = 1
		WHERE qsNow.total_logical_reads > qsFirst.total_logical_reads
			AND qsNow.Pass = 2
			AND qsNow.total_logical_reads - qsFirst.total_logical_reads > 1000 /* Only queries with over 1000 reads */
		ORDER BY (qsNow.total_logical_reads - COALESCE(qsFirst.total_logical_reads, 0)) DESC)
		UPDATE #QueryStats
			SET Points = Points + 1
			FROM #QueryStats qs
			INNER JOIN qsTop ON qs.ID = qsTop.ID;

		WITH qsTop AS (
		SELECT TOP 10 qsNow.ID
		FROM #QueryStats qsNow
		  INNER JOIN #QueryStats qsFirst ON qsNow.[sql_handle] = qsFirst.[sql_handle] AND qsNow.statement_start_offset = qsFirst.statement_start_offset AND qsNow.statement_end_offset = qsFirst.statement_end_offset AND qsNow.plan_generation_num = qsFirst.plan_generation_num AND qsNow.plan_handle = qsFirst.plan_handle AND qsFirst.Pass = 1
		WHERE qsNow.total_worker_time > qsFirst.total_worker_time
			AND qsNow.Pass = 2
			AND qsNow.total_worker_time - qsFirst.total_worker_time > 1000000 /* Only queries with over 1 second of worker time */
		ORDER BY (qsNow.total_worker_time - COALESCE(qsFirst.total_worker_time, 0)) DESC)
		UPDATE #QueryStats
			SET Points = Points + 1
			FROM #QueryStats qs
			INNER JOIN qsTop ON qs.ID = qsTop.ID;

		WITH qsTop AS (
		SELECT TOP 10 qsNow.ID
		FROM #QueryStats qsNow
		  INNER JOIN #QueryStats qsFirst ON qsNow.[sql_handle] = qsFirst.[sql_handle] AND qsNow.statement_start_offset = qsFirst.statement_start_offset AND qsNow.statement_end_offset = qsFirst.statement_end_offset AND qsNow.plan_generation_num = qsFirst.plan_generation_num AND qsNow.plan_handle = qsFirst.plan_handle AND qsFirst.Pass = 1
		WHERE qsNow.execution_count > qsFirst.execution_count
			AND qsNow.Pass = 2
			AND (qsNow.total_elapsed_time - qsFirst.total_elapsed_time > 1000000 /* Only queries with over 1 second of runtime */
				OR qsNow.total_logical_reads - qsFirst.total_logical_reads > 1000 /* Only queries with over 1000 reads */
				OR qsNow.total_worker_time - qsFirst.total_worker_time > 1000000 /* Only queries with over 1 second of worker time */)
		ORDER BY (qsNow.execution_count - COALESCE(qsFirst.execution_count, 0)) DESC)
		UPDATE #QueryStats
			SET Points = Points + 1
			FROM #QueryStats qs
			INNER JOIN qsTop ON qs.ID = qsTop.ID;

		/* Query Stats - CheckID 17 - Most Resource-Intensive Queries */
		INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, QueryPlan, QueryText, QueryStatsNowID, QueryStatsFirstID, PlanHandle)
		SELECT 17, 210, 'Query Stats', 'Most Resource-Intensive Queries', 'http://BrentOzar.com/go/topqueries',
			'Query stats during the sample:' + @LineFeed +
			'Executions: ' + CAST(qsNow.execution_count - (COALESCE(qsFirst.execution_count, 0)) AS NVARCHAR(100)) + @LineFeed +
			'Elapsed Time: ' + CAST(qsNow.total_elapsed_time - (COALESCE(qsFirst.total_elapsed_time, 0)) AS NVARCHAR(100)) + @LineFeed +
			'CPU Time: ' + CAST(qsNow.total_worker_time - (COALESCE(qsFirst.total_worker_time, 0)) AS NVARCHAR(100)) + @LineFeed +
			'Logical Reads: ' + CAST(qsNow.total_logical_reads - (COALESCE(qsFirst.total_logical_reads, 0)) AS NVARCHAR(100)) + @LineFeed +
			'Logical Writes: ' + CAST(qsNow.total_logical_writes - (COALESCE(qsFirst.total_logical_writes, 0)) AS NVARCHAR(100)) + @LineFeed +
			'CLR Time: ' + CAST(qsNow.total_clr_time - (COALESCE(qsFirst.total_clr_time, 0)) AS NVARCHAR(100)) + @LineFeed +
			@LineFeed + @LineFeed + 'Query stats since ' + CONVERT(NVARCHAR(100), qsNow.creation_time ,121) + @LineFeed +
			'Executions: ' + CAST(qsNow.execution_count AS NVARCHAR(100)) + 
					CASE qsTotal.execution_count WHEN 0 THEN '' ELSE (' - Percent of Server Total: ' + CAST(CAST(100.0 * qsNow.execution_count / qsTotal.execution_count AS DECIMAL(6,2)) AS NVARCHAR(100)) + '%') END + @LineFeed +
			'Elapsed Time: ' + CAST(qsNow.total_elapsed_time AS NVARCHAR(100)) + 
					CASE qsTotal.total_elapsed_time WHEN 0 THEN '' ELSE (' - Percent of Server Total: ' + CAST(CAST(100.0 * qsNow.total_elapsed_time / qsTotal.total_elapsed_time AS DECIMAL(6,2)) AS NVARCHAR(100)) + '%') END + @LineFeed +
			'CPU Time: ' + CAST(qsNow.total_worker_time AS NVARCHAR(100)) + 
					CASE qsTotal.total_worker_time WHEN 0 THEN '' ELSE (' - Percent of Server Total: ' + CAST(CAST(100.0 * qsNow.total_worker_time / qsTotal.total_worker_time AS DECIMAL(6,2)) AS NVARCHAR(100)) + '%') END + @LineFeed +
			'Logical Reads: ' + CAST(qsNow.total_logical_reads AS NVARCHAR(100)) +
					CASE qsTotal.total_logical_reads WHEN 0 THEN '' ELSE (' - Percent of Server Total: ' + CAST(CAST(100.0 * qsNow.total_logical_reads / qsTotal.total_logical_reads AS DECIMAL(6,2)) AS NVARCHAR(100)) + '%') END + @LineFeed +
			'Logical Writes: ' + CAST(qsNow.total_logical_writes AS NVARCHAR(100)) + 
					CASE qsTotal.total_logical_writes WHEN 0 THEN '' ELSE (' - Percent of Server Total: ' + CAST(CAST(100.0 * qsNow.total_logical_writes / qsTotal.total_logical_writes AS DECIMAL(6,2)) AS NVARCHAR(100)) + '%') END + @LineFeed +
			'CLR Time: ' + CAST(qsNow.total_clr_time AS NVARCHAR(100)) + 
					CASE qsTotal.total_clr_time WHEN 0 THEN '' ELSE (' - Percent of Server Total: ' + CAST(CAST(100.0 * qsNow.total_clr_time / qsTotal.total_clr_time AS DECIMAL(6,2)) AS NVARCHAR(100)) + '%') END + @LineFeed +
			--@LineFeed + @LineFeed + 'Query hash: ' + CAST(qsNow.query_hash AS NVARCHAR(100)) + @LineFeed +
			--@LineFeed + @LineFeed + 'Query plan hash: ' + CAST(qsNow.query_plan_hash AS NVARCHAR(100)) + 
			@LineFeed AS Details,
			'See the URL for tuning tips on why this query may be consuming resources.' AS HowToStopIt,
			qp.query_plan, 
			QueryText = SUBSTRING(st.text,
                 (qsNow.statement_start_offset / 2) + 1,
                 ((CASE qsNow.statement_end_offset
                   WHEN -1 THEN DATALENGTH(st.text)
                   ELSE qsNow.statement_end_offset
                   END - qsNow.statement_start_offset) / 2) + 1),
            qsNow.ID AS QueryStatsNowID,
            qsFirst.ID AS QueryStatsFirstID,
            qsNow.plan_handle AS PlanHandle
			FROM #QueryStats qsNow
				INNER JOIN #QueryStats qsTotal ON qsTotal.Pass = 0
				LEFT OUTER JOIN #QueryStats qsFirst ON qsNow.[sql_handle] = qsFirst.[sql_handle] AND qsNow.statement_start_offset = qsFirst.statement_start_offset AND qsNow.statement_end_offset = qsFirst.statement_end_offset AND qsNow.plan_generation_num = qsFirst.plan_generation_num AND qsNow.plan_handle = qsFirst.plan_handle AND qsFirst.Pass = 1
				CROSS APPLY sys.dm_exec_sql_text(qsNow.sql_handle) AS st 
				CROSS APPLY sys.dm_exec_query_plan(qsNow.plan_handle) AS qp
			WHERE qsNow.Points > 0 AND st.text IS NOT NULL AND qp.query_plan IS NOT NULL

            UPDATE #AskBrentResults
                SET DatabaseID = CAST(attr.value AS INT),
                DatabaseName = DB_NAME(CAST(attr.value AS INT))
            FROM #AskBrentResults
                CROSS APPLY sys.dm_exec_plan_attributes(#AskBrentResults.PlanHandle) AS attr
            WHERE attr.attribute = 'dbid'
            

		END /* IF DATEDIFF(ss, @FinishSampleTime, GETDATE()) > 10 AND @ExpertMode = 0 */
	

	/* Wait Stats - CheckID 6 */
	/* Compare the current wait stats to the sample we took at the start, and insert the top 10 waits. */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt)
	SELECT TOP 10 6 AS CheckID,
		200 AS Priority,
		'Wait Stats' AS FindingGroup,
		wNow.wait_type AS Finding,
		N'http://www.brentozar.com/sql/wait-stats/#' + wNow.wait_type AS URL,
		'For ' + CAST(((wNow.wait_time_ms - COALESCE(wBase.wait_time_ms,0)) / 1000) AS NVARCHAR(100)) + ' seconds over the last ' + CAST(@Seconds AS NVARCHAR(10)) + ' seconds, SQL Server was waiting on this particular bottleneck.' + @LineFeed + @LineFeed AS Details,
		'See the URL for more details on how to mitigate this wait type.' AS HowToStopIt
	FROM #WaitStats wNow
	LEFT OUTER JOIN #WaitStats wBase ON wNow.wait_type = wBase.wait_type AND wNow.SampleTime > wBase.SampleTime
	WHERE wNow.wait_time_ms > (wBase.wait_time_ms + (.5 * @Seconds * 1000)) /* Only look for things we've actually waited on for half of the time or more */
	ORDER BY (wNow.wait_time_ms - COALESCE(wBase.wait_time_ms,0)) DESC;

	/* Server Performance - Slow Data File Reads - CheckID 11 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, DatabaseID, DatabaseName)
	SELECT TOP 10 11 AS CheckID,
		50 AS Priority,
		'Server Performance' AS FindingGroup,
		'Slow Data File Reads' AS Finding,
		'http://BrentOzar.com/go/slow/' AS URL,
		'File: ' + fNow.PhysicalName + @LineFeed 
			+ 'Number of reads during the sample: ' + CAST((fNow.num_of_reads - fBase.num_of_reads) AS NVARCHAR(20)) + @LineFeed 
			+ 'Seconds spent waiting on storage for these reads: ' + CAST(((fNow.io_stall_read_ms - fBase.io_stall_read_ms) / 1000.0) AS NVARCHAR(20)) + @LineFeed 
			+ 'Average read latency during the sample: ' + CAST(((fNow.io_stall_read_ms - fBase.io_stall_read_ms) / (fNow.num_of_reads - fBase.num_of_reads) ) AS NVARCHAR(20)) + ' milliseconds' + @LineFeed 
			+ 'Microsoft guidance for data file read speed: 20ms or less.' + @LineFeed + @LineFeed AS Details,
		'See the URL for more details on how to mitigate this wait type.' AS HowToStopIt,
		fNow.DatabaseID,
		fNow.DatabaseName
	FROM #FileStats fNow
	INNER JOIN #FileStats fBase ON fNow.DatabaseID = fBase.DatabaseID AND fNow.FileID = fBase.FileID AND fNow.SampleTime > fBase.SampleTime AND fNow.num_of_reads > fBase.num_of_reads AND fNow.io_stall_read_ms > (fBase.io_stall_read_ms + 1000)
	WHERE (fNow.io_stall_read_ms - fBase.io_stall_read_ms) / (fNow.num_of_reads - fBase.num_of_reads) >= @FileLatencyThresholdMS
		AND fNow.TypeDesc = 'ROWS'
	ORDER BY (fNow.io_stall_read_ms - fBase.io_stall_read_ms) / (fNow.num_of_reads - fBase.num_of_reads) DESC;

	/* Server Performance - Slow Log File Writes - CheckID 12 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, DatabaseID, DatabaseName)
	SELECT TOP 10 12 AS CheckID,
		50 AS Priority,
		'Server Performance' AS FindingGroup,
		'Slow Log File Writes' AS Finding,
		'http://BrentOzar.com/go/slow/' AS URL,
		'File: ' + fNow.PhysicalName + @LineFeed 
			+ 'Number of writes during the sample: ' + CAST((fNow.num_of_writes - fBase.num_of_writes) AS NVARCHAR(20)) + @LineFeed 
			+ 'Seconds spent waiting on storage for these writes: ' + CAST(((fNow.io_stall_write_ms - fBase.io_stall_write_ms) / 1000.0) AS NVARCHAR(20)) + @LineFeed 
			+ 'Average write latency during the sample: ' + CAST(((fNow.io_stall_write_ms - fBase.io_stall_write_ms) / (fNow.num_of_writes - fBase.num_of_writes) ) AS NVARCHAR(20)) + ' milliseconds' + @LineFeed 
			+ 'Microsoft guidance for log file write speed: 3ms or less.' + @LineFeed + @LineFeed AS Details,
		'See the URL for more details on how to mitigate this wait type.' AS HowToStopIt,
		fNow.DatabaseID,
		fNow.DatabaseName
	FROM #FileStats fNow
	INNER JOIN #FileStats fBase ON fNow.DatabaseID = fBase.DatabaseID AND fNow.FileID = fBase.FileID AND fNow.SampleTime > fBase.SampleTime AND fNow.num_of_writes > fBase.num_of_writes AND fNow.io_stall_write_ms > (fBase.io_stall_write_ms + 1000)
	WHERE (fNow.io_stall_write_ms - fBase.io_stall_write_ms) / (fNow.num_of_writes - fBase.num_of_writes) >= @FileLatencyThresholdMS
		AND fNow.TypeDesc = 'LOG'
	ORDER BY (fNow.io_stall_write_ms - fBase.io_stall_write_ms) / (fNow.num_of_writes - fBase.num_of_writes) DESC;


	/* SQL Server Internal Maintenance - Log File Growing - CheckID 13 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt)
	SELECT 13 AS CheckID,
		1 AS Priority,
		'SQL Server Internal Maintenance' AS FindingGroup,
		'Log File Growing' AS Finding,
		'http://BrentOzar.com/askbrent/file-growing/' AS URL,
		'Number of growths during the sample: ' + CAST(ps.value_delta AS NVARCHAR(20)) + @LineFeed 
			+ 'Determined by sampling Perfmon counter ' + ps.object_name + ' - ' + ps.counter_name + @LineFeed AS Details,
		'Pre-grow data and log files during maintenance windows so that they do not grow during production loads. See the URL for more details.'  AS HowToStopIt
	FROM #PerfmonStats ps
	WHERE ps.Pass = 2
		AND object_name = 'SQLServer:Databases'
		AND counter_name = 'Log Growths'
		AND value_delta > 0


	/* SQL Server Internal Maintenance - Log File Shrinking - CheckID 14 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt)
	SELECT 14 AS CheckID,
		1 AS Priority,
		'SQL Server Internal Maintenance' AS FindingGroup,
		'Log File Shrinking' AS Finding,
		'http://BrentOzar.com/askbrent/file-shrinking/' AS URL,
		'Number of shrinks during the sample: ' + CAST(ps.value_delta AS NVARCHAR(20)) + @LineFeed 
			+ 'Determined by sampling Perfmon counter ' + ps.object_name + ' - ' + ps.counter_name + @LineFeed AS Details,
		'Pre-grow data and log files during maintenance windows so that they do not grow during production loads. See the URL for more details.' AS HowToStopIt
	FROM #PerfmonStats ps
	WHERE ps.Pass = 2
		AND object_name = 'SQLServer:Databases'
		AND counter_name = 'Log Shrinks'
		AND value_delta > 0

	/* Query Problems - Compilations/Sec High - CheckID 15 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt)
	SELECT 15 AS CheckID,
		50 AS Priority,
		'Query Problems' AS FindingGroup,
		'Compilations/Sec High' AS Finding,
		'http://BrentOzar.com/askbrent/compilations/' AS URL,
		'Number of batch requests during the sample: ' + CAST(ps.value_delta AS NVARCHAR(20)) + @LineFeed 
			+ 'Number of compilations during the sample: ' + CAST(psComp.value_delta AS NVARCHAR(20)) + @LineFeed 
			+ 'For OLTP environments, Microsoft recommends that 90% of batch requests should hit the plan cache, and not be compiled from scratch. We are exceeding that threshold.' + @LineFeed AS Details,
		'Find out why plans are not being reused, and consider enabling Forced Parameterization. See the URL for more details.' AS HowToStopIt
	FROM #PerfmonStats ps
		INNER JOIN #PerfmonStats psComp ON psComp.Pass = 2 AND psComp.object_name = 'SQLServer:SQL Statistics' AND psComp.counter_name = 'SQL Compilations/sec' AND psComp.value_delta > 0
	WHERE ps.Pass = 2
		AND ps.object_name = 'SQLServer:SQL Statistics'
		AND ps.counter_name = 'Batch Requests/sec'
		AND ps.value_delta > (1000 * @Seconds) /* Ignore servers sitting idle */
		AND (psComp.value_delta * 10) > ps.value_delta /* Compilations are more than 10% of batch requests per second */

	/* Query Problems - Re-Compilations/Sec High - CheckID 16 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt)
	SELECT 16 AS CheckID,
		50 AS Priority,
		'Query Problems' AS FindingGroup,
		'Re-Compilations/Sec High' AS Finding,
		'http://BrentOzar.com/askbrent/recompilations/' AS URL,
		'Number of batch requests during the sample: ' + CAST(ps.value_delta AS NVARCHAR(20)) + @LineFeed 
			+ 'Number of recompilations during the sample: ' + CAST(psComp.value_delta AS NVARCHAR(20)) + @LineFeed 
			+ 'More than 10% of our queries are being recompiled. This is typically due to statistics changing on objects.' + @LineFeed AS Details,
		'Find out which objects are changing so quickly that they hit the stats update threshold. See the URL for more details.' AS HowToStopIt
	FROM #PerfmonStats ps
		INNER JOIN #PerfmonStats psComp ON psComp.Pass = 2 AND psComp.object_name = 'SQLServer:SQL Statistics' AND psComp.counter_name = 'SQL Re-Compilations/sec' AND psComp.value_delta > 0
	WHERE ps.Pass = 2
		AND ps.object_name = 'SQLServer:SQL Statistics'
		AND ps.counter_name = 'Batch Requests/sec'
		AND ps.value_delta > (1000 * @Seconds) /* Ignore servers sitting idle */
		AND (psComp.value_delta * 10) > ps.value_delta /* Recompilations are more than 10% of batch requests per second */

	/* Server Info - Batch Requests per Sec - CheckID 19 */
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, DetailsInt)
	SELECT 19 AS CheckID,
		250 AS Priority,
		'Server Info' AS FindingGroup,
		'Batch Requests per Sec' AS Finding,
		'http://BrentOzar.com/go/measure' AS URL,
		CAST(ps.value_delta / (DATEDIFF(ss, ps1.SampleTime, ps.SampleTime)) AS NVARCHAR(20)) AS Details,
        ps.value_delta / (DATEDIFF(ss, ps1.SampleTime, ps.SampleTime)) AS DetailsInt
	FROM #PerfmonStats ps
        INNER JOIN #PerfmonStats ps1 ON ps.object_name = ps1.object_name AND ps.counter_name = ps1.counter_name AND ps1.Pass = 1
	WHERE ps.Pass = 2
		AND ps.object_name = 'SQLServer:SQL Statistics'
		AND ps.counter_name = 'Batch Requests/sec';

	/* Server Info - Wait Time per Core per Sec - CheckID 19 */
    WITH waits1(waits_ms) AS (SELECT SUM(ws1.wait_time_ms) FROM #WaitStats ws1 WHERE ws1.Pass = 1),
    waits2(waits_ms) AS (SELECT SUM(ws2.wait_time_ms) FROM #WaitStats ws2 WHERE ws2.Pass = 2)
	INSERT INTO #AskBrentResults (CheckID, Priority, FindingsGroup, Finding, URL, Details, DetailsInt)
	SELECT 19 AS CheckID,
		250 AS Priority,
		'Server Info' AS FindingGroup,
		'Wait Time per Core per Sec' AS Finding,
		'http://BrentOzar.com/sql/wait-stats/' AS URL,
		CAST((waits2.waits_ms - waits1.waits_ms) / i.cpu_count / 1000 AS NVARCHAR(20)) AS Details,
        (waits2.waits_ms - waits1.waits_ms) / i.cpu_count /1000 AS DetailsInt
	FROM sys.dm_os_sys_info i
      CROSS JOIN waits1
      CROSS JOIN waits2;

	/* If we didn't find anything, apologize. */
	IF NOT EXISTS (SELECT * FROM #AskBrentResults WHERE CheckID NOT IN (19, 20))
	BEGIN

		INSERT  INTO #AskBrentResults
				( CheckID ,
				  Priority ,
				  FindingsGroup ,
				  Finding ,
				  URL ,
				  Details
				)
		VALUES  ( -1 ,
				  255 ,
				  'No Problems Found' ,
				  'From Brent Ozar Unlimited' ,
				  'http://www.BrentOzar.com/askbrent/' ,
				  'Try running our more in-depth checks: http://www.BrentOzar.com/blitz/' + @LineFeed + 'or there may not be an unusual SQL Server performance problem. '
				);
		
	END /*IF NOT EXISTS (SELECT * FROM #AskBrentResults) */
	ELSE /* We found stuff, so add credits */
	BEGIN

		/* Add credits for the nice folks who put so much time into building and maintaining this for free: */                    
		INSERT  INTO #AskBrentResults
				( CheckID ,
				  Priority ,
				  FindingsGroup ,
				  Finding ,
				  URL ,
				  Details
				)
		VALUES  ( -1 ,
				  255 ,
				  'Thanks!' ,
				  'From Brent Ozar Unlimited' ,
				  'http://www.BrentOzar.com/askbrent/' ,
				  'Thanks from the Brent Ozar Unlimited team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com. '
				);

		INSERT  INTO #AskBrentResults
				( CheckID ,
				  Priority ,
				  FindingsGroup ,
				  Finding ,
				  URL ,
				  Details

				)
		VALUES  ( -1 ,
				  0 ,
				  'sp_AskBrent (TM) v' + CAST(@Version AS VARCHAR(20)) + ' as of ' + CAST(CONVERT(DATETIME, @VersionDate, 102) AS VARCHAR(100)),
				  'From Brent Ozar Unlimited' ,
				  'http://www.BrentOzar.com/askbrent/' ,
				  'Thanks from the Brent Ozar Unlimited team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'
				);

	END /* ELSE  We found stuff, so add credits */

	/* @OutputTableName lets us export the results to a permanent table */
	IF @OutputDatabaseName IS NOT NULL
		AND @OutputSchemaName IS NOT NULL
		AND @OutputTableName IS NOT NULL
	    AND @OutputTableName NOT LIKE '#%'
		AND EXISTS ( SELECT *
					 FROM   sys.databases
					 WHERE  QUOTENAME([name]) = @OutputDatabaseName) 
	BEGIN
		SET @StringToExecute = 'USE '
			+ @OutputDatabaseName
			+ '; IF EXISTS(SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
			+ @OutputSchemaName
			+ ''') AND NOT EXISTS (SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.TABLES WHERE QUOTENAME(TABLE_SCHEMA) = '''
			+ @OutputSchemaName + ''' AND QUOTENAME(TABLE_NAME) = '''
			+ @OutputTableName + ''') CREATE TABLE '
			+ @OutputSchemaName + '.'
			+ @OutputTableName
			+ ' (ID INT IDENTITY(1,1) NOT NULL, 
				ServerName NVARCHAR(128), 
				CheckDate DATETIME, 
				AskBrentVersion INT,
				CheckID INT NOT NULL,
				Priority TINYINT NOT NULL,
				FindingsGroup VARCHAR(50) NOT NULL,
				Finding VARCHAR(200) NOT NULL,
				URL VARCHAR(200) NOT NULL,
				Details NVARCHAR(4000) NULL,
				HowToStopIt [XML] NULL,
				QueryPlan [XML] NULL,
				QueryText NVARCHAR(MAX) NULL,
				StartTime DATETIME NULL,
				LoginName NVARCHAR(128) NULL,
				NTUserName NVARCHAR(128) NULL,
				OriginalLoginName NVARCHAR(128) NULL,
				ProgramName NVARCHAR(128) NULL,
				HostName NVARCHAR(128) NULL,
				DatabaseID INT NULL,
				DatabaseName NVARCHAR(128) NULL,
				OpenTransactionCount INT NULL,
                DetailsInt INT NULL,
				CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'

		EXEC(@StringToExecute);
		SET @StringToExecute = N' IF EXISTS(SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
			+ @OutputSchemaName + ''') INSERT '
			+ @OutputDatabaseName + '.'
			+ @OutputSchemaName + '.'
			+ @OutputTableName
			+ ' (ServerName, CheckDate, AskBrentVersion, CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, QueryPlan, QueryText, StartTime, LoginName, NTUserName, OriginalLoginName, ProgramName, HostName, DatabaseID, DatabaseName, OpenTransactionCount, DetailsInt) SELECT '''
			+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
			+ ''', ''' + CAST(CONVERT(DATETIME, @StartSampleTime, 102) AS VARCHAR(100)) + ''', ' + CAST(@Version AS NVARCHAR(128))
			+ ', CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, QueryPlan, QueryText, StartTime, LoginName, NTUserName, OriginalLoginName, ProgramName, HostName, DatabaseID, DatabaseName, OpenTransactionCount, DetailsInt FROM #AskBrentResults ORDER BY Priority , FindingsGroup , Finding , Details';
		EXEC(@StringToExecute);
	END
	ELSE IF (SUBSTRING(@OutputTableName, 2, 2) = '##')
	BEGIN
		SET @StringToExecute = N' IF (OBJECT_ID(''tempdb..'
			+ @OutputTableName
			+ ''') IS NULL) CREATE TABLE '
			+ @OutputTableName
			+ ' (ID INT IDENTITY(1,1) NOT NULL, 
				ServerName NVARCHAR(128), 
				CheckDate DATETIME, 
				AskBrentVersion INT,
				CheckID INT NOT NULL,
				Priority TINYINT NOT NULL,
				FindingsGroup VARCHAR(50) NOT NULL,
				Finding VARCHAR(200) NOT NULL,
				URL VARCHAR(200) NOT NULL,
				Details NVARCHAR(4000) NULL,
				HowToStopIt [XML] NULL,
				QueryPlan [XML] NULL,
				QueryText NVARCHAR(MAX) NULL,
				StartTime DATETIME NULL,
				LoginName NVARCHAR(128) NULL,
				NTUserName NVARCHAR(128) NULL,
				OriginalLoginName NVARCHAR(128) NULL,
				ProgramName NVARCHAR(128) NULL,
				HostName NVARCHAR(128) NULL,
				DatabaseID INT NULL,
				DatabaseName NVARCHAR(128) NULL,
				OpenTransactionCount INT NULL,
                DetailsInt INT NULL,
				CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'
			+ ' INSERT '
			+ @OutputTableName
			+ ' (ServerName, CheckDate, AskBrentVersion, CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, QueryPlan, QueryText, StartTime, LoginName, NTUserName, OriginalLoginName, ProgramName, HostName, DatabaseID, DatabaseName, OpenTransactionCount, DetailsInt) SELECT '''
			+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
			+ ''', ''' + CAST(CONVERT(DATETIME, @StartSampleTime, 102) AS VARCHAR(100)) + ''', ' + CAST(@Version AS NVARCHAR(128))
			+ ', CheckID, Priority, FindingsGroup, Finding, URL, Details, HowToStopIt, QueryPlan, QueryText, StartTime, LoginName, NTUserName, OriginalLoginName, ProgramName, HostName, DatabaseID, DatabaseName, OpenTransactionCount, DetailsInt FROM #AskBrentResults ORDER BY Priority , FindingsGroup , Finding , Details';
		EXEC(@StringToExecute);
	END
	ELSE IF (SUBSTRING(@OutputTableName, 2, 1) = '#')
	BEGIN
		RAISERROR('Due to the nature of Dymamic SQL, only global (i.e. double pound (##)) temp tables are supported for @OutputTableName', 16, 0)
	END

	/* @OutputTableNameFileStats lets us export the results to a permanent table */
	IF @OutputDatabaseName IS NOT NULL
		AND @OutputSchemaName IS NOT NULL
		AND @OutputTableNameFileStats IS NOT NULL
	    AND @OutputTableNameFileStats NOT LIKE '#%'
		AND EXISTS ( SELECT *
					 FROM   sys.databases
					 WHERE  QUOTENAME([name]) = @OutputDatabaseName) 
	BEGIN
		SET @StringToExecute = 'USE '
			+ @OutputDatabaseName
			+ '; IF EXISTS(SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
			+ @OutputSchemaName
			+ ''') AND NOT EXISTS (SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.TABLES WHERE QUOTENAME(TABLE_SCHEMA) = '''
			+ @OutputSchemaName + ''' AND QUOTENAME(TABLE_NAME) = '''
			+ @OutputTableNameFileStats + ''') CREATE TABLE '
			+ @OutputSchemaName + '.'
			+ @OutputTableNameFileStats
			+ ' (ID INT IDENTITY(1,1) NOT NULL, 
				ServerName NVARCHAR(128), 
				CheckDate DATETIME, 
		        DatabaseID INT NOT NULL,
		        FileID INT NOT NULL,
		        DatabaseName NVARCHAR(256) ,
		        FileLogicalName NVARCHAR(256) ,
		        TypeDesc NVARCHAR(60) ,
		        SizeOnDiskMB BIGINT ,
		        io_stall_read_ms BIGINT ,
		        num_of_reads BIGINT ,
		        bytes_read BIGINT ,
		        io_stall_write_ms BIGINT ,
		        num_of_writes BIGINT ,
		        bytes_written BIGINT, 
		        PhysicalName NVARCHAR(520) ,
				CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'

		EXEC(@StringToExecute);
		SET @StringToExecute = N' IF EXISTS(SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
			+ @OutputSchemaName + ''') INSERT '
			+ @OutputDatabaseName + '.'
			+ @OutputSchemaName + '.'
			+ @OutputTableNameFileStats
			+ ' (ServerName, CheckDate, DatabaseID, FileID, DatabaseName, FileLogicalName, TypeDesc, SizeOnDiskMB, io_stall_read_ms, num_of_reads, bytes_read, io_stall_write_ms, num_of_writes, bytes_written, PhysicalName) SELECT '''
			+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
			+ ''', ''' + CAST(CONVERT(DATETIME, @StartSampleTime, 102) AS VARCHAR(100)) + ''', '
			+ 'DatabaseID, FileID, DatabaseName, FileLogicalName, TypeDesc, SizeOnDiskMB, io_stall_read_ms, num_of_reads, bytes_read, io_stall_write_ms, num_of_writes, bytes_written, PhysicalName FROM #FileStats WHERE Pass = 2';
		EXEC(@StringToExecute);
	END
	ELSE IF (SUBSTRING(@OutputTableNameFileStats, 2, 2) = '##')
	BEGIN
		SET @StringToExecute = N' IF (OBJECT_ID(''tempdb..'
			+ @OutputTableNameFileStats
			+ ''') IS NULL) CREATE TABLE '
			+ @OutputTableNameFileStats
			+ ' (ID INT IDENTITY(1,1) NOT NULL, 
				ServerName NVARCHAR(128), 
				CheckDate DATETIME, 
		        DatabaseID INT NOT NULL,
		        FileID INT NOT NULL,
		        DatabaseName NVARCHAR(256) ,
		        FileLogicalName NVARCHAR(256) ,
		        TypeDesc NVARCHAR(60) ,
		        SizeOnDiskMB BIGINT ,
		        io_stall_read_ms BIGINT ,
		        num_of_reads BIGINT ,
		        bytes_read BIGINT ,
		        io_stall_write_ms BIGINT ,
		        num_of_writes BIGINT ,
		        bytes_written BIGINT, 
		        PhysicalName NVARCHAR(520) ,
                DetailsInt INT NULL,
				CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'
			+ ' INSERT '
			+ @OutputTableNameFileStats
			+ ' (ServerName, CheckDate, DatabaseID, FileID, DatabaseName, FileLogicalName, TypeDesc, SizeOnDiskMB, io_stall_read_ms, num_of_reads, bytes_read, io_stall_write_ms, num_of_writes, bytes_written, PhysicalName) SELECT '''
			+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
			+ ''', ''' + CAST(CONVERT(DATETIME, @StartSampleTime, 102) AS VARCHAR(100)) + ''', '
			+ 'DatabaseID, FileID, DatabaseName, FileLogicalName, TypeDesc, SizeOnDiskMB, io_stall_read_ms, num_of_reads, bytes_read, io_stall_write_ms, num_of_writes, bytes_written, PhysicalName FROM #FileStats WHERE Pass = 2';
		EXEC(@StringToExecute);
	END
	ELSE IF (SUBSTRING(@OutputTableNameFileStats, 2, 1) = '#')
	BEGIN
		RAISERROR('Due to the nature of Dymamic SQL, only global (i.e. double pound (##)) temp tables are supported for @OutputTableName', 16, 0)
	END


	/* @OutputTableNamePerfmonStats lets us export the results to a permanent table */
	IF @OutputDatabaseName IS NOT NULL
		AND @OutputSchemaName IS NOT NULL
		AND @OutputTableNamePerfmonStats IS NOT NULL
	    AND @OutputTableNamePerfmonStats NOT LIKE '#%'
		AND EXISTS ( SELECT *
					 FROM   sys.databases
					 WHERE  QUOTENAME([name]) = @OutputDatabaseName) 
	BEGIN
		SET @StringToExecute = 'USE '
			+ @OutputDatabaseName
			+ '; IF EXISTS(SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
			+ @OutputSchemaName
			+ ''') AND NOT EXISTS (SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.TABLES WHERE QUOTENAME(TABLE_SCHEMA) = '''
			+ @OutputSchemaName + ''' AND QUOTENAME(TABLE_NAME) = '''
			+ @OutputTableNamePerfmonStats + ''') CREATE TABLE '
			+ @OutputSchemaName + '.'
			+ @OutputTableNamePerfmonStats
			+ ' (ID INT IDENTITY(1,1) NOT NULL, 
				ServerName NVARCHAR(128), 
				CheckDate DATETIME, 
		        [object_name] NVARCHAR(128) NOT NULL,
		        [counter_name] NVARCHAR(128) NOT NULL,
		        [instance_name] NVARCHAR(128) NULL,
		        [cntr_value] BIGINT NULL,
		        [cntr_type] INT NOT NULL,
		        [value_delta] BIGINT NULL,
		        [value_per_second] DECIMAL(18,2) NULL,
				CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'

		EXEC(@StringToExecute);
		SET @StringToExecute = N' IF EXISTS(SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
			+ @OutputSchemaName + ''') INSERT '
			+ @OutputDatabaseName + '.'
			+ @OutputSchemaName + '.'
			+ @OutputTableNamePerfmonStats
			+ ' (ServerName, CheckDate, object_name, counter_name, instance_name, cntr_value, cntr_type, value_delta, value_per_second) SELECT '''
			+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
			+ ''', ''' + CAST(CONVERT(DATETIME, @StartSampleTime, 102) AS VARCHAR(100)) + ''', '
			+ 'object_name, counter_name, instance_name, cntr_value, cntr_type, value_delta, value_per_second FROM #PerfmonStats WHERE Pass = 2';
		EXEC(@StringToExecute);
	END
	ELSE IF (SUBSTRING(@OutputTableNamePerfmonStats, 2, 2) = '##')
	BEGIN
		SET @StringToExecute = N' IF (OBJECT_ID(''tempdb..'
			+ @OutputTableNamePerfmonStats
			+ ''') IS NULL) CREATE TABLE '
			+ @OutputTableNamePerfmonStats
			+ ' (ID INT IDENTITY(1,1) NOT NULL, 
				ServerName NVARCHAR(128), 
				CheckDate DATETIME, 
		        [object_name] NVARCHAR(128) NOT NULL,
		        [counter_name] NVARCHAR(128) NOT NULL,
		        [instance_name] NVARCHAR(128) NULL,
		        [cntr_value] BIGINT NULL,
		        [cntr_type] INT NOT NULL,
		        [value_delta] BIGINT NULL,
		        [value_per_second] DECIMAL(18,2) NULL,
				CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'
			+ ' INSERT '
			+ @OutputTableNamePerfmonStats
			+ ' (ServerName, CheckDate, object_name, counter_name, instance_name, cntr_value, cntr_type, value_delta, value_per_second) SELECT '''
			+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
			+ ''', ''' + CAST(CONVERT(DATETIME, @StartSampleTime, 102) AS VARCHAR(100)) + ''', '
			+ 'object_name, counter_name, instance_name, cntr_value, cntr_type, value_delta, value_per_second FROM #PerfmonStats WHERE Pass = 2';
		EXEC(@StringToExecute);
	END
	ELSE IF (SUBSTRING(@OutputTableNamePerfmonStats, 2, 1) = '#')
	BEGIN
		RAISERROR('Due to the nature of Dymamic SQL, only global (i.e. double pound (##)) temp tables are supported for @OutputTableName', 16, 0)
	END


	/* @OutputTableNameWaitStats lets us export the results to a permanent table */
	IF @OutputDatabaseName IS NOT NULL
		AND @OutputSchemaName IS NOT NULL
		AND @OutputTableNameWaitStats IS NOT NULL
	    AND @OutputTableNameWaitStats NOT LIKE '#%'
		AND EXISTS ( SELECT *
					 FROM   sys.databases
					 WHERE  QUOTENAME([name]) = @OutputDatabaseName) 
	BEGIN
		SET @StringToExecute = 'USE '
			+ @OutputDatabaseName
			+ '; IF EXISTS(SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
			+ @OutputSchemaName
			+ ''') AND NOT EXISTS (SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.TABLES WHERE QUOTENAME(TABLE_SCHEMA) = '''
			+ @OutputSchemaName + ''' AND QUOTENAME(TABLE_NAME) = '''
			+ @OutputTableNameWaitStats + ''') CREATE TABLE '
			+ @OutputSchemaName + '.'
			+ @OutputTableNameWaitStats
			+ ' (ID INT IDENTITY(1,1) NOT NULL, 
				ServerName NVARCHAR(128), 
				CheckDate DATETIME, 
		        wait_type NVARCHAR(60), 
                wait_time_ms BIGINT, 
                signal_wait_time_ms BIGINT, 
                waiting_tasks_count BIGINT ,
				CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'

		EXEC(@StringToExecute);
		SET @StringToExecute = N' IF EXISTS(SELECT * FROM '
			+ @OutputDatabaseName
			+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
			+ @OutputSchemaName + ''') INSERT '
			+ @OutputDatabaseName + '.'
			+ @OutputSchemaName + '.'
			+ @OutputTableNameWaitStats
			+ ' (ServerName, CheckDate, wait_type, wait_time_ms, signal_wait_time_ms, waiting_tasks_count) SELECT '''
			+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
			+ ''', ''' + CAST(CONVERT(DATETIME, @StartSampleTime, 102) AS VARCHAR(100)) + ''', '
			+ 'wait_type, wait_time_ms, signal_wait_time_ms, waiting_tasks_count FROM #WaitStats WHERE Pass = 2 AND wait_time_ms > 0 AND waiting_tasks_count > 0';
		EXEC(@StringToExecute);
	END
	ELSE IF (SUBSTRING(@OutputTableNameWaitStats, 2, 2) = '##')
	BEGIN
		SET @StringToExecute = N' IF (OBJECT_ID(''tempdb..'
			+ @OutputTableNameWaitStats
			+ ''') IS NULL) CREATE TABLE '
			+ @OutputTableNameWaitStats
			+ ' (ID INT IDENTITY(1,1) NOT NULL, 
				ServerName NVARCHAR(128), 
				CheckDate DATETIME, 
		        wait_type NVARCHAR(60), 
                wait_time_ms BIGINT, 
                signal_wait_time_ms BIGINT, 
                waiting_tasks_count BIGINT ,
				CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'
			+ ' INSERT '
			+ @OutputTableNameWaitStats
			+ ' (ServerName, CheckDate, wait_type, wait_time_ms, signal_wait_time_ms, waiting_tasks_count) SELECT '''
			+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
			+ ''', ''' + CAST(CONVERT(DATETIME, @StartSampleTime, 102) AS VARCHAR(100)) + ''', '
			+ 'wait_type, wait_time_ms, signal_wait_time_ms, waiting_tasks_count FROM #WaitStats WHERE Pass = 2 AND wait_time_ms > 0 AND waiting_tasks_count > 0';
		EXEC(@StringToExecute);
	END
	ELSE IF (SUBSTRING(@OutputTableNameWaitStats, 2, 1) = '#')
	BEGIN
		RAISERROR('Due to the nature of Dymamic SQL, only global (i.e. double pound (##)) temp tables are supported for @OutputTableName', 16, 0)
	END




	DECLARE @separator AS VARCHAR(1);
	IF @OutputType = 'RSV' 
		SET @separator = CHAR(31);
	ELSE 
		SET @separator = ',';

	IF @OutputType = 'COUNT' 
	BEGIN
		SELECT  COUNT(*) AS Warnings
		FROM    #AskBrentResults
	END
	ELSE 
		IF @OutputType = 'Opserver1' 
		BEGIN

			SELECT  r.[Priority] ,
					r.[FindingsGroup] ,
					r.[Finding] ,
					r.[URL] ,
					r.[Details],
					r.[HowToStopIt] ,
					r.[CheckID] ,
					r.[StartTime],
					r.[LoginName],
					r.[NTUserName],
					r.[OriginalLoginName],
					r.[ProgramName],
					r.[HostName],
					r.[DatabaseID],
					r.[DatabaseName],
					r.[OpenTransactionCount],
					r.[QueryPlan],
					r.[QueryText],
                    qsNow.plan_handle AS PlanHandle,
                    qsNow.sql_handle AS SqlHandle,
                    qsNow.statement_start_offset AS StatementStartOffset,
                    qsNow.statement_end_offset AS StatementEndOffset,
			        [Executions] = qsNow.execution_count - (COALESCE(qsFirst.execution_count, 0)),
                    [ExecutionsPercent] = CAST(100.0 * (qsNow.execution_count - (COALESCE(qsFirst.execution_count, 0))) / (qsTotal.execution_count - qsTotalFirst.execution_count) AS DECIMAL(6,2)),
			        [Duration] = qsNow.total_elapsed_time - (COALESCE(qsFirst.total_elapsed_time, 0)),
                    [DurationPercent] = CAST(100.0 * (qsNow.total_elapsed_time - (COALESCE(qsFirst.total_elapsed_time, 0))) / (qsTotal.total_elapsed_time - qsTotalFirst.total_elapsed_time) AS DECIMAL(6,2)),
			        [CPU] = qsNow.total_worker_time - (COALESCE(qsFirst.total_worker_time, 0)),
                    [CPUPercent] = CAST(100.0 * (qsNow.total_worker_time - (COALESCE(qsFirst.total_worker_time, 0))) / (qsTotal.total_worker_time - qsTotalFirst.total_worker_time) AS DECIMAL(6,2)),
			        [Reads] = qsNow.total_logical_reads - (COALESCE(qsFirst.total_logical_reads, 0)),
                    [ReadsPercent] = CAST(100.0 * (qsNow.total_logical_reads - (COALESCE(qsFirst.total_logical_reads, 0))) / (qsTotal.total_logical_reads - qsTotalFirst.total_logical_reads) AS DECIMAL(6,2)),
                    [PlanCreationTime] = CONVERT(NVARCHAR(100), qsNow.creation_time ,121),
                    [TotalExecutions] = qsNow.execution_count,
                    [TotalExecutionsPercent] = CAST(100.0 * qsNow.execution_count / qsTotal.execution_count AS DECIMAL(6,2)),
                    [TotalDuration] = qsNow.total_elapsed_time,
                    [TotalDurationPercent] = CAST(100.0 * qsNow.total_elapsed_time / qsTotal.total_elapsed_time AS DECIMAL(6,2)),
                    [TotalCPU] = qsNow.total_worker_time,
                    [TotalCPUPercent] = CAST(100.0 * qsNow.total_worker_time / qsTotal.total_worker_time AS DECIMAL(6,2)),
                    [TotalReads] = qsNow.total_logical_reads,
                    [TotalReadsPercent] = CAST(100.0 * qsNow.total_logical_reads / qsTotal.total_logical_reads AS DECIMAL(6,2)),
                    r.[DetailsInt]
			FROM    #AskBrentResults r
				LEFT OUTER JOIN #QueryStats qsTotal ON qsTotal.Pass = 0
				LEFT OUTER JOIN #QueryStats qsTotalFirst ON qsTotalFirst.Pass = -1
				LEFT OUTER JOIN #QueryStats qsNow ON r.QueryStatsNowID = qsNow.ID
                LEFT OUTER JOIN #QueryStats qsFirst ON r.QueryStatsFirstID = qsFirst.ID
			ORDER BY r.Priority ,
					r.FindingsGroup ,
					r.Finding ,
					r.ID;
		END
		ELSE IF @OutputType IN ( 'CSV', 'RSV' ) 
		BEGIN

			SELECT  Result = CAST([Priority] AS NVARCHAR(100))
					+ @separator + CAST(CheckID AS NVARCHAR(100))
					+ @separator + COALESCE([FindingsGroup],
											'(N/A)') + @separator
					+ COALESCE([Finding], '(N/A)') + @separator
					+ COALESCE(DatabaseName, '(N/A)') + @separator
					+ COALESCE([URL], '(N/A)') + @separator
					+ COALESCE([Details], '(N/A)')
			FROM    #AskBrentResults
			ORDER BY Priority ,
					FindingsGroup ,
					Finding ,
					Details;
		END
		ELSE IF @ExpertMode = 0 AND @OutputXMLasNVARCHAR = 0
		BEGIN
			SELECT  [Priority] ,
					[FindingsGroup] ,
					[Finding] ,
					[URL] ,
					CAST(@StockDetailsHeader + [Details] + @StockDetailsFooter AS XML) AS Details,
					CAST(@StockWarningHeader + HowToStopIt + @StockWarningFooter AS XML) AS HowToStopIt,
					[QueryText],
					[QueryPlan]
			FROM    #AskBrentResults
			ORDER BY Priority ,
					FindingsGroup ,
					Finding ,
					ID;
		END
		ELSE IF @ExpertMode = 0 AND @OutputXMLasNVARCHAR = 1
		BEGIN
			SELECT  [Priority] ,
					[FindingsGroup] ,
					[Finding] ,
					[URL] ,
					CAST(@StockDetailsHeader + [Details] + @StockDetailsFooter AS NVARCHAR(MAX)) AS Details,
					CAST([HowToStopIt] AS NVARCHAR(MAX)) AS HowToStopIt,
					CAST([QueryText] AS NVARCHAR(MAX)) AS QueryText,
					CAST([QueryPlan] AS NVARCHAR(MAX)) AS QueryPlan
			FROM    #AskBrentResults
			ORDER BY Priority ,
					FindingsGroup ,
					Finding ,
					ID;
		END
		ELSE IF @ExpertMode = 1
		BEGIN
			SELECT  r.[Priority] ,
					r.[FindingsGroup] ,
					r.[Finding] ,
					r.[URL] ,
					CAST(@StockDetailsHeader + r.[Details] + @StockDetailsFooter AS XML) AS Details,
					CAST(@StockWarningHeader + r.HowToStopIt + @StockWarningFooter AS XML) AS HowToStopIt,
					r.[CheckID] ,
					r.[StartTime],
					r.[LoginName],
					r.[NTUserName],
					r.[OriginalLoginName],
					r.[ProgramName],
					r.[HostName],
					r.[DatabaseID],
					r.[DatabaseName],
					r.[OpenTransactionCount],
					r.[QueryPlan],
					r.[QueryText],
                    qsNow.plan_handle AS PlanHandle,
                    qsNow.sql_handle AS SqlHandle,
                    qsNow.statement_start_offset AS StatementStartOffset,
                    qsNow.statement_end_offset AS StatementEndOffset,
			        [Executions] = qsNow.execution_count - (COALESCE(qsFirst.execution_count, 0)),
                    [ExecutionsPercent] = CAST(100.0 * (qsNow.execution_count - (COALESCE(qsFirst.execution_count, 0))) / (qsTotal.execution_count - qsTotalFirst.execution_count) AS DECIMAL(6,2)),
			        [Duration] = qsNow.total_elapsed_time - (COALESCE(qsFirst.total_elapsed_time, 0)),
                    [DurationPercent] = CAST(100.0 * (qsNow.total_elapsed_time - (COALESCE(qsFirst.total_elapsed_time, 0))) / (qsTotal.total_elapsed_time - qsTotalFirst.total_elapsed_time) AS DECIMAL(6,2)),
			        [CPU] = qsNow.total_worker_time - (COALESCE(qsFirst.total_worker_time, 0)),
                    [CPUPercent] = CAST(100.0 * (qsNow.total_worker_time - (COALESCE(qsFirst.total_worker_time, 0))) / (qsTotal.total_worker_time - qsTotalFirst.total_worker_time) AS DECIMAL(6,2)),
			        [Reads] = qsNow.total_logical_reads - (COALESCE(qsFirst.total_logical_reads, 0)),
                    [ReadsPercent] = CAST(100.0 * (qsNow.total_logical_reads - (COALESCE(qsFirst.total_logical_reads, 0))) / (qsTotal.total_logical_reads - qsTotalFirst.total_logical_reads) AS DECIMAL(6,2)),
                    [PlanCreationTime] = CONVERT(NVARCHAR(100), qsNow.creation_time ,121),
                    [TotalExecutions] = qsNow.execution_count,
                    [TotalExecutionsPercent] = CAST(100.0 * qsNow.execution_count / qsTotal.execution_count AS DECIMAL(6,2)),
                    [TotalDuration] = qsNow.total_elapsed_time,
                    [TotalDurationPercent] = CAST(100.0 * qsNow.total_elapsed_time / qsTotal.total_elapsed_time AS DECIMAL(6,2)),
                    [TotalCPU] = qsNow.total_worker_time,
                    [TotalCPUPercent] = CAST(100.0 * qsNow.total_worker_time / qsTotal.total_worker_time AS DECIMAL(6,2)),
                    [TotalReads] = qsNow.total_logical_reads,
                    [TotalReadsPercent] = CAST(100.0 * qsNow.total_logical_reads / qsTotal.total_logical_reads AS DECIMAL(6,2)),
                    r.[DetailsInt]
			FROM    #AskBrentResults r
				LEFT OUTER JOIN #QueryStats qsTotal ON qsTotal.Pass = 0
				LEFT OUTER JOIN #QueryStats qsTotalFirst ON qsTotalFirst.Pass = -1
				LEFT OUTER JOIN #QueryStats qsNow ON r.QueryStatsNowID = qsNow.ID
                LEFT OUTER JOIN #QueryStats qsFirst ON r.QueryStatsFirstID = qsFirst.ID
			ORDER BY r.Priority ,
					r.FindingsGroup ,
					r.Finding ,
					r.ID;

			-------------------------
			--What happened: #WaitStats
			-------------------------
			;with max_batch as (
				select max(SampleTime) as SampleTime
				from #WaitStats
			)
			SELECT
				'WAIT STATS' as Pattern,
				b.SampleTime as [Sample Ended],
				datediff(ss,wd1.SampleTime, wd2.SampleTime) as [Seconds Sample],
				wd1.wait_type,
				c.[Wait Time (Seconds)],
				c.[Signal Wait Time (Seconds)],
				CASE WHEN c.[Wait Time (Seconds)] > 0
				 THEN CAST(100.*(c.[Signal Wait Time (Seconds)]/c.[Wait Time (Seconds)]) as NUMERIC(4,1))
				ELSE 0 END AS [Percent Signal Waits],
				(wd2.waiting_tasks_count - wd1.waiting_tasks_count) AS [Number of Waits],
				CASE WHEN (wd2.waiting_tasks_count - wd1.waiting_tasks_count) > 0
				THEN
					cast((wd2.wait_time_ms-wd1.wait_time_ms)/
						(1.0*(wd2.waiting_tasks_count - wd1.waiting_tasks_count)) as numeric(10,1))
				ELSE 0 END AS [Avg ms Per Wait]
			FROM  max_batch b
			JOIN #WaitStats wd2 on
				wd2.SampleTime =b.SampleTime
			JOIN #WaitStats wd1 ON 
				wd1.wait_type=wd2.wait_type AND
				wd2.SampleTime > wd1.SampleTime
			CROSS APPLY (SELECT
				cast((wd2.wait_time_ms-wd1.wait_time_ms)/1000. as numeric(10,1)) as [Wait Time (Seconds)],
				cast((wd2.signal_wait_time_ms - wd1.signal_wait_time_ms)/1000. as numeric(10,1)) as [Signal Wait Time (Seconds)]) AS c
			WHERE (wd2.waiting_tasks_count - wd1.waiting_tasks_count) > 0
				and wd2.wait_time_ms-wd1.wait_time_ms > 0
			ORDER BY [Wait Time (Seconds)] DESC;


			-------------------------
			--What happened: #FileStats
			-------------------------
			WITH readstats as (
				SELECT 'PHYSICAL READS' as Pattern,
				ROW_NUMBER() over (order by wd2.avg_stall_read_ms desc) as StallRank,
				wd2.SampleTime as [Sample Time], 
				datediff(ss,wd1.SampleTime, wd2.SampleTime) as [Sample (seconds)],
				wd1.DatabaseName ,
				wd1.FileLogicalName AS [File Name],
				UPPER(SUBSTRING(wd1.PhysicalName, 1, 2)) AS [Drive] ,
				wd1.SizeOnDiskMB ,
				( wd2.num_of_reads - wd1.num_of_reads ) AS [# Reads/Writes],
				CASE WHEN wd2.num_of_reads - wd1.num_of_reads > 0
				  THEN CAST(( wd2.bytes_read - wd1.bytes_read)/1024./1024. AS NUMERIC(21,1)) 
				  ELSE 0 
				END AS [MB Read/Written],
				wd2.avg_stall_read_ms AS [Avg Stall (ms)],
				wd1.PhysicalName AS [file physical name]
			FROM #FileStats wd2
				JOIN #FileStats wd1 ON wd2.SampleTime > wd1.SampleTime
				  AND wd1.DatabaseID = wd2.DatabaseID
				  AND wd1.FileID = wd2.FileID
			),
			writestats as (
				SELECT 
				'PHYSICAL WRITES' as Pattern,
				ROW_NUMBER() over (order by wd2.avg_stall_write_ms desc) as StallRank,
				wd2.SampleTime as [Sample Time], 
				datediff(ss,wd1.SampleTime, wd2.SampleTime) as [Sample (seconds)],
				wd1.DatabaseName ,
				wd1.FileLogicalName AS [File Name],
				UPPER(SUBSTRING(wd1.PhysicalName, 1, 2)) AS [Drive] ,
				wd1.SizeOnDiskMB ,
				( wd2.num_of_writes - wd1.num_of_writes ) AS [# Reads/Writes],
				CASE WHEN wd2.num_of_writes - wd1.num_of_writes > 0
				  THEN CAST(( wd2.bytes_written - wd1.bytes_written)/1024./1024. AS NUMERIC(21,1)) 
				  ELSE 0 
				END AS [MB Read/Written],
				wd2.avg_stall_write_ms AS [Avg Stall (ms)],
				wd1.PhysicalName AS [file physical name]
			FROM #FileStats wd2
				JOIN #FileStats wd1 ON wd2.SampleTime > wd1.SampleTime
				  AND wd1.DatabaseID = wd2.DatabaseID
				  AND wd1.FileID = wd2.FileID
			)
			SELECT 
				Pattern, [Sample Time], [Sample (seconds)], [File Name], [Drive],  [# Reads/Writes],[MB Read/Written],[Avg Stall (ms)], [file physical name]
			from readstats
			where StallRank <=5 and [MB Read/Written] > 0
			union all
			SELECT Pattern, [Sample Time], [Sample (seconds)], [File Name], [Drive],  [# Reads/Writes],[MB Read/Written],[Avg Stall (ms)], [file physical name]
			from writestats
			where StallRank <=5 and [MB Read/Written] > 0;


			-------------------------
			--What happened: #PerfmonStats
			-------------------------

			SELECT 'PERFMON' AS Pattern, pLast.[object_name], pLast.counter_name, pLast.instance_name, 
				pFirst.SampleTime AS FirstSampleTime, pFirst.cntr_value AS FirstSampleValue,
				pLast.SampleTime AS LastSampleTime, pLast.cntr_value AS LastSampleValue,
				pLast.cntr_value - pFirst.cntr_value AS ValueDelta,
				((1.0 * pLast.cntr_value - pFirst.cntr_value) / DATEDIFF(ss, pFirst.SampleTime, pLast.SampleTime)) AS ValuePerSecond
				FROM #PerfmonStats pLast
					INNER JOIN #PerfmonStats pFirst ON pFirst.[object_name] = pLast.[object_name] AND pFirst.counter_name = pLast.counter_name AND (pFirst.instance_name = pLast.instance_name OR (pFirst.instance_name IS NULL AND pLast.instance_name IS NULL))
					AND pLast.ID > pFirst.ID
				ORDER BY Pattern, pLast.[object_name], pLast.counter_name, pLast.instance_name


			-------------------------
			--What happened: #FileStats
			-------------------------
			SELECT qsNow.*, qsFirst.*
			FROM #QueryStats qsNow
			  INNER JOIN #QueryStats qsFirst ON qsNow.[sql_handle] = qsFirst.[sql_handle] AND qsNow.statement_start_offset = qsFirst.statement_start_offset AND qsNow.statement_end_offset = qsFirst.statement_end_offset AND qsNow.plan_generation_num = qsFirst.plan_generation_num AND qsNow.plan_handle = qsFirst.plan_handle AND qsFirst.Pass = 1
			WHERE qsNow.Pass = 2
		END

	DROP TABLE #AskBrentResults;


END /* IF @Question IS NULL */
ELSE IF @Question IS NOT NULL 

/* We're playing Magic SQL 8 Ball, so give them an answer. */
BEGIN
	IF OBJECT_ID('tempdb..#BrentAnswers') IS NOT NULL 
		DROP TABLE #BrentAnswers;
	CREATE TABLE #BrentAnswers(Answer VARCHAR(200) NOT NULL);
	INSERT INTO #BrentAnswers VALUES ('It sounds like a SAN problem.');
	INSERT INTO #BrentAnswers VALUES ('You know what you need? Bacon.');
	INSERT INTO #BrentAnswers VALUES ('Talk to the developers about that.');
	INSERT INTO #BrentAnswers VALUES ('Let''s post that on StackOverflow.com and find out.');
	INSERT INTO #BrentAnswers VALUES ('Have you tried adding an index?');
	INSERT INTO #BrentAnswers VALUES ('Have you tried dropping an index?');
	INSERT INTO #BrentAnswers VALUES ('You can''t prove anything.');
	INSERT INTO #BrentAnswers VALUES ('If you watched our Tuesday webcasts, you''d already know the answer to that.');
	INSERT INTO #BrentAnswers VALUES ('Please phrase the question in the form of an answer.');
	INSERT INTO #BrentAnswers VALUES ('Outlook not so good. Access even worse.');
	INSERT INTO #BrentAnswers VALUES ('Did you try asking the rubber duck? http://www.codinghorror.com/blog/2012/03/rubber-duck-problem-solving.html');
	INSERT INTO #BrentAnswers VALUES ('Oooo, I read about that once.');
	INSERT INTO #BrentAnswers VALUES ('I feel your pain.');
	INSERT INTO #BrentAnswers VALUES ('http://LMGTFY.com');
	INSERT INTO #BrentAnswers VALUES ('No comprende Ingles, senor.');
	INSERT INTO #BrentAnswers VALUES ('I don''t have that problem on my Mac.');
	INSERT INTO #BrentAnswers VALUES ('Is Priority Boost on?');
	INSERT INTO #BrentAnswers VALUES ('Have you tried rebooting your machine?');
	INSERT INTO #BrentAnswers VALUES ('Try defragging your cursors.');
	INSERT INTO #BrentAnswers VALUES ('Why are you wearing that? Do you have a job interview later or something?');
	INSERT INTO #BrentAnswers VALUES ('I''m ashamed that you don''t know the answer to that question.');
	INSERT INTO #BrentAnswers VALUES ('What do I look like, a Microsoft Certified Master? Oh, wait...');
	INSERT INTO #BrentAnswers VALUES ('Duh, Debra.');
	SELECT TOP 1 Answer FROM #BrentAnswers ORDER BY NEWID();
END

END /* ELSE IF @OutputType = 'SCHEMA' */

SET NOCOUNT OFF;
GO







IF OBJECT_ID('tempdb..##sp_Blitz') IS NULL
  EXEC ('CREATE PROCEDURE ##sp_Blitz AS RETURN 0;')
GO

ALTER PROCEDURE [##sp_Blitz]
    @CheckUserDatabaseObjects TINYINT = 1 ,
    @CheckProcedureCache TINYINT = 0 ,
    @OutputType VARCHAR(20) = 'TABLE' ,
    @OutputProcedureCache TINYINT = 0 ,
    @CheckProcedureCacheFilter VARCHAR(10) = NULL ,
    @CheckServerInfo TINYINT = 0 ,
    @SkipChecksServer NVARCHAR(256) = NULL ,
    @SkipChecksDatabase NVARCHAR(256) = NULL ,
    @SkipChecksSchema NVARCHAR(256) = NULL ,
    @SkipChecksTable NVARCHAR(256) = NULL ,
    @IgnorePrioritiesBelow INT = NULL ,
    @IgnorePrioritiesAbove INT = NULL ,
    @OutputDatabaseName NVARCHAR(128) = NULL ,
    @OutputSchemaName NVARCHAR(256) = NULL ,
    @OutputTableName NVARCHAR(256) = NULL ,
    @OutputXMLasNVARCHAR TINYINT = 0 ,
    @EmailRecipients VARCHAR(MAX) = NULL ,
    @EmailProfile sysname = NULL ,
    @SummaryMode TINYINT = 0 ,
    @Help TINYINT = 0 ,
    @Version INT = NULL OUTPUT,
    @VersionDate DATETIME = NULL OUTPUT
AS
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SELECT @Version = 40, @VersionDate = '20150427'

	IF @Help = 1 PRINT '
	/*
	sp_Blitz (TM) v40 - April 27, 2015

	(C) 2015, Brent Ozar Unlimited.
	See http://BrentOzar.com/go/eula for the End User Licensing Agreement.

	To learn more, visit http://www.BrentOzar.com/blitz where you can download
	new versions for free, watch training videos on how it works, get more info on
	the findings, and more.  To contribute code and see your name in the change
	log, email your improvements & checks to Help@BrentOzar.com.

	To request a feature or change: http://support.brentozar.com/
	To contribute code: http://www.brentozar.com/contributing-code/

	Known limitations of this version:
	 - No support for SQL Server 2000 or compatibility mode 80.
	 - If a database name has a question mark in it, some tests will fail. Gotta
	   love that unsupported sp_MSforeachdb.
	 - If you have offline databases, sp_Blitz fails the first time you run it,
	   but does work the second time. (Hoo, boy, this will be fun to debug.)

	Unknown limitations of this version:
	 - None.  (If we knew them, they would be known. Duh.)

  	Changes in v40 - April 27, 2015
	 - Added check 158 for 1MB growth sizes on databases over 10GB. Probably time
       to up that growth size. Contributed by Henrik Staun Poulsen.
     - Added check 159 for queries with more than 50 execution plans in cache,
       an indicator that it is not parameterized properly.
     - Fixed check 97 that said Data Center Edition was subject to CPU and
       memory limits, which is not true. It is only subject to wallet limits.
       Reported by Brad Nelson.
     - Fixed checks 106, 150, 151 to be skipped when the default trace file has
       disappeared. Coded by Steve Coles.
     - Fixed check 1, the VERY FIRST CHECK IN THE SCRIPT, which had a bug when
       catching databases that had never been backed up. Sure, there was a
       workaround in the next statement, but Julie Citro spotted the bug and
       made it right. First check, people. All of you who ever read this code,
       Julie Citro is officially a better code reviewer than you.
  	 - Skip backup checks on offline databases.
  	 - For order and join hints, raised threshold to 1000 instead of 1.
	 
  	Changes in v39 - February 16, 2015
	 - Added @OutputType option for NONE if you only want to log the results to
	    a table. (For Jefferson Elias.)
  	 - Bug fixes and improvements. (Thanks, Nathan Sunderman.)

 	Changes in v38 - November 20, 2014
 	 - Added check 157 for dangerous builds of SQL Server that are affected by
 	   MS Security Bulletin MS14-044.
	 - Added current date to output as check 156, priority 254. Requested by
	   Denise Crabtree, who runs sp_Blitz on a regular basis and saves the
	   results in a spreadsheet. Yay, Denise!
	 - Bug fixes and improvements to wait stats checks.

 	Changes in v37 - November 19, 2014
	 - Added wait stats checks when @CheckServerInfo = 1. Check 152 looks for
	   waits that have accounted for more than 10% of minimum possible wait
	   time. If your 4-core server has been up for 40 hours, that is 160 hours
	   of potential wait time (and of course it could be much higher when
	   multiple queries are stacked up on each core.) In that case, we only
	   alert on waits that have accounted for at least 16 hours of wait time.
	   We are trying to avoid false-alarming when servers are sitting idle.
	 - Added check 154 for 32-bit SQL Servers.
	 - Added check 155 for sp_Blitz versions more than 6 months old.

	For prior changes, see: http://www.BrentOzar.com/blitz/changelog/


	Parameter explanations:

	@CheckUserDatabaseObjects	1=review user databases for triggers, heaps, etc. Takes more time for more databases and objects.
	@CheckServerInfo			1=show server info like CPUs, memory, virtualization
	@CheckProcedureCache		1=top 20-50 resource-intensive cache plans and analyze them for common performance issues.
	@OutputProcedureCache		1=output the top 20-50 resource-intensive plans even if they did not trigger an alarm
	@CheckProcedureCacheFilter	''CPU'' | ''Reads'' | ''Duration'' | ''ExecCount''
	@OutputType					''TABLE''=table | ''COUNT''=row with number found | ''SCHEMA''=version and field list | ''NONE'' = none
	@IgnorePrioritiesBelow		100=ignore priorities below 100
	@IgnorePrioritiesAbove		100=ignore priorities above 100
	For the rest of the parameters, see http://www.brentozar.com/blitz/documentation for details.


	*/'
	ELSE IF @OutputType = 'SCHEMA'
	BEGIN
		SELECT @Version AS Version,
		FieldList = '[Priority] TINYINT, [FindingsGroup] VARCHAR(50), [Finding] VARCHAR(200), [DatabaseName] NVARCHAR(128), [URL] VARCHAR(200), [Details] NVARCHAR(4000), [QueryPlan] NVARCHAR(MAX), [QueryPlanFiltered] NVARCHAR(MAX), [CheckID] INT'

	END
	ELSE /* IF @OutputType = 'SCHEMA' */
	BEGIN

		/*
		We start by creating #BlitzResults. It's a temp table that will store all of
		the results from our checks. Throughout the rest of this stored procedure,
		we're running a series of checks looking for dangerous things inside the SQL
		Server. When we find a problem, we insert rows into #BlitzResults. At the
		end, we return these results to the end user.

		#BlitzResults has a CheckID field, but there's no Check table. As we do
		checks, we insert data into this table, and we manually put in the CheckID.
		We (Brent Ozar Unlimited) maintain a list of the checks by ID#. You can
		download that from http://www.BrentOzar.com/blitz/documentation/ - you'll
		see why it can help shortly.
		*/
		DECLARE @StringToExecute NVARCHAR(4000)
			,@curr_tracefilename NVARCHAR(500)
			,@base_tracefilename NVARCHAR(500)
			,@indx int
			,@query_result_separator CHAR(1)
			,@EmailSubject NVARCHAR(255)
			,@EmailBody NVARCHAR(MAX)
			,@EmailAttachmentFilename NVARCHAR(255)
			,@ProductVersion NVARCHAR(128)
			,@ProductVersionMajor DECIMAL(10,2)
			,@ProductVersionMinor DECIMAL(10,2)
			,@CurrentName NVARCHAR(128)
			,@CurrentDefaultValue NVARCHAR(200)
			,@CurrentCheckID INT
			,@CurrentPriority INT
			,@CurrentFinding VARCHAR(200)
			,@CurrentURL VARCHAR(200)
			,@CurrentDetails NVARCHAR(4000)
			,@MSSinceStartup DECIMAL(38,0)
			,@CPUMSsinceStartup DECIMAL(38,0);

		IF OBJECT_ID('tempdb..#BlitzResults') IS NOT NULL
			DROP TABLE #BlitzResults;
		CREATE TABLE #BlitzResults
			(
			  ID INT IDENTITY(1, 1) ,
			  CheckID INT ,
			  DatabaseName NVARCHAR(128) ,
			  Priority TINYINT ,
			  FindingsGroup VARCHAR(50) ,
			  Finding VARCHAR(200) ,
			  URL VARCHAR(200) ,
			  Details NVARCHAR(4000) ,
			  QueryPlan [XML] NULL ,
			  QueryPlanFiltered [NVARCHAR](MAX) NULL
			);

		/*
		You can build your own table with a list of checks to skip. For example, you
		might have some databases that you don't care about, or some checks you don't
		want to run. Then, when you run sp_Blitz, you can specify these parameters:
		@SkipChecksDatabase = 'DBAtools',
		@SkipChecksSchema = 'dbo',
		@SkipChecksTable = 'BlitzChecksToSkip'
		Pass in the database, schema, and table that contains the list of checks you
		want to skip. This part of the code checks those parameters, gets the list,
		and then saves those in a temp table. As we run each check, we'll see if we
		need to skip it.

		Really anal-retentive users will note that the @SkipChecksServer parameter is
		not used. YET. We added that parameter in so that we could avoid changing the
		stored proc's surface area (interface) later.
		*/
		IF OBJECT_ID('tempdb..#SkipChecks') IS NOT NULL
			DROP TABLE #SkipChecks;
		CREATE TABLE #SkipChecks
			(
			  DatabaseName NVARCHAR(128) ,
			  CheckID INT ,
			  ServerName NVARCHAR(128)
			);
		CREATE CLUSTERED INDEX IX_CheckID_DatabaseName ON #SkipChecks(CheckID, DatabaseName);

		IF @SkipChecksTable IS NOT NULL
			AND @SkipChecksSchema IS NOT NULL
			AND @SkipChecksDatabase IS NOT NULL
			BEGIN
				SET @StringToExecute = 'INSERT INTO #SkipChecks(DatabaseName, CheckID, ServerName )
				SELECT DISTINCT DatabaseName, CheckID, ServerName
				FROM ' + QUOTENAME(@SkipChecksDatabase) + '.' + QUOTENAME(@SkipChecksSchema) + '.' + QUOTENAME(@SkipChecksTable)
					+ ' WHERE ServerName IS NULL OR ServerName = SERVERPROPERTY(''ServerName'');'
				EXEC(@StringToExecute)
			END

		IF NOT EXISTS ( SELECT  1
							FROM    #SkipChecks
							WHERE   DatabaseName IS NULL AND CheckID = 106 )
							AND (select convert(int,value_in_use) from sys.configurations where name = 'default trace enabled' ) = 1
			BEGIN
					select @curr_tracefilename = [path] from sys.traces where is_default = 1 ;
					set @curr_tracefilename = reverse(@curr_tracefilename);
					select @indx = patindex('%\%', @curr_tracefilename) ;
					set @curr_tracefilename = reverse(@curr_tracefilename) ;
					set @base_tracefilename = left( @curr_tracefilename,len(@curr_tracefilename) - @indx) + '\log.trc' ;
			END


		/*
		That's the end of the SkipChecks stuff.
		The next several tables are used by various checks later.
		*/
		IF OBJECT_ID('tempdb..#ConfigurationDefaults') IS NOT NULL
			DROP TABLE #ConfigurationDefaults;
		CREATE TABLE #ConfigurationDefaults
			(
			  name NVARCHAR(128) ,
			  DefaultValue BIGINT,
			  CheckID INT
			);

		IF OBJECT_ID('tempdb..#DatabaseDefaults') IS NOT NULL
			DROP TABLE #DatabaseDefaults;
		CREATE TABLE #DatabaseDefaults
			(
				name NVARCHAR(128) ,
				DefaultValue NVARCHAR(200),
				CheckID INT,
		        Priority INT,
		        Finding VARCHAR(200),
		        URL VARCHAR(200),
		        Details NVARCHAR(4000)
			);



		IF OBJECT_ID('tempdb..#DBCCs') IS NOT NULL
			DROP TABLE #DBCCs;
		CREATE TABLE #DBCCs
			(
			  ID INT IDENTITY(1, 1)
					 PRIMARY KEY ,
			  ParentObject VARCHAR(255) ,
			  Object VARCHAR(255) ,
			  Field VARCHAR(255) ,
			  Value VARCHAR(255) ,
			  DbName NVARCHAR(128) NULL
			)


		IF OBJECT_ID('tempdb..#LogInfo2012') IS NOT NULL
			DROP TABLE #LogInfo2012;
		CREATE TABLE #LogInfo2012
			(
			  recoveryunitid INT ,
			  FileID SMALLINT ,
			  FileSize BIGINT ,
			  StartOffset BIGINT ,
			  FSeqNo BIGINT ,
			  [Status] TINYINT ,
			  Parity TINYINT ,
			  CreateLSN NUMERIC(38)
			);

		IF OBJECT_ID('tempdb..#LogInfo') IS NOT NULL
			DROP TABLE #LogInfo;
		CREATE TABLE #LogInfo
			(
			  FileID SMALLINT ,
			  FileSize BIGINT ,
			  StartOffset BIGINT ,
			  FSeqNo BIGINT ,
			  [Status] TINYINT ,
			  Parity TINYINT ,
			  CreateLSN NUMERIC(38)
			);

		IF OBJECT_ID('tempdb..#partdb') IS NOT NULL
			DROP TABLE #partdb;
		CREATE TABLE #partdb
			(
			  dbname NVARCHAR(128) ,
			  objectname NVARCHAR(200) ,
			  type_desc NVARCHAR(128)
			)

		IF OBJECT_ID('tempdb..#TraceStatus') IS NOT NULL
			DROP TABLE #TraceStatus;
		CREATE TABLE #TraceStatus
			(
			  TraceFlag VARCHAR(10) ,
			  status BIT ,
			  Global BIT ,
			  Session BIT
			);

		IF OBJECT_ID('tempdb..#driveInfo') IS NOT NULL
			DROP TABLE #driveInfo;
		CREATE TABLE #driveInfo
			(
			  drive NVARCHAR ,
			  SIZE DECIMAL(18, 2)
			)


		IF OBJECT_ID('tempdb..#dm_exec_query_stats') IS NOT NULL
			DROP TABLE #dm_exec_query_stats;
		CREATE TABLE #dm_exec_query_stats
			(
			  [id] [int] NOT NULL
						 IDENTITY(1, 1) ,
			  [sql_handle] [varbinary](64) NOT NULL ,
			  [statement_start_offset] [int] NOT NULL ,
			  [statement_end_offset] [int] NOT NULL ,
			  [plan_generation_num] [bigint] NOT NULL ,
			  [plan_handle] [varbinary](64) NOT NULL ,
			  [creation_time] [datetime] NOT NULL ,
			  [last_execution_time] [datetime] NOT NULL ,
			  [execution_count] [bigint] NOT NULL ,
			  [total_worker_time] [bigint] NOT NULL ,
			  [last_worker_time] [bigint] NOT NULL ,
			  [min_worker_time] [bigint] NOT NULL ,
			  [max_worker_time] [bigint] NOT NULL ,
			  [total_physical_reads] [bigint] NOT NULL ,
			  [last_physical_reads] [bigint] NOT NULL ,
			  [min_physical_reads] [bigint] NOT NULL ,
			  [max_physical_reads] [bigint] NOT NULL ,
			  [total_logical_writes] [bigint] NOT NULL ,
			  [last_logical_writes] [bigint] NOT NULL ,
			  [min_logical_writes] [bigint] NOT NULL ,
			  [max_logical_writes] [bigint] NOT NULL ,
			  [total_logical_reads] [bigint] NOT NULL ,
			  [last_logical_reads] [bigint] NOT NULL ,
			  [min_logical_reads] [bigint] NOT NULL ,
			  [max_logical_reads] [bigint] NOT NULL ,
			  [total_clr_time] [bigint] NOT NULL ,
			  [last_clr_time] [bigint] NOT NULL ,
			  [min_clr_time] [bigint] NOT NULL ,
			  [max_clr_time] [bigint] NOT NULL ,
			  [total_elapsed_time] [bigint] NOT NULL ,
			  [last_elapsed_time] [bigint] NOT NULL ,
			  [min_elapsed_time] [bigint] NOT NULL ,
			  [max_elapsed_time] [bigint] NOT NULL ,
			  [query_hash] [binary](8) NULL ,
			  [query_plan_hash] [binary](8) NULL ,
			  [query_plan] [xml] NULL ,
			  [query_plan_filtered] [nvarchar](MAX) NULL ,
			  [text] [nvarchar](MAX) COLLATE SQL_Latin1_General_CP1_CI_AS
									 NULL ,
			  [text_filtered] [nvarchar](MAX) COLLATE SQL_Latin1_General_CP1_CI_AS
											  NULL
			)

        /* Used for the default trace checks. */
        DECLARE @TracePath NVARCHAR(256);
        SELECT @TracePath=CAST(value as NVARCHAR(256))
            FROM sys.fn_trace_getinfo(1)
            WHERE traceid=1 AND property=2;
        
        SELECT @MSSinceStartup = DATEDIFF(MINUTE, create_date, CURRENT_TIMESTAMP)
            FROM    sys.databases
            WHERE   name='tempdb';

		SET @MSSinceStartup = @MSSinceStartup * 60000;

		SELECT @CPUMSsinceStartup = @MSSinceStartup * cpu_count
			FROM sys.dm_os_sys_info;


		/* If we're outputting CSV, don't bother checking the plan cache because we cannot export plans. */
		IF @OutputType = 'CSV'
			SET @CheckProcedureCache = 0;

		/* Sanitize our inputs */
		SELECT
			@OutputDatabaseName = QUOTENAME(@OutputDatabaseName),
			@OutputSchemaName = QUOTENAME(@OutputSchemaName),
			@OutputTableName = QUOTENAME(@OutputTableName)

		/* Get the major and minor build numbers */
		SET @ProductVersion = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
		SELECT @ProductVersionMajor = SUBSTRING(@ProductVersion, 1,CHARINDEX('.', @ProductVersion) + 1 ),
			@ProductVersionMinor = PARSENAME(CONVERT(varchar(32), @ProductVersion), 2)


		/*
		Whew! we're finally done with the setup, and we can start doing checks.
		First, let's make sure we're actually supposed to do checks on this server.
		The user could have passed in a SkipChecks table that specified to skip ALL
		checks on this server, so let's check for that:
		*/
		IF ( ( SERVERPROPERTY('ServerName') NOT IN ( SELECT ServerName
													 FROM   #SkipChecks
													 WHERE  DatabaseName IS NULL
															AND CheckID IS NULL ) )
			 OR ( @SkipChecksTable IS NULL )
		   )
			BEGIN

				/*
				Our very first check! We'll put more comments in this one just to
				explain exactly how it works. First, we check to see if we're
				supposed to skip CheckID 1 (that's the check we're working on.)
				*/
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 1 )
					BEGIN

						/*
						Below, we check master.sys.databases looking for databases
						that haven't had a backup in the last week. If we find any,
						we insert them into #BlitzResults, the temp table that
						tracks our server's problems. Note that if the check does
						NOT find any problems, we don't save that. We're only
						saving the problems, not the successful checks.
						*/
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  1 AS CheckID ,
										d.[name] AS DatabaseName ,
										1 AS Priority ,
										'Backup' AS FindingsGroup ,
										'Backups Not Performed Recently' AS Finding ,
										'http://BrentOzar.com/go/nobak' AS URL ,
										'Database ' + d.Name + ' last backed up: '
										+ COALESCE(CAST(MAX(b.backup_finish_date) AS VARCHAR(25)),'never') AS Details
								FROM    master.sys.databases d
										LEFT OUTER JOIN msdb.dbo.backupset b ON d.name COLLATE SQL_Latin1_General_CP1_CI_AS = b.database_name COLLATE SQL_Latin1_General_CP1_CI_AS
																  AND b.type = 'D'
																  AND b.server_name = SERVERPROPERTY('ServerName') /*Backupset ran on current server */
								WHERE   d.database_id <> 2  /* Bonus points if you know what that means */
										AND d.state NOT IN(1, 6, 10) /* Not currently offline or restoring, like log shipping databases */
										AND d.is_in_standby = 0 /* Not a log shipping target database */
										AND d.source_database_id IS NULL /* Excludes database snapshots */
										AND d.name NOT IN ( SELECT DISTINCT
																  DatabaseName
															FROM  #SkipChecks
															WHERE CheckID IS NULL )
										/*
										The above NOT IN filters out the databases we're not supposed to check.
										*/
								GROUP BY d.name
								HAVING  MAX(b.backup_finish_date) <= DATEADD(dd,
																  -7, GETDATE())
                                        OR MAX(b.backup_finish_date) IS NULL;
						/*
						And there you have it. The rest of this stored procedure works the same
						way: it asks:
						- Should I skip this check?
						- If not, do I find problems?
						- Insert the results into #BlitzResults
						*/

					END

				/*
				And that's the end of CheckID #1.

				CheckID #2 is a little simpler because it only involves one query, and it's
				more typical for queries that people contribute. But keep reading, because
				the next check gets more complex again.
				*/

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 2 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										2 AS CheckID ,
										d.name AS DatabaseName ,
										1 AS Priority ,
										'Backup' AS FindingsGroup ,
										'Full Recovery Mode w/o Log Backups' AS Finding ,
										'http://BrentOzar.com/go/biglogs' AS URL ,
										( 'Database ' + ( d.Name COLLATE database_default )
										  + ' is in ' + d.recovery_model_desc
										  + ' recovery mode but has not had a log backup in the last week.' ) AS Details
								FROM    master.sys.databases d
								WHERE   d.recovery_model IN ( 1, 2 )
										AND d.database_id NOT IN ( 2, 3 )
										AND d.source_database_id IS NULL
										AND d.state <> 1 /* Not currently restoring, like log shipping databases */
										AND d.is_in_standby = 0 /* Not a log shipping target database */
										AND d.source_database_id IS NULL /* Excludes database snapshots */
										AND d.name NOT IN ( SELECT DISTINCT
																  DatabaseName
															FROM  #SkipChecks
															WHERE CheckID IS NULL )
										AND NOT EXISTS ( SELECT *
														 FROM   msdb.dbo.backupset b
														 WHERE  d.name COLLATE SQL_Latin1_General_CP1_CI_AS = b.database_name COLLATE SQL_Latin1_General_CP1_CI_AS
																AND b.type = 'L'
																AND b.backup_finish_date >= DATEADD(dd,
																  -7, GETDATE()) );
					END


				/*
				Next up, we've got CheckID 8. (These don't have to go in order.) This one
				won't work on SQL Server 2005 because it relies on a new DMV that didn't
				exist prior to SQL Server 2008. This means we have to check the SQL Server
				version first, then build a dynamic string with the query we want to run:
				*/

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 8 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID, Priority,
							FindingsGroup,
							Finding, URL,
							Details)
					  SELECT 8 AS CheckID,
					  150 AS Priority,
					  ''Security'' AS FindingsGroup,
					  ''Server Audits Running'' AS Finding,
					  ''http://BrentOzar.com/go/audits'' AS URL,
					  (''SQL Server built-in audit functionality is being used by server audit: '' + [name]) AS Details FROM sys.dm_server_audit_status'
								EXECUTE(@StringToExecute)
							END;
					END

				/*
				But what if you need to run a query in every individual database?
				Check out CheckID 99 below. Yes, it uses sp_MSforeachdb, and no,
				we're not happy about that. sp_MSforeachdb is known to have a lot
				of issues, like skipping databases sometimes. However, this is the
				only built-in option that we have. If you're writing your own code
				for database maintenance, consider Aaron Bertrand's alternative:
				http://www.mssqltips.com/sqlservertip/2201/making-a-more-reliable-and-flexible-spmsforeachdb/
				We don't include that as part of sp_Blitz, of course, because
				copying and distributing copyrighted code from others without their
				written permission isn't a good idea.
				*/
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 99 )
					BEGIN
						EXEC dbo.sp_MSforeachdb 'USE [?];  IF EXISTS (SELECT * FROM  sys.tables WITH (NOLOCK) WHERE name = ''sysmergepublications'' ) IF EXISTS ( SELECT * FROM sysmergepublications WITH (NOLOCK) WHERE retention = 0)   INSERT INTO #BlitzResults (CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 99, DB_NAME(), 110, ''Performance'', ''Infinite merge replication metadata retention period'', ''http://BrentOzar.com/go/merge'', (''The ['' + DB_NAME() + ''] database has merge replication metadata retention period set to infinite - this can be the case of significant performance issues.'')';
					END
				/*
				Note that by using sp_MSforeachdb, we're running the query in all
				databases. We're not checking #SkipChecks here for each database to
				see if we should run the check in this database. That means we may
				still run a skipped check if it involves sp_MSforeachdb. We just
				don't output those results in the last step.

				And that's the basic idea! You can read through the rest of the
				checks if you like - some more exciting stuff happens closer to the
				end of the stored proc, where we start doing things like checking
				the plan cache, but those aren't as cleanly commented.

				If you'd like to contribute your own check, use one of the check
				formats shown above and email it to Help@BrentOzar.com. You don't
				have to pick a CheckID or a link - we'll take care of that when we
				test and publish the code. Thanks!
				*/


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 93 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										93 AS CheckID ,
										1 AS Priority ,
										'Backup' AS FindingsGroup ,
										'Backing Up to Same Drive Where Databases Reside' AS Finding ,
										'http://BrentOzar.com/go/backup' AS URL ,
										'Drive '
										+ UPPER(LEFT(bmf.physical_device_name, 3))
										+ ' houses both database files AND backups taken in the last two weeks. This represents a serious risk if that array fails.' Details
								FROM    msdb.dbo.backupmediafamily AS bmf
										INNER JOIN msdb.dbo.backupset AS bs ON bmf.media_set_id = bs.media_set_id
																  AND bs.backup_start_date >= ( DATEADD(dd,
																  -14, GETDATE()) )
								WHERE   UPPER(LEFT(bmf.physical_device_name COLLATE SQL_Latin1_General_CP1_CI_AS, 3)) IN (
										SELECT DISTINCT
												UPPER(LEFT(mf.physical_name COLLATE SQL_Latin1_General_CP1_CI_AS, 3))
										FROM    sys.master_files AS mf )
					END


					IF NOT EXISTS ( SELECT  1
									FROM    #SkipChecks
									WHERE   DatabaseName IS NULL AND CheckID = 119 )
						AND EXISTS ( SELECT *
									 FROM   sys.all_objects o
									 WHERE  o.name = 'dm_database_encryption_keys' )
						BEGIN
							SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, DatabaseName, URL, Details)
								SELECT 119 AS CheckID,
								1 AS Priority,
								''Backup'' AS FindingsGroup,
								''TDE Certificate Not Backed Up Recently'' AS Finding,
								db_name(dek.database_id) AS DatabaseName,
								''http://BrentOzar.com/go/tde'' AS URL,
								''The certificate '' + c.name + '' is used to encrypt database '' + db_name(dek.database_id) + ''. Last backup date: '' + COALESCE(CAST(c.pvt_key_last_backup_date AS VARCHAR(100)), ''Never'') AS Details
								FROM sys.certificates c INNER JOIN sys.dm_database_encryption_keys dek ON c.thumbprint = dek.encryptor_thumbprint
								WHERE pvt_key_last_backup_date IS NULL OR pvt_key_last_backup_date <= DATEADD(dd, -30, GETDATE())';
							EXECUTE(@StringToExecute);
						END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 3 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT TOP 1
										3 AS CheckID ,
										'msdb' ,
										200 AS Priority ,
										'Backup' AS FindingsGroup ,
										'MSDB Backup History Not Purged' AS Finding ,
										'http://BrentOzar.com/go/history' AS URL ,
										( 'Database backup history retained back to '
										  + CAST(bs.backup_start_date AS VARCHAR(20)) ) AS Details
								FROM    msdb.dbo.backupset bs
								WHERE   bs.backup_start_date <= DATEADD(dd, -60,
																  GETDATE())
								ORDER BY backup_set_id ASC;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 4 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  4 AS CheckID ,
										10 AS Priority ,
										'Security' AS FindingsGroup ,
										'Sysadmins' AS Finding ,
										'http://BrentOzar.com/go/sa' AS URL ,
										( 'Login [' + l.name
										  + '] is a sysadmin - meaning they can do absolutely anything in SQL Server, including dropping databases or hiding their tracks.' ) AS Details
								FROM    master.sys.syslogins l
								WHERE   l.sysadmin = 1
										AND l.name <> SUSER_SNAME(0x01)
										AND l.denylogin = 0;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 5 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  5 AS CheckID ,
										10 AS Priority ,
										'Security' AS FindingsGroup ,
										'Security Admins' AS Finding ,
										'http://BrentOzar.com/go/sa' AS URL ,
										( 'Login [' + l.name
										  + '] is a security admin - meaning they can give themselves permission to do absolutely anything in SQL Server, including dropping databases or hiding their tracks.' ) AS Details
								FROM    master.sys.syslogins l
								WHERE   l.securityadmin = 1
										AND l.name <> SUSER_SNAME(0x01)
										AND l.denylogin = 0;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 104 )
					BEGIN
						INSERT  INTO #BlitzResults
								( [CheckID] ,
								  [Priority] ,
								  [FindingsGroup] ,
								  [Finding] ,
								  [URL] ,
								  [Details]
								)
								SELECT  104 AS [CheckID] ,
										10 AS [Priority] ,
										'Security' AS [FindingsGroup] ,
										'Login Can Control Server' AS [Finding] ,
										'http://BrentOzar.com/go/sa' AS [URL] ,
										'Login [' + pri.[name]
										+ '] has the CONTROL SERVER permission - meaning they can do absolutely anything in SQL Server, including dropping databases or hiding their tracks.' AS [Details]
								FROM    sys.server_principals AS pri
								WHERE   pri.[principal_id] IN (
										SELECT  p.[grantee_principal_id]
										FROM    sys.server_permissions AS p
										WHERE   p.[state] IN ( 'G', 'W' )
												AND p.[class] = 100
												AND p.[type] = 'CL' )
										AND pri.[name] NOT LIKE '##%##'
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 6 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  6 AS CheckID ,
										200 AS Priority ,
										'Security' AS FindingsGroup ,
										'Jobs Owned By Users' AS Finding ,
										'http://BrentOzar.com/go/owners' AS URL ,
										( 'Job [' + j.name + '] is owned by ['
										  + SUSER_SNAME(j.owner_sid)
										  + '] - meaning if their login is disabled or not available due to Active Directory problems, the job will stop working.' ) AS Details
								FROM    msdb.dbo.sysjobs j
								WHERE   j.enabled = 1
										AND SUSER_SNAME(j.owner_sid) <> SUSER_SNAME(0x01);
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 7 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  7 AS CheckID ,
										10 AS Priority ,
										'Security' AS FindingsGroup ,
										'Stored Procedure Runs at Startup' AS Finding ,
										'http://BrentOzar.com/go/startup' AS URL ,
										( 'Stored procedure [master].['
										  + r.SPECIFIC_SCHEMA + '].['
										  + r.SPECIFIC_NAME
										  + '] runs automatically when SQL Server starts up.  Make sure you know exactly what this stored procedure is doing, because it could pose a security risk.' ) AS Details
								FROM    master.INFORMATION_SCHEMA.ROUTINES r
								WHERE   OBJECTPROPERTY(OBJECT_ID(ROUTINE_NAME),
													   'ExecIsStartup') = 1;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 9 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID,
							Priority,
							FindingsGroup,
							Finding,
							URL,
							Details)
					  SELECT 9 AS CheckID,
					  200 AS Priority,
					  ''Surface Area'' AS FindingsGroup,
					  ''Endpoints Configured'' AS Finding,
					  ''http://BrentOzar.com/go/endpoints/'' AS URL,
					  (''SQL Server endpoints are configured.  These can be used for database mirroring or Service Broker, but if you do not need them, avoid leaving them enabled.  Endpoint name: '' + [name]) AS Details FROM sys.endpoints WHERE type <> 2'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 10 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID,
							Priority,
							FindingsGroup,
							Finding,
							URL,
							Details)
					  SELECT 10 AS CheckID,
					  100 AS Priority,
					  ''Performance'' AS FindingsGroup,
					  ''Resource Governor Enabled'' AS Finding,
					  ''http://BrentOzar.com/go/rg'' AS URL,
					  (''Resource Governor is enabled.  Queries may be throttled.  Make sure you understand how the Classifier Function is configured.'') AS Details FROM sys.resource_governor_configuration WHERE is_enabled = 1'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 11 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID,
							Priority,
							FindingsGroup,
							Finding,
							URL,
							Details)
					  SELECT 11 AS CheckID,
					  100 AS Priority,
					  ''Performance'' AS FindingsGroup,
					  ''Server Triggers Enabled'' AS Finding,
					  ''http://BrentOzar.com/go/logontriggers/'' AS URL,
					  (''Server Trigger ['' + [name] ++ ''] is enabled, so it runs every time someone logs in.  Make sure you understand what that trigger is doing - the less work it does, the better.'') AS Details FROM sys.server_triggers WHERE is_disabled = 0 AND is_ms_shipped = 0'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 12 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  12 AS CheckID ,
										[name] AS DatabaseName ,
										10 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Auto-Close Enabled' AS Finding ,
										'http://BrentOzar.com/go/autoclose' AS URL ,
										( 'Database [' + [name]
										  + '] has auto-close enabled.  This setting can dramatically decrease performance.' ) AS Details
								FROM    sys.databases
								WHERE   is_auto_close_on = 1
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 13 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  13 AS CheckID ,
										[name] AS DatabaseName ,
										10 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Auto-Shrink Enabled' AS Finding ,
										'http://BrentOzar.com/go/autoshrink' AS URL ,
										( 'Database [' + [name]
										  + '] has auto-shrink enabled.  This setting can dramatically decrease performance.' ) AS Details
								FROM    sys.databases
								WHERE   is_auto_shrink_on = 1
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks );
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 14 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID,
							DatabaseName,
							Priority,
							FindingsGroup,
							Finding,
							URL,
							Details)
					  SELECT 14 AS CheckID,
					  [name] as DatabaseName,
					  50 AS Priority,
					  ''Reliability'' AS FindingsGroup,
					  ''Page Verification Not Optimal'' AS Finding,
					  ''http://BrentOzar.com/go/torn'' AS URL,
					  (''Database ['' + [name] + ''] has '' + [page_verify_option_desc] + '' for page verification.  SQL Server may have a harder time recognizing and recovering from storage corruption.  Consider using CHECKSUM instead.'') COLLATE database_default AS Details
					  FROM sys.databases
					  WHERE page_verify_option < 2
					  AND name <> ''tempdb''
					  and name not in (select distinct DatabaseName from #SkipChecks)'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 15 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  15 AS CheckID ,
										[name] AS DatabaseName ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Auto-Create Stats Disabled' AS Finding ,
										'http://BrentOzar.com/go/acs' AS URL ,
										( 'Database [' + [name]
										  + '] has auto-create-stats disabled.  SQL Server uses statistics to build better execution plans, and without the ability to automatically create more, performance may suffer.' ) AS Details
								FROM    sys.databases
								WHERE   is_auto_create_stats_on = 0
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 16 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  16 AS CheckID ,
										[name] AS DatabaseName ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Auto-Update Stats Disabled' AS Finding ,
										'http://BrentOzar.com/go/aus' AS URL ,
										( 'Database [' + [name]
										  + '] has auto-update-stats disabled.  SQL Server uses statistics to build better execution plans, and without the ability to automatically update them, performance may suffer.' ) AS Details
								FROM    sys.databases
								WHERE   is_auto_update_stats_on = 0
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 17 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  17 AS CheckID ,
										[name] AS DatabaseName ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Stats Updated Asynchronously' AS Finding ,
										'http://BrentOzar.com/go/asyncstats' AS URL ,
										( 'Database [' + [name]
										  + '] has auto-update-stats-async enabled.  When SQL Server gets a query for a table with out-of-date statistics, it will run the query with the stats it has - while updating stats to make later queries better. The initial run of the query may suffer, though.' ) AS Details
								FROM    sys.databases
								WHERE   is_auto_update_stats_async_on = 1
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 18 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  18 AS CheckID ,
										[name] AS DatabaseName ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Forced Parameterization On' AS Finding ,
										'http://BrentOzar.com/go/forced' AS URL ,
										( 'Database [' + [name]
										  + '] has forced parameterization enabled.  SQL Server will aggressively reuse query execution plans even if the applications do not parameterize their queries.  This can be a performance booster with some programming languages, or it may use universally bad execution plans when better alternatives are available for certain parameters.' ) AS Details
								FROM    sys.databases
								WHERE   is_parameterization_forced = 1
										AND name NOT IN ( SELECT  DatabaseName
														  FROM    #SkipChecks )
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 19 )
					BEGIN
						/* Method 1: Check sys.databases parameters */
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)

								SELECT  19 AS CheckID ,
										[name] AS DatabaseName ,
										200 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Replication In Use' AS Finding ,
										'http://BrentOzar.com/go/repl' AS URL ,
										( 'Database [' + [name]
										  + '] is a replication publisher, subscriber, or distributor.' ) AS Details
								FROM    sys.databases
								WHERE   name NOT IN ( SELECT DISTINCT
																DatabaseName
													  FROM      #SkipChecks )
										AND is_published = 1
										OR is_subscribed = 1
										OR is_merge_published = 1
										OR is_distributor = 1;

						/* Method B: check subscribers for MSreplication_objects tables */
						EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults
										(CheckID,
										DatabaseName,
										Priority,
										FindingsGroup,
										Finding,
										URL,
										Details)
							  SELECT DISTINCT 19,
							  db_name(),
							  200,
							  ''Informational'',
							  ''Replication In Use'',
							  ''http://BrentOzar.com/go/repl'',
							  (''['' + DB_NAME() + ''] has MSreplication_objects tables in it, indicating it is a replication subscriber.'')
							  FROM [?].sys.tables
							  WHERE name = ''dbo.MSreplication_objects'' AND ''?'' <> ''master''';

					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 20 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  20 AS CheckID ,
										[name] AS DatabaseName ,
										110 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Date Correlation On' AS Finding ,
										'http://BrentOzar.com/go/corr' AS URL ,
										( 'Database [' + [name]
										  + '] has date correlation enabled.  This is not a default setting, and it has some performance overhead.  It tells SQL Server that date fields in two tables are related, and SQL Server maintains statistics showing that relation.' ) AS Details
								FROM    sys.databases
								WHERE   is_date_correlation_on = 1
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 21 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
							(CheckID,
							DatabaseName,
							Priority,
							FindingsGroup,
							Finding,
							URL,
							Details)
					  SELECT 21 AS CheckID,
					  [name] as DatabaseName,
					  20 AS Priority,
					  ''Encryption'' AS FindingsGroup,
					  ''Database Encrypted'' AS Finding,
					  ''http://BrentOzar.com/go/tde'' AS URL,
					  (''Database ['' + [name] + ''] has Transparent Data Encryption enabled.  Make absolutely sure you have backed up the certificate and private key, or else you will not be able to restore this database.'') AS Details
					  FROM sys.databases
					  WHERE is_encrypted = 1
					  and name not in (select distinct DatabaseName from #SkipChecks)'
								EXECUTE(@StringToExecute)
							END;
					END

				/*
				Believe it or not, SQL Server doesn't track the default values
				for sp_configure options! We'll make our own list here.
				*/
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'access check cache bucket count', 0, 1001 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'access check cache quota', 0, 1002 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Ad Hoc Distributed Queries', 0, 1003 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'affinity I/O mask', 0, 1004 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'affinity mask', 0, 1005 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Agent XPs', 0, 1006 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'allow updates', 0, 1007 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'awe enabled', 0, 1008 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'blocked process threshold', 0, 1009 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'c2 audit mode', 0, 1010 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'clr enabled', 0, 1011 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'cost threshold for parallelism', 5, 1012 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'cross db ownership chaining', 0, 1013 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'cursor threshold', -1, 1014 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Database Mail XPs', 0, 1015 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'default full-text language', 1033, 1016 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'default language', 0, 1017 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'default trace enabled', 1, 1018 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'disallow results from triggers', 0, 1019 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'fill factor (%)', 0, 1020 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'ft crawl bandwidth (max)', 100, 1021 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'ft crawl bandwidth (min)', 0, 1022 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'ft notify bandwidth (max)', 100, 1023 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'ft notify bandwidth (min)', 0, 1024 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'index create memory (KB)', 0, 1025 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'in-doubt xact resolution', 0, 1026 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'lightweight pooling', 0, 1027 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'locks', 0, 1028 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'max degree of parallelism', 0, 1029 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'max full-text crawl range', 4, 1030 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'max server memory (MB)', 2147483647, 1031 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'max text repl size (B)', 65536, 1032 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'max worker threads', 0, 1033 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'media retention', 0, 1034 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'min memory per query (KB)', 1024, 1035 );
				/* Accepting both 0 and 16 below because both have been seen in the wild as defaults. */
				IF EXISTS ( SELECT  *
							FROM    sys.configurations
							WHERE   name = 'min server memory (MB)'
									AND value_in_use IN ( 0, 16 ) )
					INSERT  INTO #ConfigurationDefaults
							SELECT  'min server memory (MB)' ,
									CAST(value_in_use AS BIGINT), 1036
							FROM    sys.configurations
							WHERE   name = 'min server memory (MB)'
				ELSE
					INSERT  INTO #ConfigurationDefaults
					VALUES  ( 'min server memory (MB)', 0, 1036 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'nested triggers', 1, 1037 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'network packet size (B)', 4096, 1038 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Ole Automation Procedures', 0, 1039 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'open objects', 0, 1040 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'optimize for ad hoc workloads', 0, 1041 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'PH timeout (s)', 60, 1042 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'precompute rank', 0, 1043 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'priority boost', 0, 1044 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'query governor cost limit', 0, 1045 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'query wait (s)', -1, 1046 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'recovery interval (min)', 0, 1047 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'remote access', 1, 1048 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'remote admin connections', 0, 1049 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'remote proc trans', 0, 1050 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'remote query timeout (s)', 600, 1051 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Replication XPs', 0, 1052 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'RPC parameter data validation', 0, 1053 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'scan for startup procs', 0, 1054 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'server trigger recursion', 1, 1055 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'set working set size', 0, 1056 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'show advanced options', 0, 1057 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'SMO and DMO XPs', 1, 1058 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'SQL Mail XPs', 0, 1059 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'transform noise words', 0, 1060 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'two digit year cutoff', 2049, 1061 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'user connections', 0, 1062 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'user options', 0, 1063 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'Web Assistant Procedures', 0, 1064 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'xp_cmdshell', 0, 1065 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'affinity64 mask', 0, 1066 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'affinity64 I/O mask', 0, 1067 );
				INSERT  INTO #ConfigurationDefaults
				VALUES  ( 'contained database authentication', 0, 1068 );
				/* SQL Server 2012 also changes a configuration default */
				IF @@VERSION LIKE '%Microsoft SQL Server 2005%'
					OR @@VERSION LIKE '%Microsoft SQL Server 2008%'
					BEGIN
						INSERT  INTO #ConfigurationDefaults
						VALUES  ( 'remote login timeout (s)', 20, 1069 );
					END
				ELSE
					BEGIN
						INSERT  INTO #ConfigurationDefaults
						VALUES  ( 'remote login timeout (s)', 10, 1070 );
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 22 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  cd.CheckID ,
										200 AS Priority ,
										'Non-Default Server Config' AS FindingsGroup ,
										cr.name AS Finding ,
										'http://BrentOzar.com/go/conf' AS URL ,
										( 'This sp_configure option has been changed.  Its default value is '
										  + COALESCE(CAST(cd.[DefaultValue] AS VARCHAR(100)),
													 '(unknown)')
										  + ' and it has been set to '
										  + CAST(cr.value_in_use AS VARCHAR(100))
										  + '.' ) AS Details
								FROM    sys.configurations cr
										INNER JOIN #ConfigurationDefaults cd ON cd.name = cr.name
										LEFT OUTER JOIN #ConfigurationDefaults cdUsed ON cdUsed.name = cr.name
																  AND cdUsed.DefaultValue = cr.value_in_use
								WHERE   cdUsed.name IS NULL;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 24 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										24 AS CheckID ,
										DB_NAME(database_id) AS DatabaseName ,
										20 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'System Database on C Drive' AS Finding ,
										'http://BrentOzar.com/go/cdrive' AS URL ,
										( 'The ' + DB_NAME(database_id)
										  + ' database has a file on the C drive.  Putting system databases on the C drive runs the risk of crashing the server when it runs out of space.' ) AS Details
								FROM    sys.master_files
								WHERE   UPPER(LEFT(physical_name, 1)) = 'C'
										AND DB_NAME(database_id) IN ( 'master',
																  'model', 'msdb' );
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 25 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT TOP 1
										25 AS CheckID ,
										'tempdb' ,
										100 AS Priority ,
										'Performance' AS FindingsGroup ,
										'TempDB on C Drive' AS Finding ,
										'http://BrentOzar.com/go/cdrive' AS URL ,
										CASE WHEN growth > 0
											 THEN ( 'The tempdb database has files on the C drive.  TempDB frequently grows unpredictably, putting your server at risk of running out of C drive space and crashing hard.  C is also often much slower than other drives, so performance may be suffering.' )
											 ELSE ( 'The tempdb database has files on the C drive.  TempDB is not set to Autogrow, hopefully it is big enough.  C is also often much slower than other drives, so performance may be suffering.' )
										END AS Details
								FROM    sys.master_files
								WHERE   UPPER(LEFT(physical_name, 1)) = 'C'
										AND DB_NAME(database_id) = 'tempdb';
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 26 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										26 AS CheckID ,
										DB_NAME(database_id) AS DatabaseName ,
										20 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'User Databases on C Drive' AS Finding ,
										'http://BrentOzar.com/go/cdrive' AS URL ,
										( 'The ' + DB_NAME(database_id)
										  + ' database has a file on the C drive.  Putting databases on the C drive runs the risk of crashing the server when it runs out of space.' ) AS Details
								FROM    sys.master_files
								WHERE   UPPER(LEFT(physical_name, 1)) = 'C'
										AND DB_NAME(database_id) NOT IN ( 'master',
																  'model', 'msdb',
																  'tempdb' )
										AND DB_NAME(database_id) NOT IN (
										SELECT DISTINCT
												DatabaseName
										FROM    #SkipChecks )
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 27 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  27 AS CheckID ,
										'master' AS DatabaseName ,
										200 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Tables in the Master Database' AS Finding ,
										'http://BrentOzar.com/go/mastuser' AS URL ,
										( 'The ' + name
										  + ' table in the master database was created by end users on '
										  + CAST(create_date AS VARCHAR(20))
										  + '. Tables in the master database may not be restored in the event of a disaster.' ) AS Details
								FROM    master.sys.tables
								WHERE   is_ms_shipped = 0;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 28 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  28 AS CheckID ,
										200 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Tables in the MSDB Database' AS Finding ,
										'http://BrentOzar.com/go/msdbuser' AS URL ,
										( 'The ' + name
										  + ' table in the msdb database was created by end users on '
										  + CAST(create_date AS VARCHAR(20))
										  + '. Tables in the msdb database may not be restored in the event of a disaster.' ) AS Details
								FROM    msdb.sys.tables
								WHERE   is_ms_shipped = 0;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 29 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  29 AS CheckID ,
										200 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Tables in the Model Database' AS Finding ,
										'http://BrentOzar.com/go/model' AS URL ,
										( 'The ' + name
										  + ' table in the model database was created by end users on '
										  + CAST(create_date AS VARCHAR(20))
										  + '. Tables in the model database are automatically copied into all new databases.' ) AS Details
								FROM    model.sys.tables
								WHERE   is_ms_shipped = 0;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 30 )
					BEGIN
						IF ( SELECT COUNT(*)
							 FROM   msdb.dbo.sysalerts
							 WHERE  severity BETWEEN 19 AND 25
						   ) < 7
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  30 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'Not All Alerts Configured' AS Finding ,
											'http://BrentOzar.com/go/alert' AS URL ,
											( 'Not all SQL Server Agent alerts have been configured.  This is a free, easy way to get notified of corruption, job failures, or major outages even before monitoring systems pick it up.' ) AS Details;
					END



				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 59 )
					BEGIN
						IF EXISTS ( SELECT  *
									FROM    msdb.dbo.sysalerts
									WHERE   enabled = 1
											AND COALESCE(has_notification, 0) = 0
											AND (job_id IS NULL OR job_id = 0x))
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  59 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'Alerts Configured without Follow Up' AS Finding ,
											'http://BrentOzar.com/go/alert' AS URL ,
											( 'SQL Server Agent alerts have been configured but they either do not notify anyone or else they do not take any action.  This is a free, easy way to get notified of corruption, job failures, or major outages even before monitoring systems pick it up.' ) AS Details;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 96 )
					BEGIN
						IF NOT EXISTS ( SELECT  *
										FROM    msdb.dbo.sysalerts
										WHERE   message_id IN ( 823, 824, 825 ) )
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  96 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'No Alerts for Corruption' AS Finding ,
											'http://BrentOzar.com/go/alert' AS URL ,
											( 'SQL Server Agent alerts do not exist for errors 823, 824, and 825.  These three errors can give you notification about early hardware failure. Enabling them can prevent you a lot of heartbreak.' ) AS Details;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 61 )
					BEGIN
						IF NOT EXISTS ( SELECT  *
										FROM    msdb.dbo.sysalerts
										WHERE   severity BETWEEN 19 AND 25 )
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  61 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'No Alerts for Sev 19-25' AS Finding ,
											'http://BrentOzar.com/go/alert' AS URL ,
											( 'SQL Server Agent alerts do not exist for severity levels 19 through 25.  These are some very severe SQL Server errors. Knowing that these are happening may let you recover from errors faster.' ) AS Details;
					END

		--check for disabled alerts
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 98 )
					BEGIN
						IF EXISTS ( SELECT  name
									FROM    msdb.dbo.sysalerts
									WHERE   enabled = 0 )
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  98 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'Alerts Disabled' AS Finding ,
											'http://www.BrentOzar.com/go/alerts/' AS URL ,
											( 'The following Alert is disabled, please review and enable if desired: '
											  + name ) AS Details
									FROM    msdb.dbo.sysalerts
									WHERE   enabled = 0
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 31 )
					BEGIN
						IF NOT EXISTS ( SELECT  *
										FROM    msdb.dbo.sysoperators
										WHERE   enabled = 1 )
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  31 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingsGroup ,
											'No Operators Configured/Enabled' AS Finding ,
											'http://BrentOzar.com/go/op' AS URL ,
											( 'No SQL Server Agent operators (emails) have been configured.  This is a free, easy way to get notified of corruption, job failures, or major outages even before monitoring systems pick it up.' ) AS Details;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 33 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults
					(CheckID,
					DatabaseName,
					Priority,
					FindingsGroup,
					Finding,
					URL,
					Details)
		  SELECT DISTINCT 33,
		  db_name(),
		  200,
		  ''Licensing'',
		  ''Enterprise Edition Features In Use'',
		  ''http://BrentOzar.com/go/ee'',
		  (''The ['' + DB_NAME() + ''] database is using '' + feature_name + ''.  If this database is restored onto a Standard Edition server, the restore will fail.'')
		  FROM [?].sys.dm_db_persisted_sku_features';
							END;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 34 )
					BEGIN
						IF EXISTS ( SELECT  *
									FROM    sys.all_objects
									WHERE   name = 'dm_db_mirroring_auto_page_repair' )
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT DISTINCT
		  34 AS CheckID ,
		  db.name ,
		  1 AS Priority ,
		  ''Corruption'' AS FindingsGroup ,
		  ''Database Corruption Detected'' AS Finding ,
		  ''http://BrentOzar.com/go/repair'' AS URL ,
		  ( ''Database mirroring has automatically repaired at least one corrupt page in the last 30 days. For more information, query the DMV sys.dm_db_mirroring_auto_page_repair.'' ) AS Details
		  FROM (SELECT rp2.database_id, rp2.modification_time 
			FROM sys.dm_db_mirroring_auto_page_repair rp2 
			WHERE rp2.[database_id] not in (
			SELECT db2.[database_id] 
			FROM sys.databases as db2 
			WHERE db2.[state] = 1
			) ) as rp 
		  INNER JOIN master.sys.databases db ON rp.database_id = db.database_id
		  WHERE   rp.modification_time >= DATEADD(dd, -30, GETDATE()) ;'
								EXECUTE(@StringToExecute)
							END;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 89 )
					BEGIN
						IF EXISTS ( SELECT  *
									FROM    sys.all_objects
									WHERE   name = 'dm_hadr_auto_page_repair' )
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT DISTINCT
		  89 AS CheckID ,
		  db.name ,
		  1 AS Priority ,
		  ''Corruption'' AS FindingsGroup ,
		  ''Database Corruption Detected'' AS Finding ,
		  ''http://BrentOzar.com/go/repair'' AS URL ,
		  ( ''AlwaysOn has automatically repaired at least one corrupt page in the last 30 days. For more information, query the DMV sys.dm_hadr_auto_page_repair.'' ) AS Details
		  FROM    sys.dm_hadr_auto_page_repair rp
		  INNER JOIN master.sys.databases db ON rp.database_id = db.database_id
		  WHERE   rp.modification_time >= DATEADD(dd, -30, GETDATE()) ;'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 90 )
					BEGIN
						IF EXISTS ( SELECT  *
									FROM    msdb.sys.all_objects
									WHERE   name = 'suspect_pages' )
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT DISTINCT
		  90 AS CheckID ,
		  db.name ,
		  1 AS Priority ,
		  ''Corruption'' AS FindingsGroup ,
		  ''Database Corruption Detected'' AS Finding ,
		  ''http://BrentOzar.com/go/repair'' AS URL ,
		  ( ''SQL Server has detected at least one corrupt page in the last 30 days. For more information, query the system table msdb.dbo.suspect_pages.'' ) AS Details
		  FROM    msdb.dbo.suspect_pages sp
		  INNER JOIN master.sys.databases db ON sp.database_id = db.database_id
		  WHERE   sp.last_update_date >= DATEADD(dd, -30, GETDATE()) ;'
								EXECUTE(@StringToExecute)
							END;
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 36 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										36 AS CheckID ,
										100 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Slow Storage Reads on Drive '
										+ UPPER(LEFT(mf.physical_name, 1)) AS Finding ,
										'http://BrentOzar.com/go/slow' AS URL ,
										'Reads are averaging longer than 100ms for at least one database on this drive.  For specific database file speeds, run the query from the information link.' AS Details
								FROM    sys.dm_io_virtual_file_stats(NULL, NULL)
										AS fs
										INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
																  AND fs.[file_id] = mf.[file_id]
								WHERE   ( io_stall_read_ms / ( 1.0 + num_of_reads ) ) > 100;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 37 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										37 AS CheckID ,
										100 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Slow Storage Writes on Drive '
										+ UPPER(LEFT(mf.physical_name, 1)) AS Finding ,
										'http://BrentOzar.com/go/slow' AS URL ,
										'Writes are averaging longer than 20ms for at least one database on this drive.  For specific database file speeds, run the query from the information link.' AS Details
								FROM    sys.dm_io_virtual_file_stats(NULL, NULL)
										AS fs
										INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
																  AND fs.[file_id] = mf.[file_id]
								WHERE   ( io_stall_write_ms / ( 1.0
																+ num_of_writes ) ) > 20;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 40 )
					BEGIN
						IF ( SELECT COUNT(*)
							 FROM   tempdb.sys.database_files
							 WHERE  type_desc = 'ROWS'
						   ) = 1
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  DatabaseName ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
								VALUES  ( 40 ,
										  'tempdb' ,
										  100 ,
										  'Performance' ,
										  'TempDB Only Has 1 Data File' ,
										  'http://BrentOzar.com/go/tempdb' ,
										  'TempDB is only configured with one data file.  More data files are usually required to alleviate SGAM contention.'
										);
							END;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 41 )
					BEGIN
						EXEC dbo.sp_MSforeachdb 'use [?];
		  INSERT INTO #BlitzResults
		  (CheckID,
		  DatabaseName,
		  Priority,
		  FindingsGroup,
		  Finding,
		  URL,
		  Details)
		  SELECT 41,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Multiple Log Files on One Drive'',
		  ''http://BrentOzar.com/go/manylogs'',
		  (''The ['' + DB_NAME() + ''] database has multiple log files on the '' + LEFT(physical_name, 1) + '' drive. This is not a performance booster because log file access is sequential, not parallel.'')
		  FROM [?].sys.database_files WHERE type_desc = ''LOG''
			AND ''?'' <> ''[tempdb]''
		  GROUP BY LEFT(physical_name, 1)
		  HAVING COUNT(*) > 1';
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 42 )
					BEGIN
						EXEC dbo.sp_MSforeachdb 'use [?];
			INSERT INTO #BlitzResults
			(CheckID,
			DatabaseName,
			Priority,
			FindingsGroup,
			Finding,
			URL,
			Details)
			SELECT DISTINCT 42,
			''?'',
			100,
			''Performance'',
			''Uneven File Growth Settings in One Filegroup'',
			''http://BrentOzar.com/go/grow'',
			(''The ['' + DB_NAME() + ''] database has multiple data files in one filegroup, but they are not all set up to grow in identical amounts.  This can lead to uneven file activity inside the filegroup.'')
			FROM [?].sys.database_files
			WHERE type_desc = ''ROWS''
			GROUP BY data_space_id
			HAVING COUNT(DISTINCT growth) > 1 OR COUNT(DISTINCT is_percent_growth) > 1';
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 44 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  44 AS CheckID ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Queries Forcing Order Hints' AS Finding ,
										'http://BrentOzar.com/go/hints' AS URL ,
										CAST(occurrence AS VARCHAR(10))
										+ ' instances of order hinting have been recorded since restart.  This means queries are bossing the SQL Server optimizer around, and if they don''t know what they''re doing, this can cause more harm than good.  This can also explain why DBA tuning efforts aren''t working.' AS Details
								FROM    sys.dm_exec_query_optimizer_info
								WHERE   counter = 'order hint'
										AND occurrence > 1000
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 45 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  45 AS CheckID ,
										110 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Queries Forcing Join Hints' AS Finding ,
										'http://BrentOzar.com/go/hints' AS URL ,
										CAST(occurrence AS VARCHAR(10))
										+ ' instances of join hinting have been recorded since restart.  This means queries are bossing the SQL Server optimizer around, and if they don''t know what they''re doing, this can cause more harm than good.  This can also explain why DBA tuning efforts aren''t working.' AS Details
								FROM    sys.dm_exec_query_optimizer_info
								WHERE   counter = 'join hint'
										AND occurrence > 1000
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 49 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT DISTINCT
										49 AS CheckID ,
										200 AS Priority ,
										'Informational' AS FindingsGroup ,
										'Linked Server Configured' AS Finding ,
										'http://BrentOzar.com/go/link' AS URL ,
										+CASE WHEN l.remote_name = 'sa'
											  THEN s.data_source
												   + ' is configured as a linked server. Check its security configuration as it is connecting with sa, because any user who queries it will get admin-level permissions.'
											  ELSE s.data_source
												   + ' is configured as a linked server. Check its security configuration to make sure it isn''t connecting with SA or some other bone-headed administrative login, because any user who queries it might get admin-level permissions.'
										 END AS Details
								FROM    sys.servers s
										INNER JOIN sys.linked_logins l ON s.server_id = l.server_id
								WHERE   s.is_linked = 1
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 50 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
		  SELECT  50 AS CheckID ,
		  100 AS Priority ,
		  ''Performance'' AS FindingsGroup ,
		  ''Max Memory Set Too High'' AS Finding ,
		  ''http://BrentOzar.com/go/max'' AS URL ,
		  ''SQL Server max memory is set to ''
			+ CAST(c.value_in_use AS VARCHAR(20))
			+ '' megabytes, but the server only has ''
			+ CAST(( CAST(m.total_physical_memory_kb AS BIGINT) / 1024 ) AS VARCHAR(20))
			+ '' megabytes.  SQL Server may drain the system dry of memory, and under certain conditions, this can cause Windows to swap to disk.'' AS Details
		  FROM    sys.dm_os_sys_memory m
		  INNER JOIN sys.configurations c ON c.name = ''max server memory (MB)''
		  WHERE   CAST(m.total_physical_memory_kb AS BIGINT) < ( CAST(c.value_in_use AS BIGINT) * 1024 )'
								EXECUTE(@StringToExecute)
							END;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 51 )
					BEGIN
						IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
							AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
		  SELECT  51 AS CheckID ,
		  1 AS Priority ,
		  ''Performance'' AS FindingsGroup ,
		  ''Memory Dangerously Low'' AS Finding ,
		  ''http://BrentOzar.com/go/max'' AS URL ,
		  ''The server has '' + CAST(( CAST(m.total_physical_memory_kb AS BIGINT) / 1024 ) AS VARCHAR(20)) + '' megabytes of physical memory, but only '' + CAST(( CAST(m.available_physical_memory_kb AS BIGINT) / 1024 ) AS VARCHAR(20))
			+ '' megabytes are available.  As the server runs out of memory, there is danger of swapping to disk, which will kill performance.'' AS Details
		  FROM    sys.dm_os_sys_memory m
		  WHERE   CAST(m.available_physical_memory_kb AS BIGINT) < 262144'
								EXECUTE(@StringToExecute)
							END;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 53 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT TOP 1
										53 AS CheckID ,
										200 AS Priority ,
										'High Availability' AS FindingsGroup ,
										'Cluster Node' AS Finding ,
										'http://BrentOzar.com/go/node' AS URL ,
										'This is a node in a cluster.' AS Details
								FROM    sys.dm_os_cluster_nodes
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 55 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  55 AS CheckID ,
										[name] AS DatabaseName ,
										200 AS Priority ,
										'Security' AS FindingsGroup ,
										'Database Owner <> SA' AS Finding ,
										'http://BrentOzar.com/go/owndb' AS URL ,
										( 'Database name: ' + [name] + '   '
										  + 'Owner name: ' + SUSER_SNAME(owner_sid) ) AS Details
								FROM    sys.databases
								WHERE   SUSER_SNAME(owner_sid) <> SUSER_SNAME(0x01)
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks );
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 57 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  57 AS CheckID ,
										10 AS Priority ,
										'Security' AS FindingsGroup ,
										'SQL Agent Job Runs at Startup' AS Finding ,
										'http://BrentOzar.com/go/startup' AS URL ,
										( 'Job [' + j.name
										  + '] runs automatically when SQL Server Agent starts up.  Make sure you know exactly what this job is doing, because it could pose a security risk.' ) AS Details
								FROM    msdb.dbo.sysschedules sched
										JOIN msdb.dbo.sysjobschedules jsched ON sched.schedule_id = jsched.schedule_id
										JOIN msdb.dbo.sysjobs j ON jsched.job_id = j.job_id
								WHERE   sched.freq_type = 64;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 82 )
					BEGIN
						EXEC sp_MSforeachdb 'use [?];
		INSERT INTO #BlitzResults
		(CheckID,
		DatabaseName,
		Priority,
		FindingsGroup,
		Finding,
		URL, Details)
		SELECT  DISTINCT 82 AS CheckID,
		''?'' as DatabaseName,
		100 AS Priority,
		''Performance'' AS FindingsGroup,
		''File growth set to percent'',
		''http://brentozar.com/go/percentgrowth'' AS URL,
		''The ['' + DB_NAME() + ''] database is using percent filegrowth settings. This can lead to out of control filegrowth.''
		FROM    [?].sys.database_files
		WHERE   is_percent_growth = 1 ';
					END

                /* addition by Henrik Staun Poulsen, Stovi Software */
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 158 )
					BEGIN
						EXEC sp_MSforeachdb 'use [?];
		INSERT INTO #BlitzResults
		(CheckID,
		DatabaseName,
		Priority,
		FindingsGroup,
		Finding,
		URL, Details)
		SELECT  DISTINCT 158 AS CheckID,
		''?'' as DatabaseName,
		100 AS Priority,
		''Performance'' AS FindingsGroup,
		''File growth set to 1MB'',
		''http://brentozar.com/go/percentgrowth'' AS URL,
		''The ['' + DB_NAME() + ''] database is using 1MB filegrowth settings, but it has grown larger than 10GB. Time to up the growth amount.''
		FROM    [?].sys.database_files
        WHERE is_percent_growth = 0 and growth=128 and size > 1280000 ';
					END


				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 97 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  97 AS CheckID ,
										100 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Unusual SQL Server Edition' AS Finding ,
										'http://BrentOzar.com/go/workgroup' AS URL ,
										( 'This server is using '
										  + CAST(SERVERPROPERTY('edition') AS VARCHAR(100))
										  + ', which is capped at low amounts of CPU and memory.' ) AS Details
								WHERE   CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Standard%'
										AND CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Enterprise%'
										AND CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Data Center%'
										AND CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Developer%'
										AND CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Business Intelligence%'
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 97 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  154 AS CheckID ,
										10 AS Priority ,
										'Performance' AS FindingsGroup ,
										'32-bit SQL Server Installed' AS Finding ,
										'http://BrentOzar.com/go/32bit' AS URL ,
										( 'This server uses the 32-bit x86 binaries for SQL Server instead of the 64-bit x64 binaries. The amount of memory available for query workspace and execution plans is heavily limited.' ) AS Details
								WHERE   CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%64%'
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 62 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  62 AS CheckID ,
										[name] AS DatabaseName ,
										200 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Old Compatibility Level' AS Finding ,
										'http://BrentOzar.com/go/compatlevel' AS URL ,
										( 'Database ' + [name]
										  + ' is compatibility level '
										  + CAST(compatibility_level AS VARCHAR(20))
										  + ', which may cause unwanted results when trying to run queries that have newer T-SQL features.' ) AS Details
								FROM    sys.databases
								WHERE   name NOT IN ( SELECT DISTINCT
																DatabaseName
													  FROM      #SkipChecks )
										AND compatibility_level <> ( SELECT
																  compatibility_level
																  FROM
																  sys.databases
																  WHERE
																  [name] = 'model'
																  )
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 94 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  94 AS CheckID ,
										50 AS [Priority] ,
										'Reliability' AS FindingsGroup ,
										'Agent Jobs Without Failure Emails' AS Finding ,
										'http://BrentOzar.com/go/alerts' AS URL ,
										'The job ' + [name]
										+ ' has not been set up to notify an operator if it fails.' AS Details
								FROM    msdb.[dbo].[sysjobs] j
										INNER JOIN ( SELECT DISTINCT
															[job_id]
													 FROM   [msdb].[dbo].[sysjobschedules]
													 WHERE  next_run_date > 0
												   ) s ON j.job_id = s.job_id
								WHERE   j.enabled = 1
										AND j.notify_email_operator_id = 0
										AND j.notify_netsend_operator_id = 0
										AND j.notify_page_operator_id = 0
										AND j.category_id <> 100 /* Exclude SSRS category */
					END


				IF EXISTS ( SELECT  1
							FROM    sys.configurations
							WHERE   name = 'remote admin connections'
									AND value_in_use = 0 )
					AND NOT EXISTS ( SELECT 1
									 FROM   #SkipChecks
									 WHERE  DatabaseName IS NULL AND CheckID = 100 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  100 AS CheckID ,
										50 AS Priority ,
										'Reliability' AS FindingGroup ,
										'Remote DAC Disabled' AS Finding ,
										'http://BrentOzar.com/go/dac' AS URL ,
										'Remote access to the Dedicated Admin Connection (DAC) is not enabled. The DAC can make remote troubleshooting much easier when SQL Server is unresponsive.'
					END


				IF EXISTS ( SELECT  *
							FROM    sys.dm_os_schedulers
							WHERE   is_online = 0 )
					AND NOT EXISTS ( SELECT 1
									 FROM   #SkipChecks
									 WHERE  DatabaseName IS NULL AND CheckID = 101 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  101 AS CheckID ,
										50 AS Priority ,
										'Performance' AS FindingGroup ,
										'CPU Schedulers Offline' AS Finding ,
										'http://BrentOzar.com/go/schedulers' AS URL ,
										'Some CPU cores are not accessible to SQL Server due to affinity masking or licensing problems.'
					END


					IF NOT EXISTS ( SELECT  1
									FROM    #SkipChecks
									WHERE   DatabaseName IS NULL AND CheckID = 110 )
								AND EXISTS (SELECT * FROM master.sys.all_objects WHERE name = 'dm_os_memory_nodes')
						BEGIN
							SET @StringToExecute = 'IF EXISTS (SELECT  *
												FROM sys.dm_os_nodes n
												INNER JOIN sys.dm_os_memory_nodes m ON n.memory_node_id = m.memory_node_id
												WHERE n.node_state_desc = ''OFFLINE'')
												INSERT  INTO #BlitzResults
														( CheckID ,
														  Priority ,
														  FindingsGroup ,
														  Finding ,
														  URL ,
														  Details
														)
														SELECT  110 AS CheckID ,
																50 AS Priority ,
																''Performance'' AS FindingGroup ,
																''Memory Nodes Offline'' AS Finding ,
																''http://BrentOzar.com/go/schedulers'' AS URL ,
																''Due to affinity masking or licensing problems, some of the memory may not be available.''';
									EXECUTE(@StringToExecute);
						END


				IF EXISTS ( SELECT  *
							FROM    sys.databases
							WHERE   state > 1 )
					AND NOT EXISTS ( SELECT 1
									 FROM   #SkipChecks
									 WHERE  DatabaseName IS NULL AND CheckID = 102 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  102 AS CheckID ,
										[name] ,
										20 AS Priority ,
										'Reliability' AS FindingGroup ,
										'Unusual Database State: ' + [state_desc] AS Finding ,
										'http://BrentOzar.com/go/repair' AS URL ,
										'This database may not be online.'
								FROM    sys.databases
								WHERE   state > 1
					END

				IF EXISTS ( SELECT  *
							FROM    master.sys.extended_procedures )
					AND NOT EXISTS ( SELECT 1
									 FROM   #SkipChecks
									 WHERE  DatabaseName IS NULL AND CheckID = 105 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  105 AS CheckID ,
										'master' ,
										50 AS Priority ,
										'Reliability' AS FindingGroup ,
										'Extended Stored Procedures in Master' AS Finding ,
										'http://BrentOzar.com/go/clr' AS URL ,
										'The [' + name
										+ '] extended stored procedure is in the master database. CLR may be in use, and the master database now needs to be part of your backup/recovery planning.'
								FROM    master.sys.extended_procedures
					END



					IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 107 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  107 AS CheckID ,
											100 AS Priority ,
											'Performance' AS FindingGroup ,
											'Poison Wait Detected: THREADPOOL'  AS Finding ,
											'http://BrentOzar.com/go/poison' AS URL ,
											CAST(SUM([wait_time_ms]) AS VARCHAR(100)) + ' milliseconds of this wait have been recorded. This wait often indicates killer performance problems.'
									FROM sys.[dm_os_wait_stats]
									WHERE wait_type = 'THREADPOOL'
									GROUP BY wait_type
								    HAVING SUM([wait_time_ms]) > (SELECT 5000 * datediff(HH,create_date,CURRENT_TIMESTAMP) AS hours_since_startup FROM sys.databases WHERE name='tempdb')
						END

					IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 108 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  108 AS CheckID ,
											100 AS Priority ,
											'Performance' AS FindingGroup ,
											'Poison Wait Detected: RESOURCE_SEMAPHORE'  AS Finding ,
											'http://BrentOzar.com/go/poison' AS URL ,
											CAST(SUM([wait_time_ms]) AS VARCHAR(100)) + ' milliseconds of this wait have been recorded. This wait often indicates killer performance problems.'
									FROM sys.[dm_os_wait_stats]
									WHERE wait_type = 'RESOURCE_SEMAPHORE'
									GROUP BY wait_type
								    HAVING SUM([wait_time_ms]) > (SELECT 5000 * datediff(HH,create_date,CURRENT_TIMESTAMP) AS hours_since_startup FROM sys.databases WHERE name='tempdb')
						END


					IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 109 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  109 AS CheckID ,
											100 AS Priority ,
											'Performance' AS FindingGroup ,
											'Poison Wait Detected: RESOURCE_SEMAPHORE_QUERY_COMPILE'  AS Finding ,
											'http://BrentOzar.com/go/poison' AS URL ,
											CAST(SUM([wait_time_ms]) AS VARCHAR(100)) + ' milliseconds of this wait have been recorded. This wait often indicates killer performance problems.'
									FROM sys.[dm_os_wait_stats]
									WHERE wait_type = 'RESOURCE_SEMAPHORE_QUERY_COMPILE'
									GROUP BY wait_type
								    HAVING SUM([wait_time_ms]) > (SELECT 5000 * datediff(HH,create_date,CURRENT_TIMESTAMP) AS hours_since_startup FROM sys.databases WHERE name='tempdb')
						END


					IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 121 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  121 AS CheckID ,
											100 AS Priority ,
											'Performance' AS FindingGroup ,
											'Poison Wait Detected: Serializable Locking'  AS Finding ,
											'http://BrentOzar.com/go/serializable' AS URL ,
											CAST(SUM([wait_time_ms]) / 1000 AS VARCHAR(100)) + ' seconds of this wait have been recorded. Queries are forcing serial operation (one query at a time) with lock hints.'
									FROM sys.[dm_os_wait_stats]
									WHERE wait_type LIKE '%LCK%R%'
									GROUP BY wait_type
								    HAVING SUM([wait_time_ms]) > (SELECT 5000 * datediff(HH,create_date,CURRENT_TIMESTAMP) AS hours_since_startup FROM sys.databases WHERE name='tempdb')
						END



						IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 111 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  DatabaseName ,
									  URL ,
									  Details
									)
									SELECT  111 AS CheckID ,
											50 AS Priority ,
											'Reliability' AS FindingGroup ,
											'Possibly Broken Log Shipping'  AS Finding ,
											d.[name] ,
											'http://BrentOzar.com/go/shipping' AS URL ,
											d.[name] + ' is in a restoring state, but has not had a backup applied in the last two days. This is a possible indication of a broken transaction log shipping setup.'
											FROM [master].sys.databases d
											INNER JOIN [master].sys.database_mirroring dm ON d.database_id = dm.database_id
												AND dm.mirroring_role IS NULL
											WHERE ( d.[state] = 1
											OR (d.[state] = 0 AND d.[is_in_standby] = 1) )
											AND NOT EXISTS(SELECT * FROM msdb.dbo.restorehistory rh
											INNER JOIN msdb.dbo.backupset bs ON rh.backup_set_id = bs.backup_set_id
											WHERE d.[name] COLLATE SQL_Latin1_General_CP1_CI_AS = rh.destination_database_name COLLATE SQL_Latin1_General_CP1_CI_AS
											AND rh.restore_date >= DATEADD(dd, -2, GETDATE()))

						END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 112 )
									AND EXISTS (SELECT * FROM master.sys.all_objects WHERE name = 'change_tracking_databases')
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults
									(CheckID,
									Priority,
									FindingsGroup,
									Finding,
									URL,
									Details)
							  SELECT 112 AS CheckID,
							  100 AS Priority,
							  ''Performance'' AS FindingsGroup,
							  ''Change Tracking Enabled'' AS Finding,
							  ''http://BrentOzar.com/go/tracking'' AS URL,
							  ( d.[name] + '' has change tracking enabled. This is not a default setting, and it has some performance overhead. It keeps track of changes to rows in tables that have change tracking turned on.'' ) AS Details FROM sys.change_tracking_databases AS ctd INNER JOIN sys.databases AS d ON ctd.database_id = d.database_id';
										EXECUTE(@StringToExecute);
							END

						IF NOT EXISTS ( SELECT 1
										 FROM   #SkipChecks
										 WHERE  DatabaseName IS NULL AND CheckID = 116 )
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  116 AS CheckID ,
											200 AS Priority ,
											'Informational' AS FindingGroup ,
											'Backup Compression Default Off'  AS Finding ,
											'http://BrentOzar.com/go/backup' AS URL ,
											'Backup compression is included with SQL Server 2008R2 & newer, even in Standard Edition. We recommend turning backup compression on by default so that ad-hoc backups will get compressed.'
											FROM sys.configurations
											WHERE configuration_id = 1579 AND CAST(value_in_use AS INT) = 0

						END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 117 )
									AND EXISTS (SELECT * FROM master.sys.all_objects WHERE name = 'dm_exec_query_resource_semaphores')
							BEGIN
								SET @StringToExecute = 'IF 0 < (SELECT SUM([forced_grant_count]) FROM sys.dm_exec_query_resource_semaphores WHERE [forced_grant_count] IS NOT NULL)
								INSERT INTO #BlitzResults
									(CheckID,
									Priority,
									FindingsGroup,
									Finding,
									URL,
									Details)
							  SELECT 117 AS CheckID,
							  100 AS Priority,
							  ''Performance'' AS FindingsGroup,
							  ''Memory Pressure Affecting Queries'' AS Finding,
							  ''http://BrentOzar.com/go/grants'' AS URL,
							  CAST(SUM(forced_grant_count) AS NVARCHAR(100)) + '' forced grants reported in the DMV sys.dm_exec_query_resource_semaphores, indicating memory pressure has affected query runtimes.''
							  FROM sys.dm_exec_query_resource_semaphores WHERE [forced_grant_count] IS NOT NULL;'
										EXECUTE(@StringToExecute);
							END



						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 124 )
							BEGIN
								INSERT INTO #BlitzResults
									(CheckID,
									Priority,
									FindingsGroup,
									Finding,
									URL,
									Details)
								SELECT 124, 100, 'Performance', 'Deadlocks Happening Daily', 'http://BrentOzar.com/go/deadlocks',
									CAST(p.cntr_value AS NVARCHAR(100)) + ' deadlocks have been recorded since startup.' AS Details
								FROM sys.dm_os_performance_counters p
									INNER JOIN sys.databases d ON d.name = 'tempdb'
								WHERE RTRIM(p.counter_name) = 'Number of Deadlocks/sec'
									AND RTRIM(p.instance_name) = '_Total'
									AND p.cntr_value > 0
									AND (1.0 * p.cntr_value / NULLIF(datediff(DD,create_date,CURRENT_TIMESTAMP),0)) > 10;
							END


						IF DATEADD(mi, -15, GETDATE()) < (SELECT TOP 1 creation_time FROM sys.dm_exec_query_stats ORDER BY creation_time)
						BEGIN
							INSERT INTO #BlitzResults
								(CheckID,
								Priority,
								FindingsGroup,
								Finding,
								URL,
								Details)
							SELECT TOP 1 125, 10, 'Performance', 'Plan Cache Erased Recently', 'http://BrentOzar.com/askbrent/plan-cache-erased-recently/',
								'The oldest query in the plan cache was created at ' + CAST(creation_time AS NVARCHAR(50)) + '. Someone ran DBCC FREEPROCCACHE, restarted SQL Server, or it is under horrific memory pressure.'
							FROM sys.dm_exec_query_stats WITH (NOLOCK)
							ORDER BY creation_time	
						END;

						IF EXISTS (SELECT * FROM sys.configurations WHERE name = 'priority boost' AND (value = 1 OR value_in_use = 1))
						BEGIN
							INSERT INTO #BlitzResults
								(CheckID,
								Priority,
								FindingsGroup,
								Finding,
								URL,
								Details)
							VALUES(126, 5, 'Reliability', 'Priority Boost Enabled', 'http://BrentOzar.com/go/priorityboost/',
								'Priority Boost sounds awesome, but it can actually cause your SQL Server to crash.')
						END;

						IF EXISTS (select * from msdb.dbo.backupset WHERE database_name = 'ReportServerTempDB')
						BEGIN
							INSERT INTO #BlitzResults
								(CheckID,
								Priority,
								DatabaseName,
								FindingsGroup,
								Finding,
								URL,
								Details)
							VALUES(127, 200, 'ReportServerTempDB', 'Backup', 'Backing Up Unneeded Database', 'http://BrentOzar.com/go/reportservertempdb/',
								'This database is being backed up, but you probably do not need to. See the URL for more details on how to reconstruct it.')
						END;

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 128 )
							BEGIN

							IF (@ProductVersionMajor = 12 AND @ProductVersionMinor < 2000) OR
							   (@ProductVersionMajor = 11 AND @ProductVersionMinor <= 2100) OR
							   (@ProductVersionMajor = 10.5 AND @ProductVersionMinor <= 2500) OR
							   (@ProductVersionMajor = 10 AND @ProductVersionMinor <= 4000) OR
							   (@ProductVersionMajor = 9 AND @ProductVersionMinor <= 5000)
								BEGIN
								INSERT INTO #BlitzResults(CheckID, Priority, FindingsGroup, Finding, URL, Details)
									VALUES(128, 20, 'Reliability', 'Unsupported Build of SQL Server', 'http://BrentOzar.com/go/unsupported',
										'Version ' + CAST(@ProductVersionMajor AS VARCHAR(100)) + '.' + CAST(@ProductVersionMinor AS VARCHAR(100)) + ' is no longer supported by Microsoft. You need to apply a service pack.');
								END;

							END;
							
						/* Reliability - Dangerous Build of SQL Server (Corruption) */
						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 129 )
							BEGIN
							IF (@ProductVersionMajor = 11 AND @ProductVersionMinor >= 3000 AND @ProductVersionMinor <= 3436) OR
							   (@ProductVersionMajor = 11 AND @ProductVersionMinor = 5058) OR
							   (@ProductVersionMajor = 12 AND @ProductVersionMinor >= 2000 AND @ProductVersionMinor <= 2342)
								BEGIN
								INSERT INTO #BlitzResults(CheckID, Priority, FindingsGroup, Finding, URL, Details)
									VALUES(129, 20, 'Reliability', 'Dangerous Build of SQL Server (Corruption)', 'http://sqlperformance.com/2014/06/sql-indexes/hotfix-sql-2012-rebuilds',
										'There are dangerous known bugs with version ' + CAST(@ProductVersionMajor AS VARCHAR(100)) + '.' + CAST(@ProductVersionMinor AS VARCHAR(100)) + '. Check the URL for details and apply the right service pack or hotfix.');
								END;

							END;

						/* Reliability - Dangerous Build of SQL Server (Security) */
						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 157 )
							BEGIN
							IF (@ProductVersionMajor = 10 AND @ProductVersionMinor >= 5500 AND @ProductVersionMinor <= 5512) OR
							   (@ProductVersionMajor = 10 AND @ProductVersionMinor >= 5750 AND @ProductVersionMinor <= 5867) OR
							   (@ProductVersionMajor = 10.5 AND @ProductVersionMinor >= 4000 AND @ProductVersionMinor <= 4017) OR
							   (@ProductVersionMajor = 10.5 AND @ProductVersionMinor >= 4251 AND @ProductVersionMinor <= 4319) OR
							   (@ProductVersionMajor = 11 AND @ProductVersionMinor >= 3000 AND @ProductVersionMinor <= 3129) OR
							   (@ProductVersionMajor = 11 AND @ProductVersionMinor >= 3300 AND @ProductVersionMinor <= 3447) OR
							   (@ProductVersionMajor = 12 AND @ProductVersionMinor >= 2000 AND @ProductVersionMinor <= 2253) OR
							   (@ProductVersionMajor = 12 AND @ProductVersionMinor >= 2300 AND @ProductVersionMinor <= 2370)
								BEGIN
								INSERT INTO #BlitzResults(CheckID, Priority, FindingsGroup, Finding, URL, Details)
									VALUES(157, 20, 'Reliability', 'Dangerous Build of SQL Server (Security)', 'https://technet.microsoft.com/en-us/library/security/MS14-044',
										'There are dangerous known bugs with version ' + CAST(@ProductVersionMajor AS VARCHAR(100)) + '.' + CAST(@ProductVersionMinor AS VARCHAR(100)) + '. Check the URL for details and apply the right service pack or hotfix.');
								END;

							END;


                        /* Performance - High Memory Use for In-Memory OLTP (Hekaton) */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 145 )
	                        AND EXISTS ( SELECT *
					                        FROM   sys.all_objects o
					                        WHERE  o.name = 'dm_db_xtp_table_memory_stats' )
	                        BEGIN
		                        SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			                        SELECT 145 AS CheckID,
			                        10 AS Priority,
			                        ''Performance'' AS FindingsGroup,
			                        ''High Memory Use for In-Memory OLTP (Hekaton)'' AS Finding,
			                        ''http://BrentOzar.com/go/hekaton'' AS URL,
			                        CAST(CAST((SUM(mem.pages_kb / 1024.0) / CAST(value_in_use AS INT) * 100) AS INT) AS NVARCHAR(100)) + ''% of your '' + CAST(CAST((CAST(value_in_use AS DECIMAL(38,1)) / 1024) AS MONEY) AS NVARCHAR(100)) + ''GB of your max server memory is being used for in-memory OLTP tables (Hekaton). Microsoft recommends having 2X your Hekaton table space available in memory just for Hekaton, with a max of 250GB of in-memory data regardless of your server memory capacity.'' AS Details
			                        FROM sys.configurations c INNER JOIN sys.dm_os_memory_clerks mem ON mem.type = ''MEMORYCLERK_XTP''
                                    WHERE c.name = ''max server memory (MB)''
                                    GROUP BY c.value_in_use
                                    HAVING CAST(value_in_use AS DECIMAL(38,2)) * .25 < SUM(mem.pages_kb / 1024.0)
                                      OR SUM(mem.pages_kb / 1024.0) > 250000';
		                        EXECUTE(@StringToExecute);
	                        END


                        /* Performance - In-Memory OLTP (Hekaton) In Use */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 146 )
	                        AND EXISTS ( SELECT *
					                        FROM   sys.all_objects o
					                        WHERE  o.name = 'dm_db_xtp_table_memory_stats' )
	                        BEGIN
		                        SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			                        SELECT 146 AS CheckID,
			                        200 AS Priority,
			                        ''Performance'' AS FindingsGroup,
			                        ''In-Memory OLTP (Hekaton) In Use'' AS Finding,
			                        ''http://BrentOzar.com/go/hekaton'' AS URL,
			                        CAST(CAST((SUM(mem.pages_kb / 1024.0) / CAST(value_in_use AS INT) * 100) AS INT) AS NVARCHAR(100)) + ''% of your '' + CAST(CAST((CAST(value_in_use AS DECIMAL(38,1)) / 1024) AS MONEY) AS NVARCHAR(100)) + ''GB of your max server memory is being used for in-memory OLTP tables (Hekaton).'' AS Details
			                        FROM sys.configurations c INNER JOIN sys.dm_os_memory_clerks mem ON mem.type = ''MEMORYCLERK_XTP''
                                    WHERE c.name = ''max server memory (MB)''
                                    GROUP BY c.value_in_use
                                    HAVING SUM(mem.pages_kb / 1024.0) > 10';
		                        EXECUTE(@StringToExecute);
	                        END

                        /* In-Memory OLTP (Hekaton) - Transaction Errors */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 147 )
	                        AND EXISTS ( SELECT *
					                        FROM   sys.all_objects o
					                        WHERE  o.name = 'dm_xtp_transaction_stats' )
	                        BEGIN
		                        SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			                        SELECT 147 AS CheckID,
			                        100 AS Priority,
			                        ''In-Memory OLTP (Hekaton)'' AS FindingsGroup,
			                        ''Transaction Errors'' AS Finding,
			                        ''http://BrentOzar.com/go/hekaton'' AS URL,
			                        ''Since restart: '' + CAST(validation_failures AS NVARCHAR(100)) + '' validation failures, '' + CAST(dependencies_failed AS NVARCHAR(100)) + '' dependency failures, '' + CAST(write_conflicts AS NVARCHAR(100)) + '' write conflicts, '' + CAST(unique_constraint_violations AS NVARCHAR(100)) + '' unique constraint violations.'' AS Details
			                        FROM sys.dm_xtp_transaction_stats
                                    WHERE validation_failures <> 0
                                            OR dependencies_failed <> 0
                                            OR write_conflicts <> 0
                                            OR unique_constraint_violations <> 0;'
		                        EXECUTE(@StringToExecute);
	                        END



                        /* Reliability - Database Files on Network File Shares */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 148 )
	                        BEGIN
		                        INSERT  INTO #BlitzResults
				                        ( CheckID ,
					                        DatabaseName ,
					                        Priority ,
					                        FindingsGroup ,
					                        Finding ,
					                        URL ,
					                        Details
				                        )
				                        SELECT DISTINCT 148 AS CheckID ,
						                        d.[name] AS DatabaseName ,
						                        50 AS Priority ,
						                        'Reliability' AS FindingsGroup ,
						                        'Database Files on Network File Shares' AS Finding ,
						                        'http://BrentOzar.com/go/nas' AS URL ,
						                        ( 'Files for this database are on: ' + LEFT(mf.physical_name, 30)) AS Details
				                        FROM    sys.databases d
                                          INNER JOIN sys.master_files mf ON d.database_id = mf.database_id
				                        WHERE mf.physical_name LIKE '\\%'
						                        AND d.name NOT IN ( SELECT DISTINCT
													                        DatabaseName
											                        FROM    #SkipChecks )
	                        END

                        /* Reliability - Database Files Stored in Azure */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 149 )
	                        BEGIN
		                        INSERT  INTO #BlitzResults
				                        ( CheckID ,
					                        DatabaseName ,
					                        Priority ,
					                        FindingsGroup ,
					                        Finding ,
					                        URL ,
					                        Details
				                        )
				                        SELECT DISTINCT 149 AS CheckID ,
						                        d.[name] AS DatabaseName ,
						                        50 AS Priority ,
						                        'Reliability' AS FindingsGroup ,
						                        'Database Files Stored in Azure' AS Finding ,
						                        'http://BrentOzar.com/go/azurefiles' AS URL ,
						                        ( 'Files for this database are on: ' + LEFT(mf.physical_name, 30)) AS Details
				                        FROM    sys.databases d
                                          INNER JOIN sys.master_files mf ON d.database_id = mf.database_id
				                        WHERE mf.physical_name LIKE 'http://%'
						                        AND d.name NOT IN ( SELECT DISTINCT
													                        DatabaseName
											                        FROM    #SkipChecks )
	                        END


                        /* Reliability - Errors Logged Recently in the Default Trace */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 150 )
                            AND @TracePath IS NOT NULL
	                        BEGIN

		                        INSERT  INTO #BlitzResults
				                        ( CheckID ,
					                        DatabaseName ,
					                        Priority ,
					                        FindingsGroup ,
					                        Finding ,
					                        URL ,
					                        Details
				                        )
				                        SELECT DISTINCT 150 AS CheckID ,
					                            t.DatabaseName,
						                        50 AS Priority ,
						                        'Reliability' AS FindingsGroup ,
						                        'Errors Logged Recently in the Default Trace' AS Finding ,
						                        'http://BrentOzar.com/go/defaulttrace' AS URL ,
						                         CAST(t.TextData AS NVARCHAR(4000)) AS Details
                                        FROM    sys.fn_trace_gettable(@TracePath, DEFAULT) t
                                        WHERE t.EventClass = 22
                                          AND t.Severity >= 17
                                          AND t.StartTime > DATEADD(dd, -30, GETDATE())
	                        END


                        /* Performance - Log File Growths Slow */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 151 )
                            AND @TracePath IS NOT NULL
	                        BEGIN
		                        INSERT  INTO #BlitzResults
				                        ( CheckID ,
					                        DatabaseName ,
					                        Priority ,
					                        FindingsGroup ,
					                        Finding ,
					                        URL ,
					                        Details
				                        )
				                        SELECT DISTINCT 151 AS CheckID ,
					                            t.DatabaseName,
						                        50 AS Priority ,
						                        'Performance' AS FindingsGroup ,
						                        'Log File Growths Slow' AS Finding ,
						                        'http://BrentOzar.com/go/filegrowth' AS URL ,
						                        CAST(COUNT(*) AS NVARCHAR(100)) + ' growths took more than 15 seconds each. Consider setting log file autogrowth to a smaller increment.' AS Details
                                        FROM    sys.fn_trace_gettable(@TracePath, DEFAULT) t
                                        WHERE t.EventClass = 93
                                          AND t.StartTime > DATEADD(dd, -30, GETDATE())
                                          AND t.Duration > 15000000
                                        GROUP BY t.DatabaseName
                                        HAVING COUNT(*) > 1
	                        END


                        /* Performance - Many Plans for One Query */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 160 )
                            AND EXISTS (SELECT * FROM sys.all_columns WHERE name = 'query_hash')
	                        BEGIN
		                        SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			                        SELECT TOP 1 160 AS CheckID,
			                        100 AS Priority,
			                        ''Performance'' AS FindingsGroup,
			                        ''Many Plans for One Query'' AS Finding,
			                        ''http://BrentOzar.com/go/parameterization'' AS URL,
			                        ''More than 50 plans are present for a single query in the plan cache - meaning we probably have parameterization issues.'' AS Details
			                        FROM sys.dm_exec_query_stats qs
                                    CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa
                                    WHERE pa.attribute = ''dbid''
                                    GROUP BY qs.query_hash, pa.value
                                    HAVING COUNT(DISTINCT plan_handle) > 50';
		                        EXECUTE(@StringToExecute);
	                        END


                        /* Outdated sp_Blitz - sp_Blitz is Over 6 Months Old */
                        IF NOT EXISTS ( SELECT  1
				                        FROM    #SkipChecks
				                        WHERE   DatabaseName IS NULL AND CheckID = 155 )
				           AND DATEDIFF(MM, @VersionDate, GETDATE()) > 6
	                        BEGIN
		                        INSERT  INTO #BlitzResults
				                        ( CheckID ,
					                        Priority ,
					                        FindingsGroup ,
					                        Finding ,
					                        URL ,
					                        Details
				                        )
				                        SELECT 155 AS CheckID ,
						                        0 AS Priority ,
						                        'Outdated sp_Blitz' AS FindingsGroup ,
						                        'sp_Blitz is Over 6 Months Old' AS Finding ,
						                        'http://www.BrentOzar.com/blitz/' AS URL ,
						                        'Some things get better with age, like fine wine and your T-SQL. However, sp_Blitz is not one of those things - time to go download the current one.' AS Details
	                        END


						/* Populate a list of database defaults. I'm doing this kind of oddly -
						    it reads like a lot of work, but this way it compiles & runs on all
						    versions of SQL Server.
						*/
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_supplemental_logging_enabled', 0, 131, 210, 'Supplemental Logging Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_supplemental_logging_enabled' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'snapshot_isolation_state', 0, 132, 210, 'Snapshot Isolation Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'snapshot_isolation_state' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_read_committed_snapshot_on', 0, 133, 210, 'Read Committed Snapshot Isolation Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_read_committed_snapshot_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_auto_create_stats_incremental_on', 0, 134, 210, 'Auto Create Stats Incremental Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_auto_create_stats_incremental_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_ansi_null_default_on', 0, 135, 210, 'ANSI NULL Default Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_ansi_null_default_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_recursive_triggers_on', 0, 136, 210, 'Recursive Triggers Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_recursive_triggers_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_trustworthy_on', 0, 137, 210, 'Trustworthy Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_trustworthy_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_parameterization_forced', 0, 138, 210, 'Forced Parameterization Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_parameterization_forced' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_query_store_on', 0, 139, 210, 'Query Store Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_query_store_on' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_cdc_enabled', 0, 140, 210, 'Change Data Capture Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_cdc_enabled' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'containment', 0, 141, 210, 'Containment Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'containment' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'target_recovery_time_in_seconds', 0, 142, 210, 'Target Recovery Time Changed', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'target_recovery_time_in_seconds' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'delayed_durability', 0, 143, 210, 'Delayed Durability Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'delayed_durability' AND object_id = OBJECT_ID('sys.databases');
						INSERT INTO #DatabaseDefaults
						  SELECT 'is_memory_optimized_elevate_to_snapshot_on', 0, 144, 210, 'Memory Optimized Enabled', 'http://BrentOzar.com/go/dbdefaults', NULL
						  FROM sys.all_columns 
						  WHERE name = 'is_memory_optimized_elevate_to_snapshot_on' AND object_id = OBJECT_ID('sys.databases');

						DECLARE DatabaseDefaultsLoop CURSOR FOR
						  SELECT name, DefaultValue, CheckID, Priority, Finding, URL, Details
						  FROM #DatabaseDefaults

						OPEN DatabaseDefaultsLoop
						FETCH NEXT FROM DatabaseDefaultsLoop into @CurrentName, @CurrentDefaultValue, @CurrentCheckID, @CurrentPriority, @CurrentFinding, @CurrentURL, @CurrentDetails
						WHILE @@FETCH_STATUS = 0
						BEGIN 

						    SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details)
						       SELECT ' + CAST(@CurrentCheckID AS NVARCHAR(200)) + ', d.[name], ' + CAST(@CurrentPriority AS NVARCHAR(200)) + ', ''Non-Default Database Config'', ''' + @CurrentFinding + ''',''' + @CurrentURL + ''',''' + COALESCE(@CurrentDetails, 'This database setting is not the default.') + '''
						        FROM sys.databases d
						        WHERE d.database_id > 4 AND (d.[' + @CurrentName + '] <> ' + @CurrentDefaultValue + ' OR d.[' + @CurrentName + '] IS NULL);';
						    EXEC (@StringToExecute);

						FETCH NEXT FROM DatabaseDefaultsLoop into @CurrentName, @CurrentDefaultValue, @CurrentCheckID, @CurrentPriority, @CurrentFinding, @CurrentURL, @CurrentDetails 
						END

						CLOSE DatabaseDefaultsLoop
						DEALLOCATE DatabaseDefaultsLoop;
							
				IF @CheckUserDatabaseObjects = 1
					BEGIN

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 32 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
			INSERT INTO #BlitzResults
			(CheckID,
			DatabaseName,
			Priority,
			FindingsGroup,
			Finding,
			URL,
			Details)
			SELECT DISTINCT 32,
			''?'',
			110,
			''Performance'',
			''Triggers on Tables'',
			''http://BrentOzar.com/go/trig'',
			(''The ['' + DB_NAME() + ''] database has triggers on the '' + s.name + ''.'' + o.name + '' table.'')
			FROM [?].sys.triggers t INNER JOIN [?].sys.objects o ON t.parent_id = o.object_id
			INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id WHERE t.is_ms_shipped = 0 AND DB_NAME() != ''ReportServer''';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 38 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
			INSERT INTO #BlitzResults
			(CheckID,
			DatabaseName,
			Priority,
			FindingsGroup,
			Finding,
			URL,
			Details)
		  SELECT DISTINCT 38,
		  ''?'',
		  110,
		  ''Performance'',
		  ''Active Tables Without Clustered Indexes'',
		  ''http://BrentOzar.com/go/heaps'',
		  (''The ['' + DB_NAME() + ''] database has heaps - tables without a clustered index - that are being actively queried.'')
		  FROM [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id
		  INNER JOIN [?].sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
		  INNER JOIN sys.databases sd ON sd.name = ''?''
		  LEFT OUTER JOIN [?].sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = sd.database_id
		  WHERE i.type_desc = ''HEAP'' AND COALESCE(ius.user_seeks, ius.user_scans, ius.user_lookups, ius.user_updates) IS NOT NULL
		  AND sd.name <> ''tempdb'' AND o.is_ms_shipped = 0 AND o.type <> ''S''';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 159 )
                            AND EXISTS(SELECT * FROM sys.all_objects WHERE name = 'fn_validate_plan_guide')
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
			INSERT INTO #BlitzResults
			(CheckID,
			DatabaseName,
			Priority,
			FindingsGroup,
			Finding,
			URL,
			Details)
		  SELECT DISTINCT 159,
		  ''?'',
		  20,
		  ''Reliability'',
		  ''Plan Guides Failing'',
		  ''http://BrentOzar.com/go/misguided'',
		  (''The ['' + DB_NAME() + ''] database has plan guides that are no longer valid, so the queries involved may be failing silently.'')
		  FROM [?].sys.plan_guides g CROSS APPLY fn_validate_plan_guide(g.plan_guide_id)';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 39 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
			INSERT INTO #BlitzResults
			(CheckID,
			DatabaseName,
			Priority,
			FindingsGroup,
			Finding,
			URL,
			Details)
		  SELECT DISTINCT 39,
		  ''?'',
		  110,
		  ''Performance'',
		  ''Inactive Tables Without Clustered Indexes'',
		  ''http://BrentOzar.com/go/heaps'',
		  (''The ['' + DB_NAME() + ''] database has heaps - tables without a clustered index - that have not been queried since the last restart.  These may be backup tables carelessly left behind.'')
		  FROM [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id
		  INNER JOIN [?].sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
		  INNER JOIN sys.databases sd ON sd.name = ''?''
		  LEFT OUTER JOIN [?].sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = sd.database_id
		  WHERE i.type_desc = ''HEAP'' AND COALESCE(ius.user_seeks, ius.user_scans, ius.user_lookups, ius.user_updates) IS NULL
		  AND sd.name <> ''tempdb'' AND o.is_ms_shipped = 0 AND o.type <> ''S''';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 46 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT 46,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Leftover Fake Indexes From Wizards'',
		  ''http://BrentOzar.com/go/hypo'',
		  (''The index ['' + DB_NAME() + ''].['' + s.name + ''].['' + o.name + ''].['' + i.name + ''] is a leftover hypothetical index from the Index Tuning Wizard or Database Tuning Advisor.  This index is not actually helping performance and should be removed.'')
		  from [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id
		  WHERE i.is_hypothetical = 1';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 47 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT 47,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Indexes Disabled'',
		  ''http://BrentOzar.com/go/ixoff'',
		  (''The index ['' + DB_NAME() + ''].['' + s.name + ''].['' + o.name + ''].['' + i.name + ''] is disabled.  This index is not actually helping performance and should either be enabled or removed.'')
		  from [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id
		  WHERE i.is_disabled = 1';
							END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 48 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT DISTINCT 48,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Foreign Keys Not Trusted'',
		  ''http://BrentOzar.com/go/trust'',
		  (''The ['' + DB_NAME() + ''] database has foreign keys that were probably disabled, data was changed, and then the key was enabled again.  Simply enabling the key is not enough for the optimizer to use this key - we have to alter the table using the WITH CHECK CHECK CONSTRAINT parameter.'')
		  from [?].sys.foreign_keys i INNER JOIN [?].sys.objects o ON i.parent_object_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id
		  WHERE i.is_not_trusted = 1 AND i.is_not_for_replication = 0 AND i.is_disabled = 0';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 56 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT 56,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Check Constraint Not Trusted'',
		  ''http://BrentOzar.com/go/trust'',
		  (''The check constraint ['' + DB_NAME() + ''].['' + s.name + ''].['' + o.name + ''].['' + i.name + ''] is not trusted - meaning, it was disabled, data was changed, and then the constraint was enabled again.  Simply enabling the constraint is not enough for the optimizer to use this constraint - we have to alter the table using the WITH CHECK CHECK CONSTRAINT parameter.'')
		  from [?].sys.check_constraints i INNER JOIN [?].sys.objects o ON i.parent_object_id = o.object_id
		  INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id
		  WHERE i.is_not_trusted = 1 AND i.is_not_for_replication = 0 AND i.is_disabled = 0';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 95 )
							BEGIN
								IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
									AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%'
									BEGIN
										EXEC dbo.sp_MSforeachdb 'USE [?];
			INSERT INTO #BlitzResults
				  (CheckID,
				  DatabaseName,
				  Priority,
				  FindingsGroup,
				  Finding,
				  URL,
				  Details)
			SELECT TOP 1 95 AS CheckID,
			''?'' as DatabaseName,
			110 AS Priority,
			''Performance'' AS FindingsGroup,
			''Plan Guides Enabled'' AS Finding,
			''http://BrentOzar.com/go/guides'' AS URL,
			(''Database ['' + DB_NAME() + ''] has query plan guides so a query will always get a specific execution plan. If you are having trouble getting query performance to improve, it might be due to a frozen plan. Review the DMV sys.plan_guides to learn more about the plan guides in place on this server.'') AS Details
			FROM [?].sys.plan_guides WHERE is_disabled = 0'
									END;
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 60 )
							BEGIN
								EXEC sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT  DISTINCT 60 AS CheckID,
		  ''?'' as DatabaseName,
		  100 AS Priority,
		  ''Performance'' AS FindingsGroup,
		  ''Fill Factor Changed'',
		  ''http://brentozar.com/go/fillfactor'' AS URL,
		  ''The ['' + DB_NAME() + ''] database has objects with fill factor < 80%. This can cause memory and storage performance problems, but may also prevent page splits.''
		  FROM    [?].sys.indexes
		  WHERE   fill_factor <> 0 AND fill_factor < 80 AND is_disabled = 0 AND is_hypothetical = 0';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 78 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT 78,
		  ''?'',
		  100,
		  ''Performance'',
		  ''Stored Procedure WITH RECOMPILE'',
		  ''http://BrentOzar.com/go/recompile'',
		  (''['' + DB_NAME() + ''].['' + SPECIFIC_SCHEMA + ''].['' + SPECIFIC_NAME + ''] has WITH RECOMPILE in the stored procedure code, which may cause increased CPU usage due to constant recompiles of the code.'')
		  from [?].INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_DEFINITION LIKE N''%WITH RECOMPILE%'' AND SPECIFIC_NAME NOT LIKE ''sp_Blitz%%'';';
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 86 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 86, DB_NAME(), 20, ''Security'', ''Elevated Permissions on a Database'', ''http://BrentOzar.com/go/elevated'', (''In ['' + DB_NAME() + ''], user ['' + u.name + '']  has the role ['' + g.name + ''].  This user can perform tasks beyond just reading and writing data.'') FROM [?].dbo.sysmembers m inner join [?].dbo.sysusers u on m.memberuid = u.uid inner join sysusers g on m.groupuid = g.uid where u.name <> ''dbo'' and g.name in (''db_owner'' , ''db_accessAdmin'' , ''db_securityadmin'' , ''db_ddladmin'')';
							END


							/*Check for non-aligned indexes in partioned databases*/

										IF NOT EXISTS ( SELECT  1
														FROM    #SkipChecks
														WHERE   DatabaseName IS NULL AND CheckID = 72 )
											BEGIN
												EXEC dbo.sp_MSforeachdb 'USE [?];
								insert into #partdb(dbname, objectname, type_desc)
								SELECT distinct db_name(DB_ID()) as DBName,o.name Object_Name,ds.type_desc
								FROM sys.objects AS o JOIN sys.indexes AS i ON o.object_id = i.object_id
								JOIN sys.data_spaces ds on ds.data_space_id = i.data_space_id
								LEFT OUTER JOIN sys.dm_db_index_usage_stats AS s ON i.object_id = s.object_id AND i.index_id = s.index_id AND s.database_id = DB_ID()
								WHERE  o.type = ''u''
								 -- Clustered and Non-Clustered indexes
								AND i.type IN (1, 2)
								AND o.object_id in
								  (
									SELECT a.object_id from
									  (SELECT ob.object_id, ds.type_desc from sys.objects ob JOIN sys.indexes ind on ind.object_id = ob.object_id join sys.data_spaces ds on ds.data_space_id = ind.data_space_id
									  GROUP BY ob.object_id, ds.type_desc ) a group by a.object_id having COUNT (*) > 1
								  )'
												INSERT  INTO #BlitzResults
														( CheckID ,
														  DatabaseName ,
														  Priority ,
														  FindingsGroup ,
														  Finding ,
														  URL ,
														  Details
														)
														SELECT DISTINCT
																72 AS CheckID ,
																dbname AS DatabaseName ,
																100 AS Priority ,
																'Performance' AS FindingsGroup ,
																'The partitioned database ' + dbname
																+ ' may have non-aligned indexes' AS Finding ,
																'http://BrentOzar.com/go/aligned' AS URL ,
																'Having non-aligned indexes on partitioned tables may cause inefficient query plans and CPU pressure' AS Details
														FROM    #partdb
														WHERE   dbname IS NOT NULL
																AND dbname NOT IN ( SELECT DISTINCT
																						  DatabaseName
																					FROM  #SkipChecks )
												DROP TABLE #partdb
											END


											IF NOT EXISTS ( SELECT  1
															FROM    #SkipChecks
															WHERE   DatabaseName IS NULL AND CheckID = 113 )
												BEGIN
													EXEC dbo.sp_MSforeachdb 'USE [?];
							  INSERT INTO #BlitzResults
									(CheckID,
									DatabaseName,
									Priority,
									FindingsGroup,
									Finding,
									URL,
									Details)
							  SELECT DISTINCT 113,
							  ''?'',
							  50,
							  ''Reliability'',
							  ''Full Text Indexes Not Updating'',
							  ''http://BrentOzar.com/go/fulltext'',
							  (''At least one full text index in this database has not been crawled in the last week.'')
							  from [?].sys.fulltext_indexes i WHERE i.is_enabled = 1 AND i.crawl_end_date < DATEADD(dd, -7, GETDATE())';
												END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 115 )
							BEGIN
								EXEC dbo.sp_MSforeachdb 'USE [?];
		  INSERT INTO #BlitzResults
				(CheckID,
				DatabaseName,
				Priority,
				FindingsGroup,
				Finding,
				URL,
				Details)
		  SELECT 115,
		  ''?'',
		  110,
		  ''Performance'',
		  ''Parallelism Rocket Surgery'',
		  ''http://BrentOzar.com/go/makeparallel'',
		  (''['' + DB_NAME() + ''] has a make_parallel function, indicating that an advanced developer may be manhandling SQL Server into forcing queries to go parallel.'')
		  from [?].INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = ''make_parallel'' AND ROUTINE_TYPE = ''FUNCTION''';
							END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 122 )
							BEGIN
								/* SQL Server 2012 and newer uses temporary stats for AlwaysOn Availability Groups, and those show up as user-created */
								IF EXISTS (SELECT *
									  FROM sys.all_columns c
									  INNER JOIN sys.all_objects o ON c.object_id = o.object_id
									  WHERE c.name = 'is_temporary' AND o.name = 'stats')

										EXEC dbo.sp_MSforeachdb 'USE [?];
												INSERT INTO #BlitzResults
													(CheckID,
													DatabaseName,
													Priority,
													FindingsGroup,
													Finding,
													URL,
													Details)
												SELECT TOP 1 122,
												''?'',
												200,
												''Performance'',
												''User-Created Statistics In Place'',
												''http://BrentOzar.com/go/userstats'',
												(''['' + DB_NAME() + ''] has user-created statistics. This indicates that someone is being a rocket scientist with the stats, and might actually be slowing things down, especially during stats updates.'')
												from [?].sys.stats WHERE user_created = 1 AND is_temporary = 0';

									ELSE
										EXEC dbo.sp_MSforeachdb 'USE [?];
												INSERT INTO #BlitzResults
													(CheckID,
													DatabaseName,
													Priority,
													FindingsGroup,
													Finding,
													URL,
													Details)
												SELECT TOP 1 122,
												''?'',
												200,
												''Performance'',
												''User-Created Statistics In Place'',
												''http://BrentOzar.com/go/userstats'',
												(''['' + DB_NAME() + ''] has user-created statistics. This indicates that someone is being a rocket scientist with the stats, and might actually be slowing things down, especially during stats updates.'')
												from [?].sys.stats WHERE user_created = 1';


							END /* IF NOT EXISTS ( SELECT  1 */


					END /* IF @CheckUserDatabaseObjects = 1 */

				IF @CheckProcedureCache = 1
					BEGIN

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 35 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
										SELECT  35 AS CheckID ,
												100 AS Priority ,
												'Performance' AS FindingsGroup ,
												'Single-Use Plans in Procedure Cache' AS Finding ,
												'http://BrentOzar.com/go/single' AS URL ,
												( CAST(COUNT(*) AS VARCHAR(10))
												  + ' query plans are taking up memory in the procedure cache. This may be wasted memory if we cache plans for queries that never get called again. This may be a good use case for SQL Server 2008''s Optimize for Ad Hoc or for Forced Parameterization.' ) AS Details
										FROM    sys.dm_exec_cached_plans AS cp
										WHERE   cp.usecounts = 1
												AND cp.objtype = 'Adhoc'
												AND EXISTS ( SELECT
																  1
															 FROM sys.configurations
															 WHERE
																  name = 'optimize for ad hoc workloads'
																  AND value_in_use = 0 )
										HAVING  COUNT(*) > 1;
							END


		  /* Set up the cache tables. Different on 2005 since it doesn't support query_hash, query_plan_hash. */
						IF @@VERSION LIKE '%Microsoft SQL Server 2005%'
							BEGIN
								IF @CheckProcedureCacheFilter = 'CPU'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
			  AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
			  FROM sys.dm_exec_query_stats qs
			  ORDER BY qs.total_worker_time DESC)
			  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
			  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
			  FROM queries qs
			  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
			  WHERE qsCaught.sql_handle IS NULL;'
										EXECUTE(@StringToExecute)
									END

								IF @CheckProcedureCacheFilter = 'Reads'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
		  AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.total_logical_reads DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'
										EXECUTE(@StringToExecute)
									END

								IF @CheckProcedureCacheFilter = 'ExecCount'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
		  AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.execution_count DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'
										EXECUTE(@StringToExecute)
									END

								IF @CheckProcedureCacheFilter = 'Duration'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
			AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
			FROM sys.dm_exec_query_stats qs
			ORDER BY qs.total_elapsed_time DESC)
			INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
			SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
			FROM queries qs
			LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
			WHERE qsCaught.sql_handle IS NULL;'
										EXECUTE(@StringToExecute)
									END

							END;
						IF @@VERSION LIKE '%Microsoft SQL Server 2008%'
							OR @@VERSION LIKE '%Microsoft SQL Server 2012%'
							OR @@VERSION LIKE '%Microsoft SQL Server 2014%'
							OR @@VERSION LIKE '%Microsoft SQL Server v.Next%'
							BEGIN
								IF @CheckProcedureCacheFilter = 'CPU'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
		  AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.total_worker_time DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'
										EXECUTE(@StringToExecute)
									END

								IF @CheckProcedureCacheFilter = 'Reads'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
		  AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.total_logical_reads DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'
										EXECUTE(@StringToExecute)
									END

								IF @CheckProcedureCacheFilter = 'ExecCount'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
		  AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.execution_count DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'
										EXECUTE(@StringToExecute)
									END

								IF @CheckProcedureCacheFilter = 'Duration'
									OR @CheckProcedureCacheFilter IS NULL
									BEGIN
										SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
		  AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM sys.dm_exec_query_stats qs
		  ORDER BY qs.total_elapsed_time DESC)
		  INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
		  SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
		  FROM queries qs
		  LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
		  WHERE qsCaught.sql_handle IS NULL;'
										EXECUTE(@StringToExecute)
									END

		/* Populate the query_plan_filtered field. Only works in 2005SP2+, but we're just doing it in 2008 to be safe. */
								UPDATE  #dm_exec_query_stats
								SET     query_plan_filtered = qp.query_plan
								FROM    #dm_exec_query_stats qs
										CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle,
																  qs.statement_start_offset,
																  qs.statement_end_offset)
										AS qp

							END;

		/* Populate the additional query_plan, text, and text_filtered fields */
						UPDATE  #dm_exec_query_stats
						SET     query_plan = qp.query_plan ,
								[text] = st.[text] ,
								text_filtered = SUBSTRING(st.text,
														  ( qs.statement_start_offset
															/ 2 ) + 1,
														  ( ( CASE qs.statement_end_offset
																WHEN -1
																THEN DATALENGTH(st.text)
																ELSE qs.statement_end_offset
															  END
															  - qs.statement_start_offset )
															/ 2 ) + 1)
						FROM    #dm_exec_query_stats qs
								CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
								CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle)
								AS qp

		/* Dump instances of our own script. We're not trying to tune ourselves. */
						DELETE  #dm_exec_query_stats
						WHERE   text LIKE '%sp_Blitz%'
								OR text LIKE '%#BlitzResults%'

		/* Look for implicit conversions */

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 63 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details ,
										  QueryPlan ,
										  QueryPlanFiltered
										)
										SELECT  63 AS CheckID ,
												120 AS Priority ,
												'Query Plans' AS FindingsGroup ,
												'Implicit Conversion' AS Finding ,
												'http://BrentOzar.com/go/implicit' AS URL ,
												( 'One of the top resource-intensive queries is comparing two fields that are not the same datatype.' ) AS Details ,
												qs.query_plan ,
												qs.query_plan_filtered
										FROM    #dm_exec_query_stats qs
										WHERE   COALESCE(qs.query_plan_filtered,
														 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%CONVERT_IMPLICIT%'
												AND COALESCE(qs.query_plan_filtered,
															 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%PhysicalOp="Index Scan"%'
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 64 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details ,
										  QueryPlan ,
										  QueryPlanFiltered
										)
										SELECT  64 AS CheckID ,
												120 AS Priority ,
												'Query Plans' AS FindingsGroup ,
												'Implicit Conversion Affecting Cardinality' AS Finding ,
												'http://BrentOzar.com/go/implicit' AS URL ,
												( 'One of the top resource-intensive queries has an implicit conversion that is affecting cardinality estimation.' ) AS Details ,
												qs.query_plan ,
												qs.query_plan_filtered
										FROM    #dm_exec_query_stats qs
										WHERE   COALESCE(qs.query_plan_filtered,
														 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%<PlanAffectingConvert ConvertIssue="Cardinality Estimate" Expression="CONVERT_IMPLICIT%'
							END

							/* @cms4j, 29.11.2013: Look for RID or Key Lookups */
							IF NOT EXISTS ( SELECT  1
											FROM    #SkipChecks
											WHERE   DatabaseName IS NULL AND CheckID = 118 )
								BEGIN
									INSERT  INTO #BlitzResults
											( CheckID ,
											  Priority ,
											  FindingsGroup ,
											  Finding ,
											  URL ,
											  Details ,
											  QueryPlan ,
											  QueryPlanFiltered
											)
											SELECT  118 AS CheckID ,
													120 AS Priority ,
													'Query Plans' AS FindingsGroup ,
													'RID or Key Lookups' AS Finding ,
													'http://BrentOzar.com/go/lookup' AS URL ,
													'One of the top resource-intensive queries contains RID or Key Lookups. Try to avoid them by creating covering indexes.' AS Details ,
													qs.query_plan ,
													qs.query_plan_filtered
											FROM    #dm_exec_query_stats qs
											WHERE   COALESCE(qs.query_plan_filtered,
															 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%Lookup="1"%'
								END /* @cms4j, 29.11.2013: Look for RID or Key Lookups */


						/* Look for missing indexes */
						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 65 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details ,
										  QueryPlan ,
										  QueryPlanFiltered
										)
										SELECT  65 AS CheckID ,
												120 AS Priority ,
												'Query Plans' AS FindingsGroup ,
												'Missing Index' AS Finding ,
												'http://BrentOzar.com/go/missingindex' AS URL ,
												( 'One of the top resource-intensive queries may be dramatically improved by adding an index.' ) AS Details ,
												qs.query_plan ,
												qs.query_plan_filtered
										FROM    #dm_exec_query_stats qs
										WHERE   COALESCE(qs.query_plan_filtered,
														 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%MissingIndexGroup%'
							END

						/* Look for cursors */
						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 66 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details ,
										  QueryPlan ,
										  QueryPlanFiltered
										)
										SELECT  66 AS CheckID ,
												120 AS Priority ,
												'Query Plans' AS FindingsGroup ,
												'Cursor' AS Finding ,
												'http://BrentOzar.com/go/cursor' AS URL ,
												( 'One of the top resource-intensive queries is using a cursor.' ) AS Details ,
												qs.query_plan ,
												qs.query_plan_filtered
										FROM    #dm_exec_query_stats qs
										WHERE   COALESCE(qs.query_plan_filtered,
														 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%<StmtCursor%'
							END

		/* Look for scalar user-defined functions */

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 67 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details ,
										  QueryPlan ,
										  QueryPlanFiltered
										)
										SELECT  67 AS CheckID ,
												120 AS Priority ,
												'Query Plans' AS FindingsGroup ,
												'Scalar UDFs' AS Finding ,
												'http://BrentOzar.com/go/functions' AS URL ,
												( 'One of the top resource-intensive queries is using a user-defined scalar function that may inhibit parallelism.' ) AS Details ,
												qs.query_plan ,
												qs.query_plan_filtered
										FROM    #dm_exec_query_stats qs
										WHERE   COALESCE(qs.query_plan_filtered,
														 CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%<UserDefinedFunction%'
							END

					END /* IF @CheckProcedureCache = 1 */

		/*Check for the last good DBCC CHECKDB date */
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 68 )
					BEGIN
						EXEC sp_MSforeachdb N'USE [?];
		INSERT #DBCCs
			(ParentObject,
			Object,
			Field,
			Value)
		EXEC (''DBCC DBInfo() With TableResults, NO_INFOMSGS'');
		UPDATE #DBCCs SET DbName = N''?'' WHERE DbName IS NULL;';

						WITH    DB2
								  AS ( SELECT DISTINCT
												Field ,
												Value ,
												DbName
									   FROM     #DBCCs
									   WHERE    Field = 'dbi_dbccLastKnownGood'
									 )
							INSERT  INTO #BlitzResults
									( CheckID ,
									  DatabaseName ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  68 AS CheckID ,
											DB2.DbName AS DatabaseName ,
											50 AS PRIORITY ,
											'Reliability' AS FindingsGroup ,
											'Last good DBCC CHECKDB over 2 weeks old' AS Finding ,
											'http://BrentOzar.com/go/checkdb' AS URL ,
											'Database [' + DB2.DbName + ']'
											+ CASE DB2.Value
												WHEN '1900-01-01 00:00:00.000'
												THEN ' never had a successful DBCC CHECKDB.'
												ELSE ' last had a successful DBCC CHECKDB run on '
													 + DB2.Value + '.'
											  END
											+ ' This check should be run regularly to catch any database corruption as soon as possible.'
											+ ' Note: you can restore a backup of a busy production database to a test server and run DBCC CHECKDB '
											+ ' against that to minimize impact. If you do that, you can ignore this warning.' AS Details
									FROM    DB2
									WHERE   DB2.DbName NOT IN ( SELECT DISTINCT
																  DatabaseName
																FROM
																  #SkipChecks )
											AND CONVERT(DATETIME, DB2.Value, 121) < DATEADD(DD,
																  -14,
																  CURRENT_TIMESTAMP)
					END

		/*Check for high VLF count: this will omit any database snapshots*/

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 69 )
					BEGIN
						IF @@VERSION LIKE 'Microsoft SQL Server 2012%' OR @@VERSION LIKE 'Microsoft SQL Server 2014%' OR @@VERSION LIKE '%Microsoft SQL Server v.Next%'

							BEGIN
								EXEC sp_MSforeachdb N'USE [?];
		  INSERT INTO #LogInfo2012
		  EXEC sp_executesql N''DBCC LogInfo() WITH NO_INFOMSGS'';
		  IF    @@ROWCOUNT > 999
		  BEGIN
			INSERT  INTO #BlitzResults
			( CheckID
			,DatabaseName
			,Priority
			,FindingsGroup
			,Finding
			,URL
			,Details)
			SELECT      69
			,DB_NAME()
			,100
			,''Performance''
			,''High VLF Count''
			,''http://BrentOzar.com/go/vlf''
			,''The ['' + DB_NAME() + ''] database has '' +  CAST(COUNT(*) as VARCHAR(20)) + '' virtual log files (VLFs). This may be slowing down startup, restores, and even inserts/updates/deletes.''
			FROM #LogInfo2012
			WHERE EXISTS (SELECT name FROM master.sys.databases
					WHERE source_database_id is null) ;
		  END
		TRUNCATE TABLE #LogInfo2012;'
								DROP TABLE #LogInfo2012;
							END
						ELSE
							BEGIN
								EXEC sp_MSforeachdb N'USE [?];
		  INSERT INTO #LogInfo
		  EXEC sp_executesql N''DBCC LogInfo() WITH NO_INFOMSGS'';
		  IF    @@ROWCOUNT > 999
		  BEGIN
			INSERT  INTO #BlitzResults
			( CheckID
			,DatabaseName
			,Priority
			,FindingsGroup
			,Finding
			,URL
			,Details)
			SELECT      69
			,DB_NAME()
			,100
			,''Performance''
			,''High VLF Count''
			,''http://BrentOzar.com/go/vlf''
			,''The ['' + DB_NAME() + ''] database has '' +  CAST(COUNT(*) as VARCHAR(20)) + '' virtual log files (VLFs). This may be slowing down startup, restores, and even inserts/updates/deletes.''
			FROM #LogInfo
			WHERE EXISTS (SELECT name FROM master.sys.databases
			WHERE source_database_id is null);
		  END
		  TRUNCATE TABLE #LogInfo;'
								DROP TABLE #LogInfo;
							END
					END

	/*Verify that the servername is set */
			IF NOT EXISTS ( SELECT  1
							FROM    #SkipChecks
							WHERE   DatabaseName IS NULL AND CheckID = 70 )
				BEGIN
					IF @@SERVERNAME IS NULL
						BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  70 AS CheckID ,
											200 AS Priority ,
											'Configuration' AS FindingsGroup ,
											'@@Servername Not Set' AS Finding ,
											'http://BrentOzar.com/go/servername' AS URL ,
											'@@Servername variable is null. You can fix it by executing: "sp_addserver ''<LocalServerName>'', local"' AS Details
						END;

					IF  /* @@SERVERNAME IS set */
						(@@SERVERNAME IS NOT NULL
						AND
						/* not a named instance */
						CHARINDEX('\',CAST(SERVERPROPERTY('ServerName') AS NVARCHAR)) = 0
						AND
						/* not clustered, when computername may be different than the servername */
						SERVERPROPERTY('IsClustered') = 0
						AND
						/* @@SERVERNAME is different than the computer name */
						@@SERVERNAME <> CAST(ISNULL(SERVERPROPERTY('ComputerNamePhysicalNetBIOS'),@@SERVERNAME) AS NVARCHAR) )
						 BEGIN
							INSERT  INTO #BlitzResults
									( CheckID ,
									  Priority ,
									  FindingsGroup ,
									  Finding ,
									  URL ,
									  Details
									)
									SELECT  70 AS CheckID ,
											200 AS Priority ,
											'Configuration' AS FindingsGroup ,
											'@@Servername Not Correct' AS Finding ,
											'http://BrentOzar.com/go/servername' AS URL ,
											'The @@Servername is different than the computer name, which may trigger certificate errors.' AS Details
						END;

				END
		/*Check to see if a failsafe operator has been configured*/
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 73 )
					BEGIN

						DECLARE @AlertInfo TABLE
							(
							  FailSafeOperator NVARCHAR(255) ,
							  NotificationMethod INT ,
							  ForwardingServer NVARCHAR(255) ,
							  ForwardingSeverity INT ,
							  PagerToTemplate NVARCHAR(255) ,
							  PagerCCTemplate NVARCHAR(255) ,
							  PagerSubjectTemplate NVARCHAR(255) ,
							  PagerSendSubjectOnly NVARCHAR(255) ,
							  ForwardAlways INT
							)
						INSERT  INTO @AlertInfo
								EXEC [master].[dbo].[sp_MSgetalertinfo] @includeaddresses = 0
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  73 AS CheckID ,
										50 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'No failsafe operator configured' AS Finding ,
										'http://BrentOzar.com/go/failsafe' AS URL ,
										( 'No failsafe operator is configured on this server.  This is a good idea just in-case there are issues with the [msdb] database that prevents alerting.' ) AS Details
								FROM    @AlertInfo
								WHERE   FailSafeOperator IS NULL;
					END

		/*Identify globally enabled trace flags*/
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 74 )
					BEGIN
						INSERT  INTO #TraceStatus
								EXEC ( ' DBCC TRACESTATUS(-1) WITH NO_INFOMSGS'
									)
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  74 AS CheckID ,
										200 AS Priority ,
										'Global Trace Flag' AS FindingsGroup ,
										'TraceFlag On' AS Finding ,
										'http://www.BrentOzar.com/go/traceflags/' AS URL ,
										'Trace flag ' + T.TraceFlag
										+ ' is enabled globally.' AS Details
								FROM    #TraceStatus T
					END

		/*Check for transaction log file larger than data file */
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 75 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  75 AS CheckID ,
										DB_NAME(a.database_id) ,
										50 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'Transaction Log Larger than Data File' AS Finding ,
										'http://BrentOzar.com/go/biglog' AS URL ,
										'The database [' + DB_NAME(a.database_id)
										+ '] has a transaction log file larger than a data file. This may indicate that transaction log backups are not being performed or not performed often enough.' AS Details
								FROM    sys.master_files a
								WHERE   a.type = 1
										AND DB_NAME(a.database_id) NOT IN (
										SELECT DISTINCT
												DatabaseName
										FROM    #SkipChecks )
										AND a.size > 125000 /* Size is measured in pages here, so this gets us log files over 1GB. */
										AND a.size > ( SELECT   SUM(CAST(b.size AS BIGINT))
													   FROM     sys.master_files b
													   WHERE    a.database_id = b.database_id
																AND b.type = 0
													 )
										AND a.database_id IN (
										SELECT  database_id
										FROM    sys.databases
										WHERE   source_database_id IS NULL )
					END

		/*Check for collation conflicts between user databases and tempdb */
				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 76 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  76 AS CheckID ,
										name AS DatabaseName ,
										50 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'Collation is ' + collation_name AS Finding ,
										'http://BrentOzar.com/go/collate' AS URL ,
										'Collation differences between user databases and tempdb can cause conflicts especially when comparing string values' AS Details
								FROM    sys.databases
							WHERE   name NOT IN ( 'master', 'model', 'msdb')
										AND name NOT LIKE 'ReportServer%'
										AND name NOT IN ( SELECT DISTINCT
																  DatabaseName
														  FROM    #SkipChecks )
										AND collation_name <> ( SELECT
																  collation_name
																FROM
																  sys.databases
																WHERE
																  name = 'tempdb'
															  )
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 77 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  DatabaseName ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  77 AS CheckID ,
										dSnap.[name] AS DatabaseName ,
										50 AS Priority ,
										'Reliability' AS FindingsGroup ,
										'Database Snapshot Online' AS Finding ,
										'http://BrentOzar.com/go/snapshot' AS URL ,
										'Database [' + dSnap.[name]
										+ '] is a snapshot of ['
										+ dOriginal.[name]
										+ ']. Make sure you have enough drive space to maintain the snapshot as the original database grows.' AS Details
								FROM    sys.databases dSnap
										INNER JOIN sys.databases dOriginal ON dSnap.source_database_id = dOriginal.database_id
																  AND dSnap.name NOT IN (
																  SELECT DISTINCT
																  DatabaseName
																  FROM
																  #SkipChecks )
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 79 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  79 AS CheckID ,
										100 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Shrink Database Job' AS Finding ,
										'http://BrentOzar.com/go/autoshrink' AS URL ,
										'In the [' + j.[name] + '] job, step ['
										+ step.[step_name]
										+ '] has SHRINKDATABASE or SHRINKFILE, which may be causing database fragmentation.' AS Details
								FROM    msdb.dbo.sysjobs j
										INNER JOIN msdb.dbo.sysjobsteps step ON j.job_id = step.job_id
								WHERE   step.command LIKE N'%SHRINKDATABASE%'
										OR step.command LIKE N'%SHRINKFILE%'
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 80 )
					BEGIN
						EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 80, DB_NAME(), 50, ''Reliability'', ''Max File Size Set'', ''http://BrentOzar.com/go/maxsize'', (''The ['' + DB_NAME() + ''] database file '' + name + '' has a max file size set to '' + CAST(CAST(max_size AS BIGINT) * 8 / 1024 AS VARCHAR(100)) + ''MB. If it runs out of space, the database will stop working even though there may be drive space available.'') FROM sys.database_files WHERE max_size <> 268435456 AND max_size <> -1 AND type <> 2';
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 81 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT  81 AS CheckID ,
										200 AS Priority ,
										'Non-Active Server Config' AS FindingsGroup ,
										cr.name AS Finding ,
										'http://www.BrentOzar.com/blitz/sp_configure/' AS URL ,
										( 'This sp_configure option isn''t running under its set value.  Its set value is '
										  + CAST(cr.[Value] AS VARCHAR(100))
										  + ' and its running value is '
										  + CAST(cr.value_in_use AS VARCHAR(100))
										  + '. When someone does a RECONFIGURE or restarts the instance, this setting will start taking effect.' ) AS Details
								FROM    sys.configurations cr
								WHERE   cr.value <> cr.value_in_use;
					END

				IF NOT EXISTS ( SELECT  1
								FROM    #SkipChecks
								WHERE   DatabaseName IS NULL AND CheckID = 123 )
					BEGIN
						INSERT  INTO #BlitzResults
								( CheckID ,
								  Priority ,
								  FindingsGroup ,
								  Finding ,
								  URL ,
								  Details
								)
								SELECT TOP 1 123 AS CheckID ,
										200 AS Priority ,
										'Performance' AS FindingsGroup ,
										'Agent Jobs Starting Simultaneously' AS Finding ,
										'http://BrentOzar.com/go/busyagent/' AS URL ,
										( 'Multiple SQL Server Agent jobs are configured to start simultaneously. For detailed schedule listings, see the query in the URL.' ) AS Details
								FROM    msdb.dbo.sysjobactivity
								WHERE start_execution_date > DATEADD(dd, -14, GETDATE())
								GROUP BY start_execution_date HAVING COUNT(*) > 1;
					END


				IF @CheckServerInfo = 1
					BEGIN

					IF NOT EXISTS ( SELECT  1
									FROM    #SkipChecks
									WHERE   DatabaseName IS NULL AND CheckID = 130 )
						BEGIN
									INSERT  INTO #BlitzResults
											( CheckID ,
											  Priority ,
											  FindingsGroup ,
											  Finding ,
											  URL ,
											  Details
											)
											SELECT  130 AS CheckID ,
													250 AS Priority ,
													'Server Info' AS FindingsGroup ,
													'Server Name' AS Finding ,
													'http://BrentOzar.com/go/servername' AS URL ,
													@@SERVERNAME AS Details
												WHERE @@SERVERNAME IS NOT NULL;
								END;



						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 83 )
							BEGIN
								IF EXISTS ( SELECT  *
											FROM    sys.all_objects
											WHERE   name = 'dm_server_services' )
									BEGIN
										SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
				SELECT  83 AS CheckID ,
				250 AS Priority ,
				''Server Info'' AS FindingsGroup ,
				''Services'' AS Finding ,
				'''' AS URL ,
				N''Service: '' + servicename + N'' runs under service account '' + service_account + N''. Last startup time: '' + COALESCE(CAST(CAST(last_startup_time AS DATETIME) AS VARCHAR(50)), ''not shown.'') + ''. Startup type: '' + startup_type_desc + N'', currently '' + status_desc + ''.''
				FROM sys.dm_server_services;'
										EXECUTE(@StringToExecute);
									END
							END

			/* Check 84 - SQL Server 2012 */
						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 84 )
							BEGIN
								IF EXISTS ( SELECT  *
											FROM    sys.all_objects o
													INNER JOIN sys.all_columns c ON o.object_id = c.object_id
											WHERE   o.name = 'dm_os_sys_info'
													AND c.name = 'physical_memory_kb' )
									BEGIN
										SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			SELECT  84 AS CheckID ,
			250 AS Priority ,
			''Server Info'' AS FindingsGroup ,
			''Hardware'' AS Finding ,
			'''' AS URL ,
			''Logical processors: '' + CAST(cpu_count AS VARCHAR(50)) + ''. Physical memory: '' + CAST( CAST(ROUND((physical_memory_kb / 1024.0 / 1024), 1) AS INT) AS VARCHAR(50)) + ''GB.''
			FROM sys.dm_os_sys_info';
										EXECUTE(@StringToExecute);
									END

			/* Check 84 - SQL Server 2008 */
								IF EXISTS ( SELECT  *
											FROM    sys.all_objects o
													INNER JOIN sys.all_columns c ON o.object_id = c.object_id
											WHERE   o.name = 'dm_os_sys_info'
													AND c.name = 'physical_memory_in_bytes' )
									BEGIN
										SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
			SELECT  84 AS CheckID ,
			250 AS Priority ,
			''Server Info'' AS FindingsGroup ,
			''Hardware'' AS Finding ,
			'''' AS URL ,
			''Logical processors: '' + CAST(cpu_count AS VARCHAR(50)) + ''. Physical memory: '' + CAST( CAST(ROUND((physical_memory_in_bytes / 1024.0 / 1024 / 1024), 1) AS INT) AS VARCHAR(50)) + ''GB.''
			FROM sys.dm_os_sys_info';
										EXECUTE(@StringToExecute);
									END
							END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 85 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
										SELECT  85 AS CheckID ,
												250 AS Priority ,
												'Server Info' AS FindingsGroup ,
												'SQL Server Service' AS Finding ,
												'' AS URL ,
												N'Version: '
												+ CAST(SERVERPROPERTY('productversion') AS NVARCHAR(100))
												+ N'. Patch Level: '
												+ CAST(SERVERPROPERTY('productlevel') AS NVARCHAR(100))
												+ N'. Edition: '
												+ CAST(SERVERPROPERTY('edition') AS VARCHAR(100))
												+ N'. AlwaysOn Enabled: '
												+ CAST(COALESCE(SERVERPROPERTY('IsHadrEnabled'),
																0) AS VARCHAR(100))
												+ N'. AlwaysOn Mgr Status: '
												+ CAST(COALESCE(SERVERPROPERTY('HadrManagerStatus'),
																0) AS VARCHAR(100))
							END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 88 )
							BEGIN
								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
										SELECT  88 AS CheckID ,
												250 AS Priority ,
												'Server Info' AS FindingsGroup ,
												'SQL Server Last Restart' AS Finding ,
												'' AS URL ,
												CAST(create_date AS VARCHAR(100))
										FROM    sys.databases
										WHERE   database_id = 2
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 92 )
							BEGIN
								INSERT  INTO #driveInfo
										( drive, SIZE )
										EXEC master..xp_fixeddrives

								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
										SELECT  92 AS CheckID ,
												250 AS Priority ,
												'Server Info' AS FindingsGroup ,
												'Drive ' + i.drive + ' Space' AS Finding ,
												'' AS URL ,
												CAST(i.SIZE AS VARCHAR)
												+ 'MB free on ' + i.drive
												+ ' drive' AS Details
										FROM    #driveInfo AS i
								DROP TABLE #driveInfo
							END


						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 103 )
							AND EXISTS ( SELECT *
										 FROM   sys.all_objects o
												INNER JOIN sys.all_columns c ON o.object_id = c.object_id
										 WHERE  o.name = 'dm_os_sys_info'
												AND c.name = 'virtual_machine_type_desc' )
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
									SELECT 103 AS CheckID,
									250 AS Priority,
									''Server Info'' AS FindingsGroup,
									''Virtual Server'' AS Finding,
									''http://BrentOzar.com/go/virtual'' AS URL,
									''Type: ('' + virtual_machine_type_desc + '')'' AS Details
									FROM sys.dm_os_sys_info
									WHERE virtual_machine_type <> 0';
								EXECUTE(@StringToExecute);
							END

						IF NOT EXISTS ( SELECT  1
										FROM    #SkipChecks
										WHERE   DatabaseName IS NULL AND CheckID = 114 )
							AND EXISTS ( SELECT *
										 FROM   sys.all_objects o
										 WHERE  o.name = 'dm_os_memory_nodes' )
							AND EXISTS ( SELECT *
										 FROM   sys.all_objects o
										 INNER JOIN sys.all_columns c ON o.object_id = c.object_id
										 WHERE  o.name = 'dm_os_nodes'
                                	 		AND c.name = 'processor_group' )
							BEGIN
								SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
										SELECT  114 AS CheckID ,
												250 AS Priority ,
												''Server Info'' AS FindingsGroup ,
												''Hardware - NUMA Config'' AS Finding ,
												'''' AS URL ,
												''Node: '' + CAST(n.node_id AS NVARCHAR(10)) + '' State: '' + node_state_desc
												+ '' Online schedulers: '' + CAST(n.online_scheduler_count AS NVARCHAR(10)) + '' Processor Group: '' + CAST(n.processor_group AS NVARCHAR(10))
												+ '' Memory node: '' + CAST(n.memory_node_id AS NVARCHAR(10)) + '' Memory VAS Reserved GB: '' + CAST(CAST((m.virtual_address_space_reserved_kb / 1024.0 / 1024) AS INT) AS NVARCHAR(100))
										FROM sys.dm_os_nodes n
										INNER JOIN sys.dm_os_memory_nodes m ON n.memory_node_id = m.memory_node_id
										WHERE n.node_state_desc NOT LIKE ''%DAC%''
										ORDER BY n.node_id'
								EXECUTE(@StringToExecute);
							END


							IF NOT EXISTS ( SELECT  1
											FROM    #SkipChecks
											WHERE   DatabaseName IS NULL AND CheckID = 106 )
											AND (select convert(int,value_in_use) from sys.configurations where name = 'default trace enabled' ) = 1
                                AND DATALENGTH( COALESCE( @base_tracefilename, '' ) ) > DATALENGTH('.TRC')
							BEGIN

								INSERT  INTO #BlitzResults
										( CheckID ,
										  Priority ,
										  FindingsGroup ,
										  Finding ,
										  URL ,
										  Details
										)
										SELECT
												 106 AS CheckID
												,250 AS Priority
												,'Server Info' AS FindingsGroup
												,'Default Trace Contents' AS Finding
												,'http://BrentOzar.com/go/trace' AS URL
												,'The default trace holds '+cast(DATEDIFF(hour,MIN(StartTime),GETDATE())as varchar)+' hours of data'
												+' between '+cast(Min(StartTime) as varchar)+' and '+cast(GETDATE()as varchar)
												+('. The default trace files are located in: '+left( @curr_tracefilename,len(@curr_tracefilename) - @indx)
												) as Details
										FROM    ::fn_trace_gettable( @base_tracefilename, default )
										WHERE EventClass BETWEEN 65500 and 65600
							END /* CheckID 106 */


							IF NOT EXISTS ( SELECT  1
											FROM    #SkipChecks
											WHERE   DatabaseName IS NULL AND CheckID = 152 )
							BEGIN
								IF EXISTS (SELECT * FROM sys.dm_os_wait_stats WHERE wait_time_ms > .1 * @CPUMSsinceStartup AND waiting_tasks_count > 0 
											AND wait_type NOT IN ('REQUEST_FOR_DEADLOCK_SEARCH',
												'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
												'SQLTRACE_BUFFER_FLUSH',
												'LAZYWRITER_SLEEP',
												'XE_TIMER_EVENT',
												'XE_DISPATCHER_WAIT',
												'FT_IFTS_SCHEDULER_IDLE_WAIT',
												'LOGMGR_QUEUE',
												'CHECKPOINT_QUEUE',
												'BROKER_TO_FLUSH',
												'BROKER_TASK_STOP',
												'BROKER_EVENTHANDLER',
												'SLEEP_TASK',
												'WAITFOR',
												'DBMIRROR_DBM_MUTEX',
												'DBMIRROR_EVENTS_QUEUE',
												'DBMIRRORING_CMD',
												'DISPATCHER_QUEUE_SEMAPHORE',
												'BROKER_RECEIVE_WAITFOR',
												'CLR_AUTO_EVENT',
												'DIRTY_PAGE_POLL',
												'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
												'ONDEMAND_TASK_QUEUE',
												'FT_IFTSHC_MUTEX',
												'CLR_MANUAL_EVENT',
												'CLR_SEMAPHORE',
												'DBMIRROR_WORKER_QUEUE',
												'DBMIRROR_DBM_EVENT',
												'SP_SERVER_DIAGNOSTICS_SLEEP',
												'HADR_CLUSAPI_CALL',
												'HADR_LOGCAPTURE_WAIT',
												'HADR_NOTIFICATION_DEQUEUE',
												'HADR_TIMER_TASK',
												'HADR_WORK_QUEUE',
												'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
												'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP'))
									BEGIN
									/* Check for waits that have had more than 10% of the server's wait time */
									WITH os(wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms)
									AS
									(SELECT wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms
										FROM sys.dm_os_wait_stats
											WHERE   wait_type NOT IN ('REQUEST_FOR_DEADLOCK_SEARCH',
												'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
												'SQLTRACE_BUFFER_FLUSH',
												'LAZYWRITER_SLEEP',
												'XE_TIMER_EVENT',
												'XE_DISPATCHER_WAIT',
												'FT_IFTS_SCHEDULER_IDLE_WAIT',
												'LOGMGR_QUEUE',
												'CHECKPOINT_QUEUE',
												'BROKER_TO_FLUSH',
												'BROKER_TASK_STOP',
												'BROKER_EVENTHANDLER',
												'SLEEP_TASK',
												'WAITFOR',
												'DBMIRROR_DBM_MUTEX',
												'DBMIRROR_EVENTS_QUEUE',
												'DBMIRRORING_CMD',
												'DISPATCHER_QUEUE_SEMAPHORE',
												'BROKER_RECEIVE_WAITFOR',
												'CLR_AUTO_EVENT',
												'DIRTY_PAGE_POLL',
												'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
												'ONDEMAND_TASK_QUEUE',
												'FT_IFTSHC_MUTEX',
												'CLR_MANUAL_EVENT',
												'CLR_SEMAPHORE',
												'DBMIRROR_WORKER_QUEUE',
												'DBMIRROR_DBM_EVENT',
												'SP_SERVER_DIAGNOSTICS_SLEEP',
												'HADR_CLUSAPI_CALL',
												'HADR_LOGCAPTURE_WAIT',
												'HADR_NOTIFICATION_DEQUEUE',
												'HADR_TIMER_TASK',
												'HADR_WORK_QUEUE',
												'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
												'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP')
												AND wait_time_ms > .1 * @CPUMSsinceStartup
												AND waiting_tasks_count > 0)
									INSERT  INTO #BlitzResults
											( CheckID ,
											  Priority ,
											  FindingsGroup ,
											  Finding ,
											  URL ,
											  Details
											)
											SELECT TOP 9
													 152 AS CheckID
													,240 AS Priority
													,'Wait Stats' AS FindingsGroup
													, CAST(ROW_NUMBER() OVER(ORDER BY os.wait_time_ms DESC) AS NVARCHAR(10)) + N' - ' + os.wait_type AS Finding
													,'http://BrentOzar.com/go/waits' AS URL
													, Details = CAST(CAST(SUM(os.wait_time_ms / 1000.0 / 60 / 60) OVER (PARTITION BY os.wait_type) AS NUMERIC(10,1)) AS NVARCHAR(20)) + N' hours of waits, ' +
													CAST(CAST((SUM(60.0 * os.wait_time_ms) OVER (PARTITION BY os.wait_type) ) / @MSSinceStartup  AS NUMERIC(10,1)) AS NVARCHAR(20)) + N' minutes average wait time per hour, ' + 
													CAST(CAST(
														100.* SUM(os.wait_time_ms) OVER (PARTITION BY os.wait_type) 
														/ (1. * SUM(os.wait_time_ms) OVER () )
														AS NUMERIC(10,1)) AS NVARCHAR(40)) + N'% of waits, ' + 
													CAST(CAST(
														100. * SUM(os.signal_wait_time_ms) OVER (PARTITION BY os.wait_type) 
														/ (1. * SUM(os.wait_time_ms) OVER ())
														AS NUMERIC(10,1)) AS NVARCHAR(40)) + N'% signal wait, ' + 
													CAST(SUM(os.waiting_tasks_count) OVER (PARTITION BY os.wait_type) AS NVARCHAR(40)) + N' waiting tasks, ' +
													CAST(CASE WHEN  SUM(os.waiting_tasks_count) OVER (PARTITION BY os.wait_type) > 0
													THEN
														CAST(
															SUM(os.wait_time_ms) OVER (PARTITION BY os.wait_type)
																/ (1. * SUM(os.waiting_tasks_count) OVER (PARTITION BY os.wait_type)) 
															AS NUMERIC(10,1))
													ELSE 0 END AS NVARCHAR(40)) + N' ms average wait time.'
											FROM    os
											ORDER BY SUM(os.wait_time_ms / 1000.0 / 60 / 60) OVER (PARTITION BY os.wait_type) DESC;
									END /* IF EXISTS (SELECT * FROM sys.dm_os_wait_stats WHERE wait_time_ms > 0 AND waiting_tasks_count > 0) */

								/* If no waits were found, add a note about that */
								IF NOT EXISTS (SELECT * FROM #BlitzResults WHERE CheckID = 152)
								BEGIN
									INSERT  INTO #BlitzResults
											( CheckID ,
											  Priority ,
											  FindingsGroup ,
											  Finding ,
											  URL ,
											  Details
											)
										VALUES (153, 240, 'Wait Stats', 'No Significant Waits Detected', 'http://BrentOzar.com/go/waits', 'This server might be just sitting around idle, or someone may have cleared wait stats recently.');
								END
							END /* CheckID 152 */    

					END /* IF @CheckServerInfo = 1 */
			END /* IF ( ( SERVERPROPERTY('ServerName') NOT IN ( SELECT ServerName */


				/* Delete priorites they wanted to skip. */
				IF @IgnorePrioritiesAbove IS NOT NULL
					DELETE  #BlitzResults
					WHERE   [Priority] > @IgnorePrioritiesAbove AND CheckID <> -1;

				IF @IgnorePrioritiesBelow IS NOT NULL
					DELETE  #BlitzResults
					WHERE   [Priority] < @IgnorePrioritiesBelow AND CheckID <> -1;

				/* Delete checks they wanted to skip. */
				IF @SkipChecksTable IS NOT NULL
					BEGIN
						DELETE  FROM #BlitzResults
						WHERE   DatabaseName IN ( SELECT    DatabaseName
												  FROM      #SkipChecks
												  WHERE CheckID IS NULL
												  AND (ServerName IS NULL OR ServerName = SERVERPROPERTY('ServerName')));
						DELETE  FROM #BlitzResults
						WHERE   CheckID IN ( SELECT    CheckID
												  FROM      #SkipChecks
												  WHERE DatabaseName IS NULL
												  AND (ServerName IS NULL OR ServerName = SERVERPROPERTY('ServerName')));
						DELETE r FROM #BlitzResults r
							INNER JOIN #SkipChecks c ON r.DatabaseName = c.DatabaseName and r.CheckID = c.CheckID
												  AND (ServerName IS NULL OR ServerName = SERVERPROPERTY('ServerName'));
					END

				/* Add summary mode */
				IF @SummaryMode > 0
					BEGIN
					UPDATE #BlitzResults
					  SET Finding = br.Finding + ' (' + CAST(brTotals.recs AS NVARCHAR(20)) + ')'
					  FROM #BlitzResults br
						INNER JOIN (SELECT FindingsGroup, Finding, Priority, COUNT(*) AS recs FROM #BlitzResults GROUP BY FindingsGroup, Finding, Priority) brTotals ON br.FindingsGroup = brTotals.FindingsGroup AND br.Finding = brTotals.Finding AND br.Priority = brTotals.Priority
						WHERE brTotals.recs > 1;

					DELETE br
					  FROM #BlitzResults br
					  WHERE EXISTS (SELECT * FROM #BlitzResults brLower WHERE br.FindingsGroup = brLower.FindingsGroup AND br.Finding = brLower.Finding AND br.Priority = brLower.Priority AND br.ID > brLower.ID);

					END

				/* Add credits for the nice folks who put so much time into building and maintaining this for free: */
				INSERT  INTO #BlitzResults
						( CheckID ,
						  Priority ,
						  FindingsGroup ,
						  Finding ,
						  URL ,
						  Details
						)
				VALUES  ( -1 ,
						  255 ,
						  'Thanks!' ,
						  'From Brent Ozar Unlimited' ,
						  'http://www.BrentOzar.com/blitz/' ,
						  'Thanks from the Brent Ozar Unlimited team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'
						);

				INSERT  INTO #BlitzResults
						( CheckID ,
						  Priority ,
						  FindingsGroup ,
						  Finding ,
						  URL ,
						  Details

						)
				VALUES  ( -1 ,
						  0 ,
						  'sp_Blitz (TM) v' + CAST(@Version AS VARCHAR(20)) + ' as of ' + CAST(CONVERT(DATETIME, @VersionDate, 102) AS VARCHAR(100)),
						  'From Brent Ozar Unlimited' ,
						  'http://www.BrentOzar.com/blitz/' ,
						  'Thanks from the Brent Ozar Unlimited team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'

						);

				INSERT  INTO #BlitzResults
						( CheckID ,
						  Priority ,
						  FindingsGroup ,
						  Finding ,
						  URL ,
						  Details

						)
				SELECT 156 ,
						  254 ,
						  'Rundate' ,
						  GETDATE() ,
						  'http://www.BrentOzar.com/blitz/' ,
						  'Captain''s log: stardate something and something...';
						  
				IF @EmailRecipients IS NOT NULL
					BEGIN
					/* Database mail won't work off a local temp table. I'm not happy about this hacky workaround either. */
					IF (OBJECT_ID('tempdb..##BlitzResults', 'U') IS NOT NULL) DROP TABLE ##BlitzResults;
					SELECT * INTO ##BlitzResults FROM #BlitzResults;
					SET @query_result_separator = char(9);
					SET @StringToExecute = 'SET NOCOUNT ON;SELECT [Priority] , [FindingsGroup] , [Finding] , [DatabaseName] , [URL] ,  [Details] , CheckID FROM ##BlitzResults ORDER BY Priority , FindingsGroup, Finding, Details; SET NOCOUNT OFF;';
					SET @EmailSubject = 'sp_Blitz (TM) Results for ' + @@SERVERNAME;
					SET @EmailBody = 'sp_Blitz (TM) v' + CAST(@Version AS VARCHAR(20)) + ' as of ' + CAST(CONVERT(DATETIME, @VersionDate, 102) AS VARCHAR(100)) + '. From Brent Ozar Unlimited: http://www.BrentOzar.com/blitz/';
					IF @EmailProfile IS NULL
						EXEC msdb.dbo.sp_send_dbmail
							@recipients = @EmailRecipients,
							@subject = @EmailSubject,
							@body = @EmailBody,
							@query_attachment_filename = 'sp_Blitz-Results.csv',
							@attach_query_result_as_file = 1,
							@query_result_header = 1,
							@query_result_width = 32767,
							@append_query_error = 1,
							@query_result_no_padding = 1,
							@query_result_separator = @query_result_separator,
							@query = @StringToExecute;
					ELSE
						EXEC msdb.dbo.sp_send_dbmail
							@profile_name = @EmailProfile,
							@recipients = @EmailRecipients,
							@subject = @EmailSubject,
							@body = @EmailBody,
							@query_attachment_filename = 'sp_Blitz-Results.csv',
							@attach_query_result_as_file = 1,
							@query_result_header = 1,
							@query_result_width = 32767,
							@append_query_error = 1,
							@query_result_no_padding = 1,
							@query_result_separator = @query_result_separator,
							@query = @StringToExecute;
					IF (OBJECT_ID('tempdb..##BlitzResults', 'U') IS NOT NULL) DROP TABLE ##BlitzResults;
				END


				/* @OutputTableName lets us export the results to a permanent table */
				IF @OutputDatabaseName IS NOT NULL
					AND @OutputSchemaName IS NOT NULL
					AND @OutputTableName IS NOT NULL
					AND EXISTS ( SELECT *
								 FROM   sys.databases
								 WHERE  QUOTENAME([name]) = @OutputDatabaseName)
					BEGIN
						SET @StringToExecute = 'USE '
							+ @OutputDatabaseName
							+ '; IF EXISTS(SELECT * FROM '
							+ @OutputDatabaseName
							+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
							+ @OutputSchemaName
							+ ''') AND NOT EXISTS (SELECT * FROM '
							+ @OutputDatabaseName
							+ '.INFORMATION_SCHEMA.TABLES WHERE QUOTENAME(TABLE_SCHEMA) = '''
							+ @OutputSchemaName + ''' AND QUOTENAME(TABLE_NAME) = '''
							+ @OutputTableName + ''') CREATE TABLE '
							+ @OutputSchemaName + '.'
							+ @OutputTableName
							+ ' (ID INT IDENTITY(1,1) NOT NULL,
								ServerName NVARCHAR(128),
								CheckDate DATETIME,
								BlitzVersion INT,
								Priority TINYINT ,
								FindingsGroup VARCHAR(50) ,
								Finding VARCHAR(200) ,
								DatabaseName NVARCHAR(128),
								URL VARCHAR(200) ,
								Details NVARCHAR(4000) ,
								QueryPlan [XML] NULL ,
								QueryPlanFiltered [NVARCHAR](MAX) NULL,
								CheckID INT ,
								CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'
						EXEC(@StringToExecute);
						SET @StringToExecute = N' IF EXISTS(SELECT * FROM '
							+ @OutputDatabaseName
							+ '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
							+ @OutputSchemaName + ''') INSERT '
							+ @OutputDatabaseName + '.'
							+ @OutputSchemaName + '.'
							+ @OutputTableName
							+ ' (ServerName, CheckDate, BlitzVersion, CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details, QueryPlan, QueryPlanFiltered) SELECT '''
							+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
							+ ''', GETDATE(), ' + CAST(@Version AS NVARCHAR(128))
							+ ', CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details, QueryPlan, QueryPlanFiltered FROM #BlitzResults ORDER BY Priority , FindingsGroup , Finding , Details';
						EXEC(@StringToExecute);
					END
				ELSE IF (SUBSTRING(@OutputTableName, 2, 2) = '##')
					BEGIN
						SET @StringToExecute = N' IF (OBJECT_ID(''tempdb..'
							+ @OutputTableName
							+ ''') IS NOT NULL) DROP TABLE ' + @OutputTableName + ';'
							+ 'CREATE TABLE '
							+ @OutputTableName
							+ ' (ID INT IDENTITY(1,1) NOT NULL,
								ServerName NVARCHAR(128),
								CheckDate DATETIME,
								BlitzVersion INT,
								Priority TINYINT ,
								FindingsGroup VARCHAR(50) ,
								Finding VARCHAR(200) ,
								DatabaseName NVARCHAR(128),
								URL VARCHAR(200) ,
								Details NVARCHAR(4000) ,
								QueryPlan [XML] NULL ,
								QueryPlanFiltered [NVARCHAR](MAX) NULL,
								CheckID INT ,
								CONSTRAINT [PK_' + CAST(NEWID() AS CHAR(36)) + '] PRIMARY KEY CLUSTERED (ID ASC));'
							+ ' INSERT '
							+ @OutputTableName
							+ ' (ServerName, CheckDate, BlitzVersion, CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details, QueryPlan, QueryPlanFiltered) SELECT '''
							+ CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128))
							+ ''', GETDATE(), ' + CAST(@Version AS NVARCHAR(128))
							+ ', CheckID, DatabaseName, Priority, FindingsGroup, Finding, URL, Details, QueryPlan, QueryPlanFiltered FROM #BlitzResults ORDER BY Priority , FindingsGroup , Finding , Details';
						EXEC(@StringToExecute);
					END
				ELSE IF (SUBSTRING(@OutputTableName, 2, 1) = '#')
					BEGIN
						RAISERROR('Due to the nature of Dymamic SQL, only global (i.e. double pound (##)) temp tables are supported for @OutputTableName', 16, 0)
					END


				DECLARE @separator AS VARCHAR(1);
				IF @OutputType = 'RSV'
					SET @separator = CHAR(31);
				ELSE
					SET @separator = ',';

				IF @OutputType = 'COUNT'
					BEGIN
						SELECT  COUNT(*) AS Warnings
						FROM    #BlitzResults
					END
				ELSE
					IF @OutputType IN ( 'CSV', 'RSV' )
						BEGIN

							SELECT  Result = CAST([Priority] AS NVARCHAR(100))
									+ @separator + CAST(CheckID AS NVARCHAR(100))
									+ @separator + COALESCE([FindingsGroup],
															'(N/A)') + @separator
									+ COALESCE([Finding], '(N/A)') + @separator
									+ COALESCE(DatabaseName, '(N/A)') + @separator
									+ COALESCE([URL], '(N/A)') + @separator
									+ COALESCE([Details], '(N/A)')
							FROM    #BlitzResults
							ORDER BY Priority ,
									FindingsGroup ,
									Finding ,
									Details;
						END
					ELSE IF @OutputXMLasNVARCHAR = 1 AND @OutputType <> 'NONE'
						BEGIN
							SELECT  [Priority] ,
									[FindingsGroup] ,
									[Finding] ,
									[DatabaseName] ,
									[URL] ,
									[Details] ,
									CAST([QueryPlan] AS NVARCHAR(MAX)) AS QueryPlan,
									[QueryPlanFiltered] ,
									CheckID
							FROM    #BlitzResults
							ORDER BY Priority ,
									FindingsGroup ,
									Finding ,
									Details;
						END
					ELSE IF @OutputType <> 'NONE'
						BEGIN
							SELECT  [Priority] ,
									[FindingsGroup] ,
									[Finding] ,
									[DatabaseName] ,
									[URL] ,
									[Details] ,
									[QueryPlan] ,
									[QueryPlanFiltered] ,
									CheckID
							FROM    #BlitzResults
							ORDER BY Priority ,
									FindingsGroup ,
									Finding ,
									Details;
						END

				DROP TABLE #BlitzResults;

				IF @OutputProcedureCache = 1
					AND @CheckProcedureCache = 1
					SELECT TOP 20
							total_worker_time / execution_count AS AvgCPU ,
							total_worker_time AS TotalCPU ,
							CAST(ROUND(100.00 * total_worker_time
									   / ( SELECT   SUM(total_worker_time)
										   FROM     sys.dm_exec_query_stats
										 ), 2) AS MONEY) AS PercentCPU ,
							total_elapsed_time / execution_count AS AvgDuration ,
							total_elapsed_time AS TotalDuration ,
							CAST(ROUND(100.00 * total_elapsed_time
									   / ( SELECT   SUM(total_elapsed_time)
										   FROM     sys.dm_exec_query_stats
										 ), 2) AS MONEY) AS PercentDuration ,
							total_logical_reads / execution_count AS AvgReads ,
							total_logical_reads AS TotalReads ,
							CAST(ROUND(100.00 * total_logical_reads
									   / ( SELECT   SUM(total_logical_reads)
										   FROM     sys.dm_exec_query_stats
										 ), 2) AS MONEY) AS PercentReads ,
							execution_count ,
							CAST(ROUND(100.00 * execution_count
									   / ( SELECT   SUM(execution_count)
										   FROM     sys.dm_exec_query_stats
										 ), 2) AS MONEY) AS PercentExecutions ,
							CASE WHEN DATEDIFF(mi, creation_time,
											   qs.last_execution_time) = 0 THEN 0
								 ELSE CAST(( 1.00 * execution_count / DATEDIFF(mi,
																  creation_time,
																  qs.last_execution_time) ) AS MONEY)
							END AS executions_per_minute ,
							qs.creation_time AS plan_creation_time ,
							qs.last_execution_time ,
							text ,
							text_filtered ,
							query_plan ,
							query_plan_filtered ,
							sql_handle ,
							query_hash ,
							plan_handle ,
							query_plan_hash
					FROM    #dm_exec_query_stats qs
					ORDER BY CASE UPPER(@CheckProcedureCacheFilter)
							   WHEN 'CPU' THEN total_worker_time
							   WHEN 'READS' THEN total_logical_reads
							   WHEN 'EXECCOUNT' THEN execution_count
							   WHEN 'DURATION' THEN total_elapsed_time
							   ELSE total_worker_time
							 END DESC

	END /* ELSE -- IF @OutputType = 'SCHEMA' */
    SET NOCOUNT OFF;
GO





IF OBJECT_ID('tempdb..##sp_BlitzIndex') IS NOT NULL 
	DROP PROCEDURE ##sp_BlitzIndex;
GO

CREATE PROCEDURE ##sp_BlitzIndex
	@DatabaseName NVARCHAR(128) = null, /*Defaults to current DB if not specified*/
	@Mode tinyint=0, /*0=diagnose, 1=Summarize, 2=Index Usage Detail, 3=Missing Index Detail*/
	@SchemaName NVARCHAR(128) = NULL, /*Requires table_name as well.*/
	@TableName NVARCHAR(128) = NULL,  /*Requires schema_name as well.*/
		/*Note:@Mode doesn't matter if you're specifying schema_name and @TableName.*/
	@Filter tinyint = 0 /* 0=no filter (default). 1=No low-usage warnings for objects with 0 reads. 2=Only warn for objects >= 500MB */
		/*Note:@Filter doesn't do anything unless @Mode=0*/
/*
sp_BlitzIndex(TM) v2.02 - Jan 30, 2014

(C) 2014, Brent Ozar Unlimited(TM). 
See http://BrentOzar.com/go/eula for the End User Licensing Agreement.

For help and how-to info, visit http://www.BrentOzar.com/BlitzIndex

How to use:
--	Diagnose:
		EXEC dbo.sp_BlitzIndex @DatabaseName='AdventureWorks';
--	Return detail for a specific table:
		EXEC dbo.sp_BlitzIndex @DatabaseName='AdventureWorks', @SchemaName='Person', @TableName='Person';

Known limitations of this version:
 - Does not include FULLTEXT indexes. (A possibility in the future, let us know if you're interested.)
 - Index create statements are just to give you a rough idea of the syntax. It includes filters and fillfactor.
 --		Example 1: index creates use ONLINE=? instead of ONLINE=ON / ONLINE=OFF. This is because it's important for the user to understand if it's going to be offline and not just run a script.
 --		Example 2: they do not include all the options the index may have been created with (padding, compression filegroup/partition scheme etc.)
 --		(The compression and filegroup index create syntax isn't trivial because it's set at the partition level and isn't trivial to code. Two people have voted for wanting it so far.)
 - Doesn't advise you about data modeling for clustered indexes and primary keys (primarily looks for signs of insanity.)
 - Found something? Let us know at help@brentozar.com.

 Thanks for using sp_BlitzIndex(TM)!
 Sincerely,
 The Humans of Brent Ozar Unlimited(TM)

CHANGE LOG (last five versions):
	Jan 30, 2014 (v2.02)
		Standardized calling parameters with sp_AskBrent(TM) and sp_BlitzIndex(TM). (@DatabaseName instead of @database_name, etc)
		Added check_id 80 and 81-- what appear to be the most frequently used indexes (workaholics)
		Added index_operational_stats info to table level output -- recent scans vs lookups
		Broke index_usage_stats output into two categories, scans and lookups (also in table level output)
		Changed db name, table name, index name to 128 length
		Fixed findings_group column length in #BlitzIndexResults (fixed issues for users w/ longer db names)
		Fixed issue where identities nearing end of range were only detected if the check was run with a specific db context
			Fixed extra tab in @SchemaName= that made pasting into Excel awkward/wrong
		Added abnormal psychology check for clustered columnstore indexes (and general support for detecting them)
		Standardized underscores in create TSQL for missing indexes
		Better error message when running in table mode and the table isn't found.
		Added current timestamp to the header based on user request. (Didn't add startup time-- sorry! Too many things reset usage info, don't want to mislead anyone.)
		Added fillfactor to index create statements.
		Changed all index create statements to ONLINE=?, SORT_IN_TEMPDB=?. The user should decide at index create time what's right for them.
	May 26, 2013 (v2.01)
		Added check_id 28: Non-unqiue clustered indexes. (This should have been checked in for an earlier version, it slipped by).
	May 14, 2013 (v2.0) - Added data types and max length to all columns (keys, includes, secret columns)
		Set sp_blitz to default to current DB if database_name is not specified when called
		Added @Filter:  
			0=no filter (default)
			1=Don't throw low-usage warnings for objects with 0 reads (helpful for dev/non-production environments)
			2=Only report on objects >= 250MB (helps focus on larger indexes). Still runs a few database-wide checks as well.
		Added list of all columns and types in table for runs using: @DatabaseName, @SchemaName, @TableName
		Added count of total number of indexes a column is part of.
		Added check_id 25: Addicted to nullable columns. (All or all but one column is nullable.)
		Added check_id 66 and 67 to flag tables/indexes created within 1 week or modified within 48 hours.
		Added check_id 26: Wide tables (35+ cols or > 2000 non-LOB bytes).
		Added check_id 27: Addicted to strings. Looks for tables with 4 or more columns, of which all or all but one are string or LOB types.
		Added check_id 68: Identity columns within 30% of the end of range (tinyint, smallint, int) AND
			Negative identity seeds or identity increments <> 1
		Added check_id 69: Column collation does not match database collation
		Added check_id 70: Replicated columns. This identifies which columns are in at least one replication publication.
		Added check_id 71: Cascading updates or cascading deletes.
		Split check_id 40 into two checks: fillfactor on nonclustered indexes < 80%, fillfactor on clustered indexes < 90%
		Added check_id 33: Potential filtered indexes based on column names.
		Fixed bug where you couldn't see detailed view for indexed views. 
			(Ex: EXEC dbo.sp_BlitzIndex @DatabaseName='AdventureWorks', @SchemaName='Production', @TableName='vProductAndDescription';)
		Added four index usage columns to table detail output: last_user_seek, last_user_scan, last_user_lookup, last_user_update
		Modified check_id 24. This now looks for wide clustered indexes (> 3 columns OR > 16 bytes).
			Previously just simplistically looked for multiple column CX.
		Removed extra spacing (non-breaking) in more_info column.
		Fixed bug where create t-sql didn't include filter (for filtered indexes)
		Fixed formatting bug where "magic number" in table detail view didn't have commas
		Neatened up column names in result sets.
	April 8, 2013 (v1.5) - Fixed breaking bug for partitioned tables with > 10(ish) partitions
		Added schema_name to suggested create statement for PKs
		Handled "magic_benefit_number" values for missing indexes >= 922,337,203,685,477
		Added count of NC indexes to Index Hoarder: Multi-column clustered index finding
		Added link to EULA
		Simplified aggressive index checks (blocking). Multiple checks confused people more than it helped.
			Left only "Total lock wait time > 5 minutes (row + page)".
		Added CheckId 25 for non-unique clustered indexes. 
		The "Create TSQL" column now shows a commented out drop command for disabled non-clustered indexes
		Updated query which joins to sys.dm_operational_stats DMV when running against 2012 for performance reasons
	December 20, 2012 (v1.4) - Fixed bugs for instances using a case-sensitive collation
		Added support to identify compressed indexes
		Added basic support for columnstore, XML, and spatial indexes
		Added "Abnormal Psychology" diagnosis to alert you to special index types in a database
		Removed hypothetical indexes and disabled indexes from "multiple personality disorders"
		Fixed bug where hypothetical indexes weren't showing up in "self-loathing indexes"
		Fixed bug where the partitioning key column was displayed in the key of aligned nonclustered indexes on partitioned tables
		Added set options to the script so procedure is created with required settings for its use of computed columns

*/
AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


DECLARE	@DatabaseID INT;
DECLARE @ObjectID INT;
DECLARE	@dsql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
DECLARE	@msg NVARCHAR(4000);
DECLARE	@ErrorSeverity INT;
DECLARE	@ErrorState INT;
DECLARE	@Rowcount BIGINT;
DECLARE @SQLServerProductVersion NVARCHAR(128);
DECLARE @SQLServerEdition INT;
DECLARE @FilterMB INT;
DECLARE @collation NVARCHAR(256);


SELECT @SQLServerProductVersion = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
SELECT @SQLServerEdition =CAST(SERVERPROPERTY('EngineEdition') AS INT); /* We default to online index creates where EngineEdition=3*/
SET @FilterMB=250;

IF @DatabaseName is null 
	SET @DatabaseName=DB_NAME();

SELECT	@DatabaseID = database_id
FROM	sys.databases
WHERE	[name] = @DatabaseName
	AND user_access_desc='MULTI_USER'
	AND state_desc = 'ONLINE';

----------------------------------------
--STEP 1: OBSERVE THE PATIENT
--This step puts index information into temp tables.
----------------------------------------
BEGIN TRY
	BEGIN

		--Validate SQL Server Verson

		IF (SELECT LEFT(@SQLServerProductVersion,
			  CHARINDEX('.',@SQLServerProductVersion,0)-1
			  )) <= 8
		BEGIN
			SET @msg=N'sp_BlitzIndex is only supported on SQL Server 2005 and higher. The version of this instance is: ' + @SQLServerProductVersion;
			RAISERROR(@msg,16,1);
		END

		--Short circuit here if database name does not exist.
		IF @DatabaseName IS NULL OR @DatabaseID IS NULL
		BEGIN
			SET @msg='Database does not exist or is not online/multi-user: cannot proceed.'
			RAISERROR(@msg,16,1);
		END    

		--Validate parameters.
		IF (@Mode NOT IN (0,1,2,3))
		BEGIN
			SET @msg=N'Invalid @Mode parameter. 0=diagnose, 1=summarize, 2=index detail, 3=missing index detail';
			RAISERROR(@msg,16,1);
		END

		IF (@Mode <> 0 AND @TableName IS NOT NULL)
		BEGIN
			SET @msg=N'Setting the @Mode doesn''t change behavior if you supply @TableName. Use default @Mode=0 to see table detail.';
			RAISERROR(@msg,16,1);
		END

		IF ((@Mode <> 0 OR @TableName IS NOT NULL) and @Filter <> 0)
		BEGIN
			SET @msg=N'@Filter only appies when @Mode=0 and @TableName is not specified. Please try again.';
			RAISERROR(@msg,16,1);
		END

		IF (@SchemaName IS NOT NULL AND @TableName IS NULL) 
		BEGIN
			SET @msg='We can''t run against a whole schema! Specify a @TableName, or leave both NULL for diagnosis.'
			RAISERROR(@msg,16,1);
		END


		IF  (@TableName IS NOT NULL AND @SchemaName IS NULL)
		BEGIN
			SET @SchemaName=N'dbo'
			SET @msg='@SchemaName wasn''t specified-- assuming schema=dbo.'
			RAISERROR(@msg,1,1) WITH NOWAIT;
		END

		--If a table is specified, grab the object id.
		--Short circuit if it doesn't exist.
		IF @TableName IS NOT NULL
		BEGIN
			SET @dsql = N'
					SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
					SELECT	@ObjectID= OBJECT_ID
					FROM	' + QUOTENAME(@DatabaseName) + N'.sys.objects AS so
					JOIN	' + QUOTENAME(@DatabaseName) + N'.sys.schemas AS sc on 
						so.schema_id=sc.schema_id
					where so.type in (''U'', ''V'')
					and so.name=' + QUOTENAME(@TableName,'''')+ N'
					and sc.name=' + QUOTENAME(@SchemaName,'''')+ N'
					/*Has a row in sys.indexes. This lets us get indexed views.*/
					and exists (
						SELECT si.name
						FROM ' + QUOTENAME(@DatabaseName) + '.sys.indexes AS si 
						WHERE so.object_id=si.object_id)
					OPTION (RECOMPILE);';

			SET @params='@ObjectID INT OUTPUT'				

			IF @dsql IS NULL 
				RAISERROR('@dsql is null',16,1);

			EXEC sp_executesql @dsql, @params, @ObjectID=@ObjectID OUTPUT;
			
			IF @ObjectID IS NULL
					BEGIN
						SET @msg=N'Oh, this is awkward. I can''t find the table or indexed view you''re looking for in that database.' + CHAR(10) +
							N'Please check your parameters.'
						RAISERROR(@msg,1,1);
						RETURN;
					END
		END

		RAISERROR(N'Starting run. sp_BlitzIndex(TM) v2.02 - Jan 30, 2014', 0,1) WITH NOWAIT;

		IF OBJECT_ID('tempdb..#IndexSanity') IS NOT NULL 
			DROP TABLE #IndexSanity;

		IF OBJECT_ID('tempdb..#IndexPartitionSanity') IS NOT NULL 
			DROP TABLE #IndexPartitionSanity;

		IF OBJECT_ID('tempdb..#IndexSanitySize') IS NOT NULL 
			DROP TABLE #IndexSanitySize;

		IF OBJECT_ID('tempdb..#IndexColumns') IS NOT NULL 
			DROP TABLE #IndexColumns;

		IF OBJECT_ID('tempdb..#MissingIndexes') IS NOT NULL 
			DROP TABLE #MissingIndexes;

		IF OBJECT_ID('tempdb..#ForeignKeys') IS NOT NULL 
			DROP TABLE #ForeignKeys;

		IF OBJECT_ID('tempdb..#BlitzIndexResults') IS NOT NULL 
			DROP TABLE #BlitzIndexResults;
		
		IF OBJECT_ID('tempdb..#IndexCreateTsql') IS NOT NULL	
			DROP TABLE #IndexCreateTsql;

		RAISERROR (N'Create temp tables.',0,1) WITH NOWAIT;
		CREATE TABLE #BlitzIndexResults
			(
			  blitz_result_id INT IDENTITY PRIMARY KEY,
			  check_id INT NOT NULL,
			  index_sanity_id INT NULL,
			  findings_group VARCHAR(4000) NOT NULL,
			  finding VARCHAR(200) NOT NULL,
			  URL VARCHAR(200) NOT NULL,
			  details NVARCHAR(4000) NOT NULL,
			  index_definition NVARCHAR(MAX) NOT NULL,
			  secret_columns NVARCHAR(MAX) NULL,
			  index_usage_summary NVARCHAR(MAX) NULL,
			  index_size_summary NVARCHAR(MAX) NULL,
			  create_tsql NVARCHAR(MAX) NULL,
			  more_info NVARCHAR(MAX)NULL
			);

		CREATE TABLE #IndexSanity
			(
			  [index_sanity_id] INT IDENTITY PRIMARY KEY,
			  [database_id] SMALLINT NOT NULL ,
			  [object_id] INT NOT NULL ,
			  [index_id] INT NOT NULL ,
			  [index_type] TINYINT NOT NULL,
			  [database_name] NVARCHAR(128) NOT NULL ,
			  [schema_name] NVARCHAR(128) NOT NULL ,
			  [object_name] NVARCHAR(128) NOT NULL ,
			  index_name NVARCHAR(128) NULL ,
			  key_column_names NVARCHAR(MAX) NULL ,
			  key_column_names_with_sort_order NVARCHAR(MAX) NULL ,
			  key_column_names_with_sort_order_no_types NVARCHAR(MAX) NULL ,
			  count_key_columns INT NULL ,
			  include_column_names NVARCHAR(MAX) NULL ,
			  include_column_names_no_types NVARCHAR(MAX) NULL ,
			  count_included_columns INT NULL ,
			  partition_key_column_name NVARCHAR(MAX) NULL,
			  filter_definition NVARCHAR(MAX) NOT NULL ,
			  is_indexed_view BIT NOT NULL ,
			  is_unique BIT NOT NULL ,
			  is_primary_key BIT NOT NULL ,
			  is_XML BIT NOT NULL,
			  is_spatial BIT NOT NULL,
			  is_NC_columnstore BIT NOT NULL,
			  is_CX_columnstore BIT NOT NULL,
			  is_disabled BIT NOT NULL ,
			  is_hypothetical BIT NOT NULL ,
			  is_padded BIT NOT NULL ,
			  fill_factor SMALLINT NOT NULL ,
			  user_seeks BIGINT NOT NULL ,
			  user_scans BIGINT NOT NULL ,
			  user_lookups BIGINT NOT  NULL ,
			  user_updates BIGINT NULL ,
			  last_user_seek DATETIME NULL ,
			  last_user_scan DATETIME NULL ,
			  last_user_lookup DATETIME NULL ,
			  last_user_update DATETIME NULL ,
			  is_referenced_by_foreign_key BIT DEFAULT(0),
			  secret_columns NVARCHAR(MAX) NULL,
			  count_secret_columns INT NULL,
			  create_date DATETIME NOT NULL,
			  modify_date DATETIME NOT NULL
			);	

		CREATE TABLE #IndexPartitionSanity
			(
			  [index_partition_sanity_id] INT IDENTITY PRIMARY KEY ,
			  [index_sanity_id] INT NULL ,
			  [object_id] INT NOT NULL ,
			  [index_id] INT NOT NULL ,
			  [partition_number] INT NOT NULL ,
			  row_count BIGINT NOT NULL ,
			  reserved_MB NUMERIC(29,2) NOT NULL ,
			  reserved_LOB_MB NUMERIC(29,2) NOT NULL ,
			  reserved_row_overflow_MB NUMERIC(29,2) NOT NULL ,
			  leaf_insert_count BIGINT NULL ,
			  leaf_delete_count BIGINT NULL ,
			  leaf_update_count BIGINT NULL ,
			  range_scan_count BIGINT NULL ,
			  singleton_lookup_count BIGINT NULL , 
			  forwarded_fetch_count BIGINT NULL ,
			  lob_fetch_in_pages BIGINT NULL ,
			  lob_fetch_in_bytes BIGINT NULL ,
			  row_overflow_fetch_in_pages BIGINT NULL ,
			  row_overflow_fetch_in_bytes BIGINT NULL ,
			  row_lock_count BIGINT NULL ,
			  row_lock_wait_count BIGINT NULL ,
			  row_lock_wait_in_ms BIGINT NULL ,
			  page_lock_count BIGINT NULL ,
			  page_lock_wait_count BIGINT NULL ,
			  page_lock_wait_in_ms BIGINT NULL ,
			  index_lock_promotion_attempt_count BIGINT NULL ,
			  index_lock_promotion_count BIGINT NULL,
  			  data_compression_desc VARCHAR(60) NULL
			);

		CREATE TABLE #IndexSanitySize
			(
			  [index_sanity_size_id] INT IDENTITY NOT NULL ,
			  [index_sanity_id] INT NOT NULL ,
			  partition_count INT NOT NULL ,
			  total_rows BIGINT NOT NULL ,
			  total_reserved_MB NUMERIC(29,2) NOT NULL ,
			  total_reserved_LOB_MB NUMERIC(29,2) NOT NULL ,
			  total_reserved_row_overflow_MB NUMERIC(29,2) NOT NULL ,
			  total_leaf_delete_count BIGINT NULL,
			  total_leaf_update_count BIGINT NULL,
			  total_range_scan_count BIGINT NULL,
			  total_singleton_lookup_count BIGINT NULL,
			  total_forwarded_fetch_count BIGINT NULL,
			  total_row_lock_count BIGINT NULL ,
			  total_row_lock_wait_count BIGINT NULL ,
			  total_row_lock_wait_in_ms BIGINT NULL ,
			  avg_row_lock_wait_in_ms BIGINT NULL ,
			  total_page_lock_count BIGINT NULL ,
			  total_page_lock_wait_count BIGINT NULL ,
			  total_page_lock_wait_in_ms BIGINT NULL ,
			  avg_page_lock_wait_in_ms BIGINT NULL ,
 			  total_index_lock_promotion_attempt_count BIGINT NULL ,
			  total_index_lock_promotion_count BIGINT NULL ,
			  data_compression_desc VARCHAR(8000) NULL
			);

		CREATE TABLE #IndexColumns
			(
			  [object_id] INT NOT NULL ,
			  [index_id] INT NOT NULL ,
			  [key_ordinal] INT NULL ,
			  is_included_column BIT NULL ,
			  is_descending_key BIT NULL ,
			  [partition_ordinal] INT NULL ,
			  column_name NVARCHAR(256) NOT NULL ,
			  system_type_name NVARCHAR(256) NOT NULL,
			  max_length SMALLINT NOT NULL,
			  [precision] TINYINT NOT NULL,
			  [scale] TINYINT NOT NULL,
			  collation_name NVARCHAR(256) NULL,
			  is_nullable bit NULL,
			  is_identity bit NULL,
			  is_computed bit NULL,
			  is_replicated bit NULL,
			  is_sparse bit NULL,
			  is_filestream bit NULL,
			  seed_value BIGINT NULL,
			  increment_value INT NULL ,
			  last_value BIGINT NULL,
			  is_not_for_replication BIT NULL
			);

		CREATE TABLE #MissingIndexes
			([object_id] INT NOT NULL,
			[database_name] NVARCHAR(128) NOT NULL ,
			[schema_name] NVARCHAR(128) NOT NULL ,
			[table_name] NVARCHAR(128),
			[statement] NVARCHAR(512) NOT NULL,
			magic_benefit_number AS (( user_seeks + user_scans ) * avg_total_user_cost * avg_user_impact),
			avg_total_user_cost NUMERIC(29,1) NOT NULL,
			avg_user_impact NUMERIC(29,1) NOT NULL,
			user_seeks BIGINT NOT NULL,
			user_scans BIGINT NOT NULL,
			unique_compiles BIGINT NULL,
			equality_columns NVARCHAR(4000), 
			inequality_columns NVARCHAR(4000),
			included_columns NVARCHAR(4000)
			);

		CREATE TABLE #ForeignKeys (
			foreign_key_name NVARCHAR(256),
			parent_object_id INT,
			parent_object_name NVARCHAR(256),
			referenced_object_id INT,
			referenced_object_name NVARCHAR(256),
			is_disabled BIT,
			is_not_trusted BIT,
			is_not_for_replication BIT,
			parent_fk_columns NVARCHAR(MAX),
			referenced_fk_columns NVARCHAR(MAX),
			update_referential_action_desc NVARCHAR(16),
			delete_referential_action_desc NVARCHAR(60)
		)
		
		CREATE TABLE #IndexCreateTsql (
			index_sanity_id INT NOT NULL,
			create_tsql NVARCHAR(MAX) NOT NULL
		)

		--set @collation
		SELECT @collation=collation_name
		FROM sys.databases
		where database_id=@DatabaseID;

		--insert columns for clustered indexes and heaps
		--collect info on identity columns for this one
		SET @dsql = N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
				SELECT	
					si.object_id, 
					si.index_id, 
					sc.key_ordinal, 
					sc.is_included_column, 
					sc.is_descending_key,
					sc.partition_ordinal,
					c.name as column_name, 
					st.name as system_type_name,
					c.max_length,
					c.[precision],
					c.[scale],
					c.collation_name,
					c.is_nullable,
					c.is_identity,
					c.is_computed,
					c.is_replicated,
					' + case when @SQLServerProductVersion not like '9%' THEN N'c.is_sparse' else N'NULL as is_sparse' END + N',
					' + case when @SQLServerProductVersion not like '9%' THEN N'c.is_filestream' else N'NULL as is_filestream' END + N',
					CAST(ic.seed_value AS BIGINT),
					CAST(ic.increment_value AS INT),
					CAST(ic.last_value AS BIGINT),
					ic.is_not_for_replication
				FROM	' + QUOTENAME(@DatabaseName) + N'.sys.indexes si
				JOIN	' + QUOTENAME(@DatabaseName) + N'.sys.columns c ON
					si.object_id=c.object_id
				LEFT JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.index_columns sc ON 
					sc.object_id = si.object_id
					and sc.index_id=si.index_id
					AND sc.column_id=c.column_id
				LEFT JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.identity_columns ic ON
					c.object_id=ic.object_id and
					c.column_id=ic.column_id
				JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.types st ON 
					c.system_type_id=st.system_type_id
					AND c.user_type_id=st.user_type_id
				WHERE si.index_id in (0,1) ' 
					+ CASE WHEN @ObjectID IS NOT NULL 
						THEN N' AND si.object_id=' + CAST(@ObjectID AS NVARCHAR(30)) 
					ELSE N'' END 
				+ N';';

		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);

		RAISERROR (N'Inserting data into #IndexColumns for clustered indexes and heaps',0,1) WITH NOWAIT;
		INSERT	#IndexColumns ( object_id, index_id, key_ordinal, is_included_column, is_descending_key, partition_ordinal,
			column_name, system_type_name, max_length, precision, scale, collation_name, is_nullable, is_identity, is_computed,
			is_replicated, is_sparse, is_filestream, seed_value, increment_value, last_value, is_not_for_replication )
				EXEC sp_executesql @dsql;

		--insert columns for nonclustered indexes
		--this uses a full join to sys.index_columns
		--We don't collect info on identity columns here. They may be in NC indexes, but we just analyze identities in the base table.
		SET @dsql = N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
				SELECT	
					si.object_id, 
					si.index_id, 
					sc.key_ordinal, 
					sc.is_included_column, 
					sc.is_descending_key,
					sc.partition_ordinal,
					c.name as column_name, 
					st.name as system_type_name,
					c.max_length,
					c.[precision],
					c.[scale],
					c.collation_name,
					c.is_nullable,
					c.is_identity,
					c.is_computed,
					c.is_replicated,
					' + case when @SQLServerProductVersion not like '9%' THEN N'c.is_sparse' else N'NULL AS is_sparse' END + N',
					' + case when @SQLServerProductVersion not like '9%' THEN N'c.is_filestream' else N'NULL AS is_filestream' END + N'				
				FROM	' + QUOTENAME(@DatabaseName) + N'.sys.indexes AS si
				JOIN	' + QUOTENAME(@DatabaseName) + N'.sys.columns AS c ON
					si.object_id=c.object_id
				JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.index_columns AS sc ON 
					sc.object_id = si.object_id
					and sc.index_id=si.index_id
					AND sc.column_id=c.column_id
				JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.types AS st ON 
					c.system_type_id=st.system_type_id
					AND c.user_type_id=st.user_type_id
				WHERE si.index_id not in (0,1) ' 
					+ CASE WHEN @ObjectID IS NOT NULL 
						THEN N' AND si.object_id=' + CAST(@ObjectID AS NVARCHAR(30)) 
					ELSE N'' END 
				+ N';';

		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);

		RAISERROR (N'Inserting data into #IndexColumns for nonclustered indexes',0,1) WITH NOWAIT;
		INSERT	#IndexColumns ( object_id, index_id, key_ordinal, is_included_column, is_descending_key, partition_ordinal,
			column_name, system_type_name, max_length, precision, scale, collation_name, is_nullable, is_identity, is_computed,
			is_replicated, is_sparse, is_filestream )
				EXEC sp_executesql @dsql;
					
		SET @dsql = N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
				SELECT	' + CAST(@DatabaseID AS NVARCHAR(10)) + ' AS database_id, 
						so.object_id, 
						si.index_id, 
						si.type,
						' + QUOTENAME(@DatabaseName, '''') + ' AS database_name, 
						sc.NAME AS [schema_name],
						so.name AS [object_name], 
						si.name AS [index_name],
						CASE	WHEN so.[type] = CAST(''V'' AS CHAR(2)) THEN 1 ELSE 0 END, 
						si.is_unique, 
						si.is_primary_key, 
						CASE when si.type = 3 THEN 1 ELSE 0 END AS is_XML,
						CASE when si.type = 4 THEN 1 ELSE 0 END AS is_spatial,
						CASE when si.type = 6 THEN 1 ELSE 0 END AS is_NC_columnstore,
						CASE when si.type = 5 then 1 else 0 end as is_CX_columnstore,
						si.is_disabled,
						si.is_hypothetical, 
						si.is_padded, 
						si.fill_factor,'
						+ case when @SQLServerProductVersion not like '9%' THEN '
						CASE WHEN si.filter_definition IS NOT NULL THEN si.filter_definition
							 ELSE ''''
						END AS filter_definition' ELSE ''''' AS filter_definition' END + '
						, ISNULL(us.user_seeks, 0), ISNULL(us.user_scans, 0),
						ISNULL(us.user_lookups, 0), ISNULL(us.user_updates, 0), us.last_user_seek, us.last_user_scan,
						us.last_user_lookup, us.last_user_update,
						so.create_date, so.modify_date
				FROM	' + QUOTENAME(@DatabaseName) + '.sys.indexes AS si WITH (NOLOCK)
						JOIN ' + QUOTENAME(@DatabaseName) + '.sys.objects AS so WITH (NOLOCK) ON si.object_id = so.object_id
											   AND so.is_ms_shipped = 0 /*Exclude objects shipped by Microsoft*/
											   AND so.type <> ''TF'' /*Exclude table valued functions*/
						JOIN ' + QUOTENAME(@DatabaseName) + '.sys.schemas sc ON so.schema_id = sc.schema_id
						LEFT JOIN sys.dm_db_index_usage_stats AS us WITH (NOLOCK) ON si.[object_id] = us.[object_id]
																	   AND si.index_id = us.index_id
																	   AND us.database_id = '+ CAST(@DatabaseID AS NVARCHAR(10)) + '
				WHERE	si.[type] IN ( 0, 1, 2, 3, 4, 5, 6 ) 
				/* Heaps, clustered, nonclustered, XML, spatial, Cluster Columnstore, NC Columnstore */ ' +
				CASE WHEN @TableName IS NOT NULL THEN ' and so.name=' + QUOTENAME(@TableName,'''') + ' ' ELSE '' END + 
		'OPTION	( RECOMPILE );
		';
		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);

		RAISERROR (N'Inserting data into #IndexSanity',0,1) WITH NOWAIT;
		INSERT	#IndexSanity ( [database_id], [object_id], [index_id], [index_type], [database_name], [schema_name], [object_name],
								index_name, is_indexed_view, is_unique, is_primary_key, is_XML, is_spatial, is_NC_columnstore, is_CX_columnstore,
								is_disabled, is_hypothetical, is_padded, fill_factor, filter_definition, user_seeks, user_scans, 
								user_lookups, user_updates, last_user_seek, last_user_scan, last_user_lookup, last_user_update,
								create_date, modify_date )
				EXEC sp_executesql @dsql;

		RAISERROR (N'Updating #IndexSanity.key_column_names',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		key_column_names = D1.key_column_names
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + c.column_name 
									+ N' {' + system_type_name + N' ' + CAST(max_length AS NVARCHAR(50)) +  N'}'
										AS col_definition
									FROM	#IndexColumns c
									WHERE	c.object_id = si.object_id
											AND c.index_id = si.index_id
											AND c.is_included_column = 0 /*Just Keys*/
											AND c.key_ordinal > 0 /*Ignore non-key columns, such as partitioning keys*/
									ORDER BY c.object_id, c.index_id, c.key_ordinal	
							FOR	  XML PATH('') ,TYPE).value('.', 'varchar(max)'), 1, 1, ''))
										) D1 ( key_column_names )

		RAISERROR (N'Updating #IndexSanity.partition_key_column_name',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		partition_key_column_name = D1.partition_key_column_name
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + c.column_name AS col_definition
									FROM	#IndexColumns c
									WHERE	c.object_id = si.object_id
											AND c.index_id = si.index_id
											AND c.partition_ordinal <> 0 /*Just Partitioned Keys*/
									ORDER BY c.object_id, c.index_id, c.key_ordinal	
							FOR	  XML PATH('') , TYPE).value('.', 'varchar(max)'), 1, 1,''))) D1 
										( partition_key_column_name )

		RAISERROR (N'Updating #IndexSanity.key_column_names_with_sort_order',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		key_column_names_with_sort_order = D2.key_column_names_with_sort_order
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + c.column_name + CASE c.is_descending_key
									WHEN 1 THEN N' DESC'
									ELSE N''
								+ N' {' + system_type_name + N' ' + CAST(max_length AS NVARCHAR(50)) +  N'}'
								END AS col_definition
							FROM	#IndexColumns c
							WHERE	c.object_id = si.object_id
									AND c.index_id = si.index_id
									AND c.is_included_column = 0 /*Just Keys*/
									AND c.key_ordinal > 0 /*Ignore non-key columns, such as partitioning keys*/
							ORDER BY c.object_id, c.index_id, c.key_ordinal	
					FOR	  XML PATH('') , TYPE).value('.', 'varchar(max)'), 1, 1, ''))
					) D2 ( key_column_names_with_sort_order )

		RAISERROR (N'Updating #IndexSanity.key_column_names_with_sort_order_no_types (for create tsql)',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		key_column_names_with_sort_order_no_types = D2.key_column_names_with_sort_order_no_types
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + QUOTENAME(c.column_name) + CASE c.is_descending_key
									WHEN 1 THEN N' [DESC]'
									ELSE N''
								END AS col_definition
							FROM	#IndexColumns c
							WHERE	c.object_id = si.object_id
									AND c.index_id = si.index_id
									AND c.is_included_column = 0 /*Just Keys*/
									AND c.key_ordinal > 0 /*Ignore non-key columns, such as partitioning keys*/
							ORDER BY c.object_id, c.index_id, c.key_ordinal	
					FOR	  XML PATH('') , TYPE).value('.', 'varchar(max)'), 1, 1, ''))
					) D2 ( key_column_names_with_sort_order_no_types )

		RAISERROR (N'Updating #IndexSanity.include_column_names',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		include_column_names = D3.include_column_names
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + c.column_name
								+ N' {' + system_type_name + N' ' + CAST(max_length AS NVARCHAR(50)) +  N'}'
								FROM	#IndexColumns c
								WHERE	c.object_id = si.object_id
										AND c.index_id = si.index_id
										AND c.is_included_column = 1 /*Just includes*/
								ORDER BY c.column_name /*Order doesn't matter in includes, 
										this is here to make rows easy to compare.*/ 
						FOR	  XML PATH('') ,  TYPE).value('.', 'varchar(max)'), 1, 1, ''))
						) D3 ( include_column_names );

		RAISERROR (N'Updating #IndexSanity.include_column_names_no_types (for create tsql)',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		include_column_names_no_types = D3.include_column_names_no_types
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	RTRIM(STUFF( (SELECT	N', ' + QUOTENAME(c.column_name)
								FROM	#IndexColumns c
								WHERE	c.object_id = si.object_id
										AND c.index_id = si.index_id
										AND c.is_included_column = 1 /*Just includes*/
								ORDER BY c.column_name /*Order doesn't matter in includes, 
										this is here to make rows easy to compare.*/ 
						FOR	  XML PATH('') ,  TYPE).value('.', 'varchar(max)'), 1, 1, ''))
						) D3 ( include_column_names_no_types );

		RAISERROR (N'Updating #IndexSanity.count_key_columns and count_include_columns',0,1) WITH NOWAIT;
		UPDATE	#IndexSanity
		SET		count_included_columns = D4.count_included_columns,
				count_key_columns = D4.count_key_columns
		FROM	#IndexSanity si
				CROSS APPLY ( SELECT	SUM(CASE WHEN is_included_column = 'true' THEN 1
												 ELSE 0
											END) AS count_included_columns,
										SUM(CASE WHEN is_included_column = 'false' AND c.key_ordinal > 0 THEN 1
												 ELSE 0
											END) AS count_key_columns
							  FROM		#IndexColumns c
							  WHERE		c.object_id = si.object_id
										AND c.index_id = si.index_id 
										) AS D4 ( count_included_columns, count_key_columns );

		IF (SELECT LEFT(@SQLServerProductVersion,
			  CHARINDEX('.',@SQLServerProductVersion,0)-1
			  )) <> 11 --Anything other than 2012
		BEGIN

			RAISERROR (N'Using non-2012 syntax to query sys.dm_db_index_operational_stats',0,1) WITH NOWAIT;

			--NOTE: we're joining to sys.dm_db_index_operational_stats differently than you might think (not using a cross apply)
			--This is because of quirks prior to SQL Server 2012 and in 2014 with this DMV.
			SET @dsql = N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
						SELECT	ps.object_id, 
								ps.index_id, 
								ps.partition_number, 
								ps.row_count,
								ps.reserved_page_count * 8. / 1024. AS reserved_MB,
								ps.lob_reserved_page_count * 8. / 1024. AS reserved_LOB_MB,
								ps.row_overflow_reserved_page_count * 8. / 1024. AS reserved_row_overflow_MB,
								os.leaf_insert_count, 
								os.leaf_delete_count, 
								os.leaf_update_count, 
								os.range_scan_count, 
								os.singleton_lookup_count,  
								os.forwarded_fetch_count,
								os.lob_fetch_in_pages, 
								os.lob_fetch_in_bytes, 
								os.row_overflow_fetch_in_pages,
								os.row_overflow_fetch_in_bytes, 
								os.row_lock_count, 
								os.row_lock_wait_count,
								os.row_lock_wait_in_ms, 
								os.page_lock_count, 
								os.page_lock_wait_count, 
								os.page_lock_wait_in_ms,
								os.index_lock_promotion_attempt_count, 
								os.index_lock_promotion_count, 
							' + case when @SQLServerProductVersion not like '9%' THEN 'par.data_compression_desc ' ELSE 'null as data_compression_desc' END + '
					FROM	' + QUOTENAME(@DatabaseName) + '.sys.dm_db_partition_stats AS ps  
					JOIN ' + QUOTENAME(@DatabaseName) + '.sys.partitions AS par on ps.partition_id=par.partition_id
					JOIN ' + QUOTENAME(@DatabaseName) + '.sys.objects AS so ON ps.object_id = so.object_id
							   AND so.is_ms_shipped = 0 /*Exclude objects shipped by Microsoft*/
							   AND so.type <> ''TF'' /*Exclude table valued functions*/
					LEFT JOIN ' + QUOTENAME(@DatabaseName) + '.sys.dm_db_index_operational_stats('
				+ CAST(@DatabaseID AS NVARCHAR(10)) + ', NULL, NULL,NULL) AS os ON
					ps.object_id=os.object_id and ps.index_id=os.index_id and ps.partition_number=os.partition_number 
					WHERE 1=1 
					' + CASE WHEN @ObjectID IS NOT NULL THEN N'AND so.object_id=' + CAST(@ObjectID AS NVARCHAR(30)) + N' ' ELSE N' ' END + '
					' + CASE WHEN @Filter = 2 THEN N'AND ps.reserved_page_count * 8./1024. > ' + CAST(@FilterMB AS NVARCHAR(5)) + N' ' ELSE N' ' END + '
			ORDER BY ps.object_id,  ps.index_id, ps.partition_number
			OPTION	( RECOMPILE );
			';
		END
		ELSE /* Otherwise use this syntax which takes advantage of OUTER APPLY on the os_partitions DMV. 
		This performs better on 2012 tables using 1000+ partitions. */
		BEGIN
		RAISERROR (N'Using 2012 syntax to query sys.dm_db_index_operational_stats',0,1) WITH NOWAIT;

 		SET @dsql = N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
						SELECT	ps.object_id, 
								ps.index_id, 
								ps.partition_number, 
								ps.row_count,
								ps.reserved_page_count * 8. / 1024. AS reserved_MB,
								ps.lob_reserved_page_count * 8. / 1024. AS reserved_LOB_MB,
								ps.row_overflow_reserved_page_count * 8. / 1024. AS reserved_row_overflow_MB,
								os.leaf_insert_count, 
								os.leaf_delete_count, 
								os.leaf_update_count, 
								os.range_scan_count, 
								os.singleton_lookup_count,  
								os.forwarded_fetch_count,
								os.lob_fetch_in_pages, 
								os.lob_fetch_in_bytes, 
								os.row_overflow_fetch_in_pages,
								os.row_overflow_fetch_in_bytes, 
								os.row_lock_count, 
								os.row_lock_wait_count,
								os.row_lock_wait_in_ms, 
								os.page_lock_count, 
								os.page_lock_wait_count, 
								os.page_lock_wait_in_ms,
								os.index_lock_promotion_attempt_count, 
								os.index_lock_promotion_count, 
								' + case when @SQLServerProductVersion not like '9%' THEN N'par.data_compression_desc ' ELSE N'null as data_compression_desc' END + N'
						FROM	' + QUOTENAME(@DatabaseName) + N'.sys.dm_db_partition_stats AS ps  
						JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.partitions AS par on ps.partition_id=par.partition_id
						JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.objects AS so ON ps.object_id = so.object_id
								   AND so.is_ms_shipped = 0 /*Exclude objects shipped by Microsoft*/
								   AND so.type <> ''TF'' /*Exclude table valued functions*/
						OUTER APPLY ' + QUOTENAME(@DatabaseName) + N'.sys.dm_db_index_operational_stats('
					+ CAST(@DatabaseID AS NVARCHAR(10)) + N', ps.object_id, ps.index_id,ps.partition_number) AS os
						WHERE 1=1 
						' + CASE WHEN @ObjectID IS NOT NULL THEN N'AND so.object_id=' + CAST(@ObjectID AS NVARCHAR(30)) + N' ' ELSE N' ' END + N'
						' + CASE WHEN @Filter = 2 THEN N'AND ps.reserved_page_count * 8./1024. > ' + CAST(@FilterMB AS NVARCHAR(5)) + N' ' ELSE N' ' END + '
				ORDER BY ps.object_id,  ps.index_id, ps.partition_number
				OPTION	( RECOMPILE );
				';
 
		END       

		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);

		RAISERROR (N'Inserting data into #IndexPartitionSanity',0,1) WITH NOWAIT;
		insert	#IndexPartitionSanity ( 
											[object_id], 
											index_id, 
											partition_number, 
											row_count, 
											reserved_MB,
										  reserved_LOB_MB, 
										  reserved_row_overflow_MB, 
										  leaf_insert_count,
										  leaf_delete_count, 
										  leaf_update_count, 
										  range_scan_count,
										  singleton_lookup_count,
										  forwarded_fetch_count, 
										  lob_fetch_in_pages, 
										  lob_fetch_in_bytes, 
										  row_overflow_fetch_in_pages,
										  row_overflow_fetch_in_bytes, 
										  row_lock_count, 
										  row_lock_wait_count,
										  row_lock_wait_in_ms, 
										  page_lock_count, 
										  page_lock_wait_count,
										  page_lock_wait_in_ms, 
										  index_lock_promotion_attempt_count,
										  index_lock_promotion_count, 
										  data_compression_desc )
				EXEC sp_executesql @dsql;


		RAISERROR (N'Updating index_sanity_id on #IndexPartitionSanity',0,1) WITH NOWAIT;
		UPDATE	#IndexPartitionSanity
		SET		index_sanity_id = i.index_sanity_id
		FROM #IndexPartitionSanity ps
				JOIN #IndexSanity i ON ps.[object_id] = i.[object_id]
										AND ps.index_id = i.index_id


		RAISERROR (N'Inserting data into #IndexSanitySize',0,1) WITH NOWAIT;
		INSERT	#IndexSanitySize ( [index_sanity_id], partition_count, total_rows, total_reserved_MB,
									 total_reserved_LOB_MB, total_reserved_row_overflow_MB, total_range_scan_count,
									 total_singleton_lookup_count, total_leaf_delete_count, total_leaf_update_count, 
									 total_forwarded_fetch_count,total_row_lock_count,
									 total_row_lock_wait_count, total_row_lock_wait_in_ms, avg_row_lock_wait_in_ms,
									 total_page_lock_count, total_page_lock_wait_count, total_page_lock_wait_in_ms,
									 avg_page_lock_wait_in_ms, total_index_lock_promotion_attempt_count, 
									 total_index_lock_promotion_count, data_compression_desc )
				SELECT	index_sanity_id, COUNT(*), SUM(row_count), SUM(reserved_MB), SUM(reserved_LOB_MB),
						SUM(reserved_row_overflow_MB), 
						SUM(range_scan_count),
						SUM(singleton_lookup_count),
						SUM(leaf_delete_count), 
						SUM(leaf_update_count),
						SUM(forwarded_fetch_count),
						SUM(row_lock_count), 
						SUM(row_lock_wait_count),
						SUM(row_lock_wait_in_ms), 
						CASE WHEN SUM(row_lock_wait_in_ms) > 0 THEN
							SUM(row_lock_wait_in_ms)/(1.*SUM(row_lock_wait_count))
						ELSE 0 END AS avg_row_lock_wait_in_ms,           
						SUM(page_lock_count), 
						SUM(page_lock_wait_count),
						SUM(page_lock_wait_in_ms), 
						CASE WHEN SUM(page_lock_wait_in_ms) > 0 THEN
							SUM(page_lock_wait_in_ms)/(1.*SUM(page_lock_wait_count))
						ELSE 0 END AS avg_page_lock_wait_in_ms,           
						SUM(index_lock_promotion_attempt_count),
						SUM(index_lock_promotion_count),
						LEFT(MAX(data_compression_info.data_compression_rollup),8000)
				FROM #IndexPartitionSanity ipp
				/* individual partitions can have distinct compression settings, just roll them into a list here*/
				OUTER APPLY (SELECT STUFF((
					SELECT	N', ' + data_compression_desc
					FROM #IndexPartitionSanity ipp2
					WHERE ipp.[object_id]=ipp2.[object_id]
						AND ipp.[index_id]=ipp2.[index_id]
					ORDER BY ipp2.partition_number
					FOR	  XML PATH(''),TYPE).value('.', 'varchar(max)'), 1, 1, '')) 
						data_compression_info(data_compression_rollup)
				GROUP BY index_sanity_id
				ORDER BY index_sanity_id 
		OPTION	( RECOMPILE );

		RAISERROR (N'Adding UQ index on #IndexSanity (object_id,index_id)',0,1) WITH NOWAIT;
		CREATE UNIQUE INDEX uq_object_id_index_id ON #IndexSanity (object_id,index_id);

		RAISERROR (N'Inserting data into #MissingIndexes',0,1) WITH NOWAIT;
		SET @dsql=N'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
				SELECT	id.object_id, ' + QUOTENAME(@DatabaseName,'''') + N', sc.[name], so.[name], id.statement , gs.avg_total_user_cost, 
						gs.avg_user_impact, gs.user_seeks, gs.user_scans, gs.unique_compiles,id.equality_columns, 
						id.inequality_columns,id.included_columns
				FROM	sys.dm_db_missing_index_groups ig
						JOIN sys.dm_db_missing_index_details id ON ig.index_handle = id.index_handle
						JOIN sys.dm_db_missing_index_group_stats gs ON ig.index_group_handle = gs.group_handle
						JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.objects so on 
							id.object_id=so.object_id
						JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.schemas sc on 
							so.schema_id=sc.schema_id
				WHERE	id.database_id = ' + CAST(@DatabaseID AS NVARCHAR(30)) + '
				' + CASE WHEN @ObjectID IS NULL THEN N'' 
					ELSE N'and id.object_id=' + CAST(@ObjectID AS NVARCHAR(30)) 
				END +
		N';'

		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);
		INSERT	#MissingIndexes ( [object_id], [database_name], [schema_name], [table_name], [statement], avg_total_user_cost, 
									avg_user_impact, user_seeks, user_scans, unique_compiles, equality_columns, 
									inequality_columns,included_columns)
		EXEC sp_executesql @dsql;

		SET @dsql = N'
			SELECT 
				fk_object.name AS foreign_key_name,
				parent_object.[object_id] AS parent_object_id,
				parent_object.name AS parent_object_name,
				referenced_object.[object_id] AS referenced_object_id,
				referenced_object.name AS referenced_object_name,
				fk.is_disabled,
				fk.is_not_trusted,
				fk.is_not_for_replication,
				parent.fk_columns,
				referenced.fk_columns,
				[update_referential_action_desc],
				[delete_referential_action_desc]
			FROM ' + QUOTENAME(@DatabaseName) + N'.sys.foreign_keys fk
			JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.objects fk_object ON fk.object_id=fk_object.object_id
			JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.objects parent_object ON fk.parent_object_id=parent_object.object_id
			JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.objects referenced_object ON fk.referenced_object_id=referenced_object.object_id
			CROSS APPLY ( SELECT	STUFF( (SELECT	N'', '' + c_parent.name AS fk_columns
											FROM	' + QUOTENAME(@DatabaseName) + N'.sys.foreign_key_columns fkc 
											JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.columns c_parent ON fkc.parent_object_id=c_parent.[object_id]
												AND fkc.parent_column_id=c_parent.column_id
											WHERE	fk.parent_object_id=fkc.parent_object_id
												AND fk.[object_id]=fkc.constraint_object_id
											ORDER BY fkc.constraint_column_id 
									FOR	  XML PATH('''') ,
											  TYPE).value(''.'', ''varchar(max)''), 1, 1, '''')/*This is how we remove the first comma*/ ) parent ( fk_columns )
			CROSS APPLY ( SELECT	STUFF( (SELECT	N'', '' + c_referenced.name AS fk_columns
											FROM	' + QUOTENAME(@DatabaseName) + N'.sys.	foreign_key_columns fkc 
											JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.columns c_referenced ON fkc.referenced_object_id=c_referenced.[object_id]
												AND fkc.referenced_column_id=c_referenced.column_id
											WHERE	fk.referenced_object_id=fkc.referenced_object_id
												and fk.[object_id]=fkc.constraint_object_id
											ORDER BY fkc.constraint_column_id  /*order by col name, we don''t have anything better*/
									FOR	  XML PATH('''') ,
											  TYPE).value(''.'', ''varchar(max)''), 1, 1, '''') ) referenced ( fk_columns )
			' + CASE WHEN @ObjectID IS NOT NULL THEN 
					'WHERE fk.parent_object_id=' + CAST(@ObjectID AS NVARCHAR(30)) + N' OR fk.referenced_object_id=' + CAST(@ObjectID AS NVARCHAR(30)) + N' ' 
					ELSE N' ' END + '
			ORDER BY parent_object_name, foreign_key_name;
		';
		IF @dsql IS NULL 
			RAISERROR('@dsql is null',16,1);

        RAISERROR (N'Inserting data into #ForeignKeys',0,1) WITH NOWAIT;
        INSERT  #ForeignKeys ( foreign_key_name, parent_object_id,parent_object_name, referenced_object_id, referenced_object_name,
                                is_disabled, is_not_trusted, is_not_for_replication, parent_fk_columns, referenced_fk_columns,
								[update_referential_action_desc], [delete_referential_action_desc] )
                EXEC sp_executesql @dsql;

        RAISERROR (N'Updating #IndexSanity.referenced_by_foreign_key',0,1) WITH NOWAIT;
		UPDATE #IndexSanity
			SET is_referenced_by_foreign_key=1
		FROM #IndexSanity s
		JOIN #ForeignKeys fk ON 
			s.object_id=fk.referenced_object_id
			AND LEFT(s.key_column_names,LEN(fk.referenced_fk_columns)) = fk.referenced_fk_columns

		RAISERROR (N'Add computed columns to #IndexSanity to simplify queries.',0,1) WITH NOWAIT;
		ALTER TABLE #IndexSanity ADD 
		[schema_object_name] AS [schema_name] + '.' + [object_name]  ,
		[schema_object_indexid] AS [schema_name] + '.' + [object_name]
			+ CASE WHEN [index_name] IS NOT NULL THEN '.' + index_name
			ELSE ''
			END + ' (' + CAST(index_id AS NVARCHAR(20)) + ')' ,
		first_key_column_name AS CASE	WHEN count_key_columns > 1
			THEN LEFT(key_column_names, CHARINDEX(',', key_column_names, 0) - 1)
			ELSE key_column_names
			END ,
		index_definition AS 
		CASE WHEN partition_key_column_name IS NOT NULL 
			THEN N'[PARTITIONED BY:' + partition_key_column_name +  N']' 
			ELSE '' 
			END +
			CASE index_id
				WHEN 0 THEN N'[HEAP] '
				WHEN 1 THEN N'[CX] '
				ELSE N'' END + CASE WHEN is_indexed_view = 1 THEN '[VIEW] '
				ELSE N'' END + CASE WHEN is_primary_key = 1 THEN N'[PK] '
				ELSE N'' END + CASE WHEN is_XML = 1 THEN N'[XML] '
				ELSE N'' END + CASE WHEN is_spatial = 1 THEN N'[SPATIAL] '
				ELSE N'' END + CASE WHEN is_NC_columnstore = 1 THEN N'[COLUMNSTORE] '
				ELSE N'' END + CASE WHEN is_disabled = 1 THEN N'[DISABLED] '
				ELSE N'' END + CASE WHEN is_hypothetical = 1 THEN N'[HYPOTHETICAL] '
				ELSE N'' END + CASE WHEN is_unique = 1 AND is_primary_key = 0 THEN N'[UNIQUE] '
				ELSE N'' END + CASE WHEN count_key_columns > 0 THEN 
					N'[' + CAST(count_key_columns AS VARCHAR(10)) + N' KEY' 
						+ CASE WHEN count_key_columns > 1 then  N'S' ELSE N'' END
						+ N'] ' + LTRIM(key_column_names_with_sort_order)
				ELSE N'' END + CASE WHEN count_included_columns > 0 THEN 
					N' [' + CAST(count_included_columns AS VARCHAR(10))  + N' INCLUDE' + 
						+ CASE WHEN count_included_columns > 1 then  N'S' ELSE N'' END					
						+ N'] ' + include_column_names
				ELSE N'' END + CASE WHEN filter_definition <> N'' THEN N' [FILTER] ' + filter_definition
				ELSE N'' END ,
		[total_reads] AS user_seeks + user_scans + user_lookups,
		[reads_per_write] AS CAST(CASE WHEN user_updates > 0
			THEN ( user_seeks + user_scans + user_lookups )  / (1.0 * user_updates)
			ELSE 0 END AS MONEY) ,
		[index_usage_summary] AS N'Reads: ' + 
			REPLACE(CONVERT(NVARCHAR(30),CAST((user_seeks + user_scans + user_lookups) AS money), 1), '.00', '')
			+ case when user_seeks + user_scans + user_lookups > 0 then
				N' (' 
					+ RTRIM(
					CASE WHEN user_seeks > 0 then REPLACE(CONVERT(NVARCHAR(30),CAST((user_seeks) AS money), 1), '.00', '') + N' seek ' ELSE N'' END
					+ CASE WHEN user_scans > 0 then REPLACE(CONVERT(NVARCHAR(30),CAST((user_scans) AS money), 1), '.00', '') + N' scan '  ELSE N'' END
					+ CASE WHEN user_lookups > 0 then  REPLACE(CONVERT(NVARCHAR(30),CAST((user_lookups) AS money), 1), '.00', '') + N' lookup' ELSE N'' END
					)
					+ N') '
				else N' ' end 
			+ N'Writes:' + 
			REPLACE(CONVERT(NVARCHAR(30),CAST(user_updates AS money), 1), '.00', ''),
		[more_info] AS N'EXEC dbo.sp_BlitzIndex @DatabaseName=' + QUOTENAME([database_name],'''') + 
			N', @SchemaName=' + QUOTENAME([schema_name],'''') + N', @TableName=' + QUOTENAME([object_name],'''') + N';'

		RAISERROR (N'Update index_secret on #IndexSanity for NC indexes.',0,1) WITH NOWAIT;
		UPDATE nc 
		SET secret_columns=
			N'[' + 
			CASE tb.count_key_columns WHEN 0 THEN '1' ELSE CAST(tb.count_key_columns AS VARCHAR(10)) END +
			CASE nc.is_unique WHEN 1 THEN N' INCLUDE' ELSE N' KEY' END +
			CASE WHEN tb.count_key_columns > 1 then  N'S] ' ELSE N'] ' END +
			CASE tb.index_id WHEN 0 THEN '[RID]' ELSE LTRIM(tb.key_column_names) +
				/* Uniquifiers only needed on non-unique clustereds-- not heaps */
				CASE tb.is_unique WHEN 0 THEN ' [UNIQUIFIER]' ELSE N'' END
			END
			, count_secret_columns=
			CASE tb.index_id WHEN 0 THEN 1 ELSE 
				tb.count_key_columns +
					CASE tb.is_unique WHEN 0 THEN 1 ELSE 0 END
			END
		FROM #IndexSanity AS nc
		JOIN #IndexSanity AS tb ON nc.object_id=tb.object_id
			and tb.index_id in (0,1) 
		WHERE nc.index_id > 1;

		RAISERROR (N'Update index_secret on #IndexSanity for heaps and non-unique clustered.',0,1) WITH NOWAIT;
		UPDATE tb
		SET secret_columns=	CASE tb.index_id WHEN 0 THEN '[RID]' ELSE '[UNIQUIFIER]' END
			, count_secret_columns = 1
		FROM #IndexSanity AS tb
		WHERE tb.index_id = 0 /*Heaps-- these have the RID */
			or (tb.index_id=1 and tb.is_unique=0); /* Non-unique CX: has uniquifer (when needed) */

		RAISERROR (N'Add computed columns to #IndexSanitySize to simplify queries.',0,1) WITH NOWAIT;
		ALTER TABLE #IndexSanitySize ADD 
			  index_size_summary AS ISNULL(
				CASE WHEN partition_count > 1
						THEN N'[' + CAST(partition_count AS NVARCHAR(10)) + N' PARTITIONS] '
						ELSE N''
				END + REPLACE(CONVERT(NVARCHAR(30),CAST([total_rows] AS money), 1), N'.00', N'') + N' rows; '
				+ CASE WHEN total_reserved_MB > 1024 THEN 
					CAST(CAST(total_reserved_MB/1024. AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'GB'
				ELSE 
					CAST(CAST(total_reserved_MB AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'MB'
				END
				+ CASE WHEN total_reserved_LOB_MB > 1024 THEN 
					N'; ' + CAST(CAST(total_reserved_LOB_MB/1024. AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'GB LOB'
				WHEN total_reserved_LOB_MB > 0 THEN
					N'; ' + CAST(CAST(total_reserved_LOB_MB AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'MB LOB'
				ELSE ''
				END
				 + CASE WHEN total_reserved_row_overflow_MB > 1024 THEN
					N'; ' + CAST(CAST(total_reserved_row_overflow_MB/1024. AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'GB Row Overflow'
				WHEN total_reserved_row_overflow_MB > 0 THEN
					N'; ' + CAST(CAST(total_reserved_row_overflow_MB AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'MB Row Overflow'
				ELSE ''
				END ,
					N'Error- NULL in computed column'),
			index_op_stats AS ISNULL(
				(
					REPLACE(CONVERT(NVARCHAR(30),CAST(total_singleton_lookup_count AS MONEY), 1),N'.00',N'') + N' singleton lookups; '
					+ REPLACE(CONVERT(NVARCHAR(30),CAST(total_range_scan_count AS MONEY), 1),N'.00',N'') + N' scans/seeks; '
					+ REPLACE(CONVERT(NVARCHAR(30),CAST(total_leaf_delete_count AS MONEY), 1),N'.00',N'') + N' deletes; '
					+ REPLACE(CONVERT(NVARCHAR(30),CAST(total_leaf_update_count AS MONEY), 1),N'.00',N'') + N' updates; '
					+ CASE WHEN ISNULL(total_forwarded_fetch_count,0) >0 THEN
						REPLACE(CONVERT(NVARCHAR(30),CAST(total_forwarded_fetch_count AS MONEY), 1),N'.00',N'') + N' forward records fetched; '
					ELSE N'' END

					/* rows will only be in this dmv when data is in memory for the table */
				), N'Table metadata not in memory'),
			index_lock_wait_summary AS ISNULL(
				CASE WHEN total_row_lock_wait_count = 0 and  total_page_lock_wait_count = 0 and
					total_index_lock_promotion_attempt_count = 0 THEN N'0 lock waits.'
				ELSE
					CASE WHEN total_row_lock_wait_count > 0 THEN
						N'Row lock waits: ' + REPLACE(CONVERT(NVARCHAR(30),CAST(total_row_lock_wait_count AS money), 1), N'.00', N'')
						+ N'; total duration: ' + 
							CASE WHEN total_row_lock_wait_in_ms >= 60000 THEN /*More than 1 min*/
								REPLACE(CONVERT(NVARCHAR(30),CAST((total_row_lock_wait_in_ms/60000) AS money), 1), N'.00', N'') + N' minutes; '
							ELSE                         
								REPLACE(CONVERT(NVARCHAR(30),CAST(ISNULL(total_row_lock_wait_in_ms/1000,0) AS money), 1), N'.00', N'') + N' seconds; '
							END
						+ N'avg duration: ' + 
							CASE WHEN avg_row_lock_wait_in_ms >= 60000 THEN /*More than 1 min*/
								REPLACE(CONVERT(NVARCHAR(30),CAST((avg_row_lock_wait_in_ms/60000) AS money), 1), N'.00', N'') + N' minutes; '
							ELSE                         
								REPLACE(CONVERT(NVARCHAR(30),CAST(ISNULL(avg_row_lock_wait_in_ms/1000,0) AS money), 1), N'.00', N'') + N' seconds; '
							END
					ELSE N''
					END +
					CASE WHEN total_page_lock_wait_count > 0 THEN
						N'Page lock waits: ' + REPLACE(CONVERT(NVARCHAR(30),CAST(total_page_lock_wait_count AS money), 1), N'.00', N'')
						+ N'; total duration: ' + 
							CASE WHEN total_page_lock_wait_in_ms >= 60000 THEN /*More than 1 min*/
								REPLACE(CONVERT(NVARCHAR(30),CAST((total_page_lock_wait_in_ms/60000) AS money), 1), N'.00', N'') + N' minutes; '
							ELSE                         
								REPLACE(CONVERT(NVARCHAR(30),CAST(ISNULL(total_page_lock_wait_in_ms/1000,0) AS money), 1), N'.00', N'') + N' seconds; '
							END
						+ N'avg duration: ' + 
							CASE WHEN avg_page_lock_wait_in_ms >= 60000 THEN /*More than 1 min*/
								REPLACE(CONVERT(NVARCHAR(30),CAST((avg_page_lock_wait_in_ms/60000) AS money), 1), N'.00', N'') + N' minutes; '
							ELSE                         
								REPLACE(CONVERT(NVARCHAR(30),CAST(ISNULL(avg_page_lock_wait_in_ms/1000,0) AS money), 1), N'.00', N'') + N' seconds; '
							END
					ELSE N''
					END +
					CASE WHEN total_index_lock_promotion_attempt_count > 0 THEN
						N'Lock escalation attempts: ' + REPLACE(CONVERT(NVARCHAR(30),CAST(total_index_lock_promotion_attempt_count AS money), 1), N'.00', N'')
						+ N'; Actual Escalations: ' + REPLACE(CONVERT(NVARCHAR(30),CAST(ISNULL(total_index_lock_promotion_count,0) AS money), 1), N'.00', N'') + N'.'
					ELSE N''
					END
				END                  
					,'Error- NULL in computed column')


		RAISERROR (N'Add computed columns to #missing_index to simplify queries.',0,1) WITH NOWAIT;
		ALTER TABLE #MissingIndexes ADD 
				[index_estimated_impact] AS 
					CAST(user_seeks + user_scans AS NVARCHAR(30)) + N' use' 
						+ CASE WHEN (user_seeks + user_scans) > 1 THEN N's' ELSE N'' END
						 +N'; Impact: ' + CAST(avg_user_impact AS NVARCHAR(30))
						+ N'%; Avg query cost: '
						+ CAST(avg_total_user_cost AS NVARCHAR(30)),
				[missing_index_details] AS
					CASE WHEN equality_columns IS NOT NULL THEN N'EQUALITY: ' + equality_columns + N' '
						 ELSE N''
					END + CASE WHEN inequality_columns IS NOT NULL THEN N'INEQUALITY: ' + inequality_columns + N' '
					   ELSE N''
					END + CASE WHEN included_columns IS NOT NULL THEN N'INCLUDES: ' + included_columns + N' '
						ELSE N''
					END,
				[create_tsql] AS N'CREATE INDEX [ix_' + table_name + N'_' 
					+ REPLACE(REPLACE(REPLACE(REPLACE(
						ISNULL(equality_columns,N'')+ 
						CASE when equality_columns is not null and inequality_columns is not null then N'_' else N'' END
						+ ISNULL(inequality_columns,''),',','')
						,'[',''),']',''),' ','_') 
					+ CASE WHEN included_columns IS NOT NULL THEN N'_includes' ELSE N'' END + N'] ON ' 
					+ [statement] + N' (' + ISNULL(equality_columns,N'')
					+ CASE WHEN equality_columns IS NOT NULL AND inequality_columns IS NOT NULL THEN N', ' ELSE N'' END
					+ CASE WHEN inequality_columns IS NOT NULL THEN inequality_columns ELSE N'' END + 
					') ' + CASE WHEN included_columns IS NOT NULL THEN N' INCLUDE (' + included_columns + N')' ELSE N'' END
					+ N' WITH (' 
						+ N'FILLFACTOR=100, ONLINE=?, SORT_IN_TEMPDB=?' 
					+ N')'
					+ N';'
					,
				[more_info] AS N'EXEC dbo.sp_BlitzIndex @DatabaseName=' + QUOTENAME([database_name],'''') + 
					N', @SchemaName=' + QUOTENAME([schema_name],'''') + N', @TableName=' + QUOTENAME([table_name],'''') + N';'
				;


		RAISERROR (N'Populate #IndexCreateTsql.',0,1) WITH NOWAIT;
		INSERT #IndexCreateTsql (index_sanity_id, create_tsql)
		SELECT
			index_sanity_id,
			ISNULL (
			/* Script drops for disabled non-clustered indexes*/
			CASE WHEN is_disabled = 1 AND index_id <> 1
				THEN N'--DROP INDEX ' + QUOTENAME([index_name]) + N' ON '
				 + QUOTENAME([schema_name]) + N'.' + QUOTENAME([object_name]) 
			ELSE
				CASE index_id WHEN 0 THEN N'--I''m a Heap!' 
				ELSE 
					CASE WHEN is_XML = 1 OR is_spatial=1 THEN N'' /* Not even trying for these just yet...*/
					ELSE 
						CASE WHEN is_primary_key=1 THEN
							N'ALTER TABLE ' + QUOTENAME([schema_name]) +
								N'.' + QUOTENAME([object_name]) + 
								N' ADD CONSTRAINT [' +
								index_name + 
								N'] PRIMARY KEY ' + 
								CASE WHEN index_id=1 THEN N'CLUSTERED (' ELSE N'(' END +
								key_column_names_with_sort_order_no_types + N' )' 
							WHEN is_CX_columnstore= 1 THEN
								 N'CREATE CLUSTERED COLUMNSTORE INDEX ' + QUOTENAME(index_name) + N' on ' + QUOTENAME([schema_name]) + '.' + QUOTENAME([object_name])
						ELSE /*Else not a PK or cx columnstore */ 
							N'CREATE ' + 
							CASE WHEN is_unique=1 THEN N'UNIQUE ' ELSE N'' END +
							CASE WHEN index_id=1 THEN N'CLUSTERED ' ELSE N'' END +
							CASE WHEN is_NC_columnstore=1 THEN N'NONCLUSTERED COLUMNSTORE ' 
							ELSE N'' END +
							N'INDEX ['
								 + index_name + N'] ON ' + 
								QUOTENAME([schema_name]) + '.' + QUOTENAME([object_name]) + 
									CASE WHEN is_NC_columnstore=1 THEN 
										N' (' + ISNULL(include_column_names_no_types,'') +  N' )' 
									ELSE /*Else not colunnstore */ 
										N' (' + ISNULL(key_column_names_with_sort_order_no_types,'') +  N' )' 
										+ CASE WHEN include_column_names_no_types IS NOT NULL THEN 
											N' INCLUDE (' + include_column_names_no_types + N')' 
											ELSE N'' 
										END
									END /*End non-colunnstore case */ 
								+ CASE WHEN filter_definition <> N'' THEN N' WHERE ' + filter_definition ELSE N'' END
							END /*End Non-PK index CASE */ 
						+ CASE WHEN is_NC_columnstore=0 and is_CX_columnstore=0 then
							N' WITH (' 
								+ N'FILLFACTOR=' + CASE fill_factor when 0 then N'100' else CAST(fill_factor AS NVARCHAR(5)) END + ', '
								+ N'ONLINE=?, SORT_IN_TEMPDB=?'
							+ N')'
						else N'' end
						+ N';'
  					END /*End non-spatial and non-xml CASE */ 
				END
			END, '[Unknown Error]')
				AS create_tsql
		FROM #IndexSanity;
					
	END
END TRY
BEGIN CATCH
		RAISERROR (N'Failure populating temp tables.', 0,1) WITH NOWAIT;

		IF @dsql IS NOT NULL
		BEGIN
			SET @msg= 'Last @dsql: ' + @dsql;
			RAISERROR(@msg, 0, 1) WITH NOWAIT;
		END

		SELECT	@msg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		RAISERROR (@msg,@ErrorSeverity, @ErrorState )WITH NOWAIT;
		
		
		WHILE @@trancount > 0 
			ROLLBACK;

		RETURN;
END CATCH;

----------------------------------------
--STEP 2: DIAGNOSE THE PATIENT
--EVERY QUERY AFTER THIS GOES AGAINST TEMP TABLES ONLY.
----------------------------------------
BEGIN TRY
----------------------------------------
--If @TableName is specified, just return information for that table.
--The @Mode parameter doesn't matter if you're looking at a specific table.
----------------------------------------
IF @TableName IS NOT NULL
BEGIN
	RAISERROR(N'@TableName specified, giving detail only on that table.', 0,1) WITH NOWAIT;

	--We do a left join here in case this is a disabled NC.
	--In that case, it won't have any size info/pages allocated.
	WITH table_mode_cte AS (
		SELECT 
			s.schema_object_indexid, 
			s.key_column_names,
			s.index_definition, 
			ISNULL(s.secret_columns,N'') AS secret_columns,
			s.fill_factor,
			s.index_usage_summary, 
			sz.index_op_stats,
			ISNULL(sz.index_size_summary,'') /*disabled NCs will be null*/ AS index_size_summary,
			ISNULL(sz.index_lock_wait_summary,'') AS index_lock_wait_summary,
			s.is_referenced_by_foreign_key,
			(SELECT COUNT(*)
				FROM #ForeignKeys fk WHERE fk.parent_object_id=s.object_id
				AND PATINDEX (fk.parent_fk_columns, s.key_column_names)=1) AS FKs_covered_by_index,
			s.last_user_seek,
			s.last_user_scan,
			s.last_user_lookup,
			s.last_user_update,
			s.create_date,
			s.modify_date,
			ct.create_tsql,
			1 as display_order
		FROM #IndexSanity s
		LEFT JOIN #IndexSanitySize sz ON 
			s.index_sanity_id=sz.index_sanity_id
		LEFT JOIN #IndexCreateTsql ct ON 
			s.index_sanity_id=ct.index_sanity_id
		WHERE s.[object_id]=@ObjectID
		UNION ALL
		SELECT 	N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121) + 			
				N' (sp_BlitzIndex(TM) v2.02 - Jan 30, 2014)' ,   
				N'From Brent Ozar Unlimited(TM)' ,   
				N'http://BrentOzar.com/BlitzIndex' ,
				N'Thanks from the Brent Ozar Unlimited(TM) team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.',
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				0 as display_order
	)
	SELECT 
			schema_object_indexid AS [Details: schema.table.index(indexid)], 
			index_definition AS [Definition: [Property]] ColumnName {datatype maxbytes}], 
			secret_columns AS [Secret Columns],
			fill_factor AS [Fillfactor],
			index_usage_summary AS [Usage Stats], 
			index_op_stats as [Op Stats],
			index_size_summary AS [Size],
			index_lock_wait_summary AS [Lock Waits],
			is_referenced_by_foreign_key AS [Referenced by FK?],
			FKs_covered_by_index AS [FK Covered by Index?],
			last_user_seek AS [Last User Seek],
			last_user_scan AS [Last User Scan],
			last_user_lookup AS [Last User Lookup],
			last_user_update as [Last User Write],
			create_date AS [Created],
			modify_date AS [Last Modified],
			create_tsql AS [Create TSQL]
	FROM table_mode_cte
	ORDER BY display_order ASC, key_column_names ASC
	OPTION	( RECOMPILE );						

	IF (SELECT TOP 1 [object_id] FROM    #MissingIndexes mi) IS NOT NULL
	BEGIN  
		SELECT  N'Missing index.' AS Finding ,
				N'http://BrentOzar.com/go/Indexaphobia' AS URL ,
				mi.[statement] + ' Est Benefit: '
					+ CASE WHEN magic_benefit_number >= 922337203685477 THEN '>= 922,337,203,685,477'
					ELSE REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(magic_benefit_number AS BIGINT) AS money), 1), '.00', '')
					END AS [Estimated Benefit],
				missing_index_details AS [Missing Index Request] ,
				index_estimated_impact AS [Estimated Impact],
				create_tsql AS [Create TSQL]
		FROM    #MissingIndexes mi
		WHERE   [object_id] = @ObjectID
		ORDER BY magic_benefit_number DESC
		OPTION	( RECOMPILE );
	END       
	ELSE     
	SELECT 'No missing indexes.' AS finding;

	SELECT 	
		column_name AS [Column Name],
		(SELECT COUNT(*)  
			FROM #IndexColumns c2 
			WHERE c2.column_name=c.column_name
			and c2.key_ordinal is not null)
		+ CASE WHEN c.index_id = 1 and c.key_ordinal is not null THEN
			-1+ (SELECT COUNT(DISTINCT index_id)
			from #IndexColumns c3
			where c3.index_id not in (0,1))
			ELSE 0 END
				AS [Found In],
		system_type_name + 
			CASE max_length WHEN -1 THEN N' (max)' ELSE
				CASE  
					WHEN system_type_name in (N'char',N'nchar',N'binary',N'varbinary') THEN N' (' + CAST(max_length as NVARCHAR(20)) + N')' 
					WHEN system_type_name in (N'varchar',N'nvarchar') THEN N' (' + CAST(max_length/2 as NVARCHAR(20)) + N')' 
					ELSE '' 
				END
			END
			AS [Type],
		CASE is_computed WHEN 1 THEN 'yes' ELSE '' END AS [Computed?],
		max_length AS [Length (max bytes)],
		[precision] AS [Prec],
		[scale] AS [Scale],
		CASE is_nullable WHEN 1 THEN 'yes' ELSE '' END AS [Nullable?],
		CASE is_identity WHEN 1 THEN 'yes' ELSE '' END AS [Identity?],
		CASE is_replicated WHEN 1 THEN 'yes' ELSE '' END AS [Replicated?],
		CASE is_sparse WHEN 1 THEN 'yes' ELSE '' END AS [Sparse?],
		CASE is_filestream WHEN 1 THEN 'yes' ELSE '' END AS [Filestream?],
		collation_name AS [Collation]
	FROM #IndexColumns AS c
	where index_id in (0,1);

	IF (SELECT TOP 1 parent_object_id FROM #ForeignKeys) IS NOT NULL
	BEGIN
		SELECT parent_object_name + N': ' + foreign_key_name AS [Foreign Key],
			parent_fk_columns AS [Foreign Key Columns],
			referenced_object_name AS [Referenced Table],
			referenced_fk_columns AS [Referenced Table Columns],
			is_disabled AS [Is Disabled?],
			is_not_trusted as [Not Trusted?],
			is_not_for_replication [Not for Replication?],
			[update_referential_action_desc] as [Cascading Updates?],
			[delete_referential_action_desc] as [Cascading Deletes?]
		FROM #ForeignKeys
		ORDER BY [Foreign Key]
		OPTION	( RECOMPILE );
	END
	ELSE
	SELECT 'No foreign keys.' AS finding;
END 

--If @TableName is NOT specified...
--Act based on the @Mode and @Filter. (@Filter applies only when @Mode=0 "diagnose")
ELSE
BEGIN;
	IF @Mode=0 /* DIAGNOSE*/
	BEGIN;
		RAISERROR(N'@Mode=0, we are diagnosing.', 0,1) WITH NOWAIT;

		RAISERROR(N'Insert a row to help people find help', 0,1) WITH NOWAIT;
		INSERT	#BlitzIndexResults ( check_id, findings_group, finding, URL, details, index_definition,
										index_usage_summary, index_size_summary )
		VALUES  ( 0 , 
				N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121), 
				N'sp_BlitzIndex(TM) v2.02 - Jan 30, 2014' ,
				N'From Brent Ozar Unlimited(TM)' ,   N'http://BrentOzar.com/BlitzIndex' ,
				N'Thanks from the Brent Ozar Unlimited(TM) team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'
				, N'',N''
				);

		----------------------------------------
		--Multiple Index Personalities: Check_id 0-10
		----------------------------------------
		BEGIN;
		RAISERROR('check_id 1: Duplicate keys', 0,1) WITH NOWAIT;
			WITH	duplicate_indexes
					  AS ( SELECT	[object_id], key_column_names
						   FROM		#IndexSanity
						   WHERE  index_type IN (1,2) /* Clustered, NC only*/
								AND is_hypothetical = 0
								AND is_disabled = 0
						   GROUP BY	[object_id], key_column_names
						   HAVING	COUNT(*) > 1)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	1 AS check_id, 
								ip.index_sanity_id,
								'Multiple Index Personalities' AS findings_group,
								'Duplicate keys' AS finding,
								N'http://BrentOzar.com/go/duplicateindex' AS URL,
								ip.schema_object_indexid AS details,
								ip.index_definition, 
								ip.secret_columns, 
								ip.index_usage_summary,
								ips.index_size_summary
						FROM	duplicate_indexes di
								JOIN #IndexSanity ip ON di.[object_id] = ip.[object_id]
														 AND ip.key_column_names = di.key_column_names
								JOIN #IndexSanitySize ips ON ip.index_sanity_id = ips.index_sanity_id
						ORDER BY ip.object_id, ip.key_column_names_with_sort_order	
				OPTION	( RECOMPILE );

		RAISERROR('check_id 2: Keys w/ identical leading columns.', 0,1) WITH NOWAIT;
			WITH	borderline_duplicate_indexes
					  AS ( SELECT DISTINCT [object_id], first_key_column_name, key_column_names,
									COUNT([object_id]) OVER ( PARTITION BY [object_id], first_key_column_name ) AS number_dupes
						   FROM		#IndexSanity
						   WHERE index_type IN (1,2) /* Clustered, NC only*/
							AND is_hypothetical=0
							AND is_disabled=0)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id,  findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	2 AS check_id, 
								ip.index_sanity_id,
								'Multiple Index Personalities' AS findings_group,
								'Borderline duplicate keys' AS finding,
								N'http://BrentOzar.com/go/duplicateindex' AS URL,
								ip.schema_object_indexid AS details, 
								ip.index_definition, 
								ip.secret_columns,
								ip.index_usage_summary,
								ips.index_size_summary
						FROM	#IndexSanity AS ip 
						JOIN #IndexSanitySize ips ON ip.index_sanity_id = ips.index_sanity_id
						WHERE EXISTS (
							SELECT di.[object_id]
							FROM borderline_duplicate_indexes AS di
							WHERE di.[object_id] = ip.[object_id] AND
								di.first_key_column_name = ip.first_key_column_name AND
								di.key_column_names <> ip.key_column_names AND
								di.number_dupes > 1	
						)
						ORDER BY ip.[schema_name], ip.[object_name], ip.key_column_names, ip.include_column_names
			OPTION	( RECOMPILE );

		END
		----------------------------------------
		--Aggressive Indexes: Check_id 10-19
		----------------------------------------
		BEGIN;

		RAISERROR(N'check_id 11: Total lock wait time > 5 minutes (row + page)', 0,1) WITH NOWAIT;
		INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										secret_columns, index_usage_summary, index_size_summary )
				SELECT	11 AS check_id, 
						i.index_sanity_id,
						N'Aggressive Indexes' AS findings_group,
						N'Total lock wait time > 5 minutes (row + page)' AS finding, 
						N'http://BrentOzar.com/go/AggressiveIndexes' AS URL,
						i.schema_object_indexid + N': ' +
							sz.index_lock_wait_summary AS details, 
						i.index_definition,
						i.secret_columns,
						i.index_usage_summary,
						sz.index_size_summary
				FROM	#IndexSanity AS i
				JOIN #IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
				WHERE	(total_row_lock_wait_in_ms + total_page_lock_wait_in_ms) > 300000
				OPTION	( RECOMPILE );
		END

		---------------------------------------- 
		--Index Hoarder: Check_id 20-29
		----------------------------------------
		BEGIN
			RAISERROR(N'check_id 20: >=7 NC indexes on any given table. Yes, 7 is an arbitrary number.', 0,1) WITH NOWAIT;
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	20 AS check_id, 
								MAX(i.index_sanity_id) AS index_sanity_id, 
								'Index Hoarder' AS findings_group,
								'Many NC indexes on a single table' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								CAST (COUNT(*) AS NVARCHAR(30)) + ' NC indexes on ' + i.schema_object_name AS details,
								i.schema_object_name + ' (' + CAST (COUNT(*) AS NVARCHAR(30)) + ' indexes)' AS index_definition,
								'' AS secret_columns,
								REPLACE(CONVERT(NVARCHAR(30),CAST(SUM(total_reads) AS money), 1), N'.00', N'') + N' reads (ALL); '
									+ REPLACE(CONVERT(NVARCHAR(30),CAST(SUM(user_updates) AS money), 1), N'.00', N'') + N' writes (ALL); ',
								REPLACE(CONVERT(NVARCHAR(30),CAST(MAX(total_rows) AS money), 1), N'.00', N'') + N' rows (MAX)'
									+ CASE WHEN SUM(total_reserved_MB) > 1024 THEN 
										N'; ' + CAST(CAST(SUM(total_reserved_MB)/1024. AS NUMERIC(29,1)) AS NVARCHAR(30)) + 'GB (ALL)'
									WHEN SUM(total_reserved_MB) > 0 THEN
										N'; ' + CAST(CAST(SUM(total_reserved_MB) AS NUMERIC(29,1)) AS NVARCHAR(30)) + 'MB (ALL)'
									ELSE ''
									END AS index_size_summary
						FROM	#IndexSanity i
						JOIN #IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						WHERE	index_id NOT IN ( 0, 1 )
						GROUP BY schema_object_name
						HAVING	COUNT(*) >= 7
						ORDER BY i.schema_object_name DESC  OPTION	( RECOMPILE );

			if @Filter = 1 /*@Filter=1 is "ignore unusued" */
			BEGIN
				RAISERROR(N'Skipping checks on unused indexes (21 and 22) because @Filter=1', 0,1) WITH NOWAIT;
			END
			ELSE /*Otherwise, go ahead and do the checks*/
			BEGIN
				RAISERROR(N'check_id 21: >=5 percent of indexes are unused. Yes, 5 is an arbitrary number.', 0,1) WITH NOWAIT;
					DECLARE @percent_NC_indexes_unused NUMERIC(29,1);
					DECLARE @NC_indexes_unused_reserved_MB NUMERIC(29,1);

					SELECT	@percent_NC_indexes_unused =( 100.00 * SUM(CASE	WHEN total_reads = 0 THEN 1
												ELSE 0
										   END) ) / COUNT(*) ,
							@NC_indexes_unused_reserved_MB = SUM(CASE WHEN total_reads = 0 THEN sz.total_reserved_MB
									 ELSE 0
								END) 
					FROM	#IndexSanity i
					JOIN	#IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE	index_id NOT IN ( 0, 1 ) 
							and i.is_unique = 0
					OPTION	( RECOMPILE );

				IF @percent_NC_indexes_unused >= 5 
					INSERT	#BlitzIndexResults ( check_id, index_sanity_id,  findings_group, finding, URL, details, index_definition,
												   secret_columns, index_usage_summary, index_size_summary )
							SELECT	21 AS check_id, 
									MAX(i.index_sanity_id) AS index_sanity_id, 
									N'Index Hoarder' AS findings_group,
									N'More than 5 percent NC indexes are unused' AS finding,
									N'http://BrentOzar.com/go/IndexHoarder' AS URL,
									CAST (@percent_NC_indexes_unused AS NVARCHAR(30)) + N' percent NC indexes (' + CAST(COUNT(*) AS NVARCHAR(10)) + N') unused. ' +
									N'These take up ' + CAST (@NC_indexes_unused_reserved_MB AS NVARCHAR(30)) + N'MB of space.' AS details,
									i.database_name + ' (' + CAST (COUNT(*) AS NVARCHAR(30)) + N' indexes)' AS index_definition,
									'' AS secret_columns, 
									CAST(SUM(total_reads) AS NVARCHAR(256)) + N' reads (ALL); '
										+ CAST(SUM([user_updates]) AS NVARCHAR(256)) + N' writes (ALL)' AS index_usage_summary,
								
									REPLACE(CONVERT(NVARCHAR(30),CAST(MAX([total_rows]) AS money), 1), '.00', '') + N' rows (MAX)'
										+ CASE WHEN SUM(total_reserved_MB) > 1024 THEN 
											N'; ' + CAST(CAST(SUM(total_reserved_MB)/1024. AS NUMERIC(29,1)) AS NVARCHAR(30)) + 'GB (ALL)'
										WHEN SUM(total_reserved_MB) > 0 THEN
											N'; ' + CAST(CAST(SUM(total_reserved_MB) AS NUMERIC(29,1)) AS NVARCHAR(30)) + 'MB (ALL)'
										ELSE ''
										END AS index_size_summary
							FROM	#IndexSanity i
							JOIN	#IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
							WHERE	index_id NOT IN ( 0, 1 )
									AND i.is_unique = 0
									AND total_reads = 0
							GROUP BY i.database_name 
					OPTION	( RECOMPILE );

				RAISERROR(N'check_id 22: NC indexes with 0 reads. (Borderline)', 0,1) WITH NOWAIT;
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	22 AS check_id, 
								i.index_sanity_id,
								N'Index Hoarder' AS findings_group,
								N'Unused NC index' AS finding, 
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								N'0 reads: ' + i.schema_object_indexid AS details, 
								i.index_definition, 
								i.secret_columns, 
								i.index_usage_summary,
								sz.index_size_summary
						FROM	#IndexSanity AS i
						JOIN	#IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
						WHERE	i.total_reads=0
								AND i.index_id NOT IN (0,1) /*NCs only*/
								and i.is_unique = 0
						ORDER BY i.schema_object_indexid
						OPTION	( RECOMPILE );
			END /*end checks only run when @Filter <> 1*/

			RAISERROR(N'check_id 23: Indexes with 7 or more columns. (Borderline)', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	23 AS check_id, 
							i.index_sanity_id, 
							N'Index Hoarder' AS findings_group,
							N'Borderline: Wide indexes (7 or more columns)' AS finding, 
							N'http://BrentOzar.com/go/IndexHoarder' AS URL,
							CAST(count_key_columns + count_included_columns AS NVARCHAR(10)) + ' columns on '
							+ i.schema_object_indexid AS details, i.index_definition, 
							i.secret_columns, 
							i.index_usage_summary,
							sz.index_size_summary
					FROM	#IndexSanity AS i
					JOIN	#IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE	( count_key_columns + count_included_columns ) >= 7
					OPTION	( RECOMPILE );

			RAISERROR(N'check_id 24: Wide clustered indexes (> 3 columns or > 16 bytes).', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								SUM(CASE max_length when -1 THEN 0 ELSE max_length END) AS sum_max_length
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
							and key_ordinal > 0
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	24 AS check_id, 
								i.index_sanity_id, 
								N'Index Hoarder' AS findings_group,
								N'Wide clustered index (> 3 columns OR > 16 bytes)' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								CAST (i.count_key_columns AS NVARCHAR(10)) + N' columns with potential size of '
									+ CAST(cc.sum_max_length AS NVARCHAR(10))
									+ N' bytes in clustered index:' + i.schema_object_name 
									+ N'. ' + 
										(SELECT CAST(COUNT(*) AS NVARCHAR(23)) FROM #IndexSanity i2 
										WHERE i2.[object_id]=i.[object_id] AND i2.index_id <> 1
										AND i2.is_disabled=0 AND i2.is_hypothetical=0)
										+ N' NC indexes on the table.'
									AS details,
								i.index_definition,
								secret_columns, 
								i.index_usage_summary,
								ip.index_size_summary
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]	
						WHERE	index_id = 1 /* clustered only */
								AND 
									(count_key_columns > 3 /*More than three key columns.*/
									OR cc.sum_max_length > 15 /*More than 16 bytes in key */)
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 25: Addicted to nullable columns.', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								SUM(CASE is_nullable WHEN 1 THEN 0 ELSE 1 END) as non_nullable_columns,
								COUNT(*) as total_columns
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	25 AS check_id, 
								i.index_sanity_id, 
								N'Index Hoarder' AS findings_group,
								N'Addicted to nulls' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								i.schema_object_name 
									+ N' allows null in ' + CAST((total_columns-non_nullable_columns) as NVARCHAR(10))
									+ N' of ' + CAST(total_columns as NVARCHAR(10))
									+ N' columns.' AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]
						WHERE	i.index_id in (1,0)
							AND cc.non_nullable_columns < 2
							and cc.total_columns > 3
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 26: Wide tables (35+ cols or > 2000 non-LOB bytes).', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								SUM(CASE max_length when -1 THEN 1 ELSE 0 END) AS count_lob_columns,
								SUM(CASE max_length when -1 THEN 0 ELSE max_length END) AS sum_max_length,
								COUNT(*) as total_columns
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	26 AS check_id, 
								i.index_sanity_id, 
								N'Index Hoarder' AS findings_group,
								N'Wide tables: 35+ cols or > 2000 non-LOB bytes' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								i.schema_object_name 
									+ N' has ' + CAST((total_columns) as NVARCHAR(10))
									+ N' total columns with a max possible width of ' + CAST(sum_max_length as NVARCHAR(10))
									+ N' bytes.' +
									CASE WHEN count_lob_columns > 0 THEN CAST((count_lob_columns) as NVARCHAR(10))
										+ ' columns are LOB types.' ELSE ''
									END
										AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]
						WHERE	i.index_id in (1,0)
							and 
							(cc.total_columns >= 35 OR
							cc.sum_max_length >= 2000)
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );
					
			RAISERROR(N'check_id 27: Addicted to strings.', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								SUM(CASE WHEN system_type_name in ('varchar','nvarchar','char') or max_length=-1 THEN 1 ELSE 0 END) as string_or_LOB_columns,
								COUNT(*) as total_columns
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	27 AS check_id, 
								i.index_sanity_id, 
								N'Index Hoarder' AS findings_group,
								N'Addicted to strings' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								i.schema_object_name 
									+ N' uses string or LOB types for ' + CAST((string_or_LOB_columns) as NVARCHAR(10))
									+ N' of ' + CAST(total_columns as NVARCHAR(10))
									+ N' columns. Check if data types are valid.' AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]
						CROSS APPLY (SELECT cc.total_columns - string_or_LOB_columns AS non_string_or_lob_columns) AS calc1
						WHERE	i.index_id in (1,0)
							AND calc1.non_string_or_lob_columns <= 1
							AND cc.total_columns > 3
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 28: Non-unique clustered index.', 0,1) WITH NOWAIT;
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	28 AS check_id, 
								i.index_sanity_id, 
								N'Index Hoarder' AS findings_group,
								N'Non-Unique clustered index' AS finding,
								N'http://BrentOzar.com/go/IndexHoarder' AS URL,
								N'Uniquifiers will be required! Clustered index: ' + i.schema_object_name 
									+ N' and all NC indexes. ' + 
										(SELECT CAST(COUNT(*) AS NVARCHAR(23)) FROM #IndexSanity i2 
										WHERE i2.[object_id]=i.[object_id] AND i2.index_id <> 1
										AND i2.is_disabled=0 AND i2.is_hypothetical=0)
										+ N' NC indexes on the table.'
									AS details,
								i.index_definition,
								secret_columns, 
								i.index_usage_summary,
								ip.index_size_summary
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						WHERE	index_id = 1 /* clustered only */
								AND is_unique=0 /* not unique */
								AND is_CX_columnstore=0 /* not a clustered columnstore-- no unique option on those */
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );


		END
		 ----------------------------------------
		--Feature-Phobic Indexes: Check_id 30-39
		---------------------------------------- 
		BEGIN
			RAISERROR(N'check_id 30: No indexes with includes', 0,1) WITH NOWAIT;

			DECLARE	@number_indexes_with_includes INT;
			DECLARE	@percent_indexes_with_includes NUMERIC(10, 1);

			SELECT	@number_indexes_with_includes = SUM(CASE WHEN count_included_columns > 0 THEN 1 ELSE 0	END),
					@percent_indexes_with_includes = 100.* 
						SUM(CASE WHEN count_included_columns > 0 THEN 1 ELSE 0 END) / ( 1.0 * COUNT(*) )
			FROM	#IndexSanity;

			IF @number_indexes_with_includes = 0 
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	30 AS check_id, 
								NULL AS index_sanity_id, 
								N'Feature-Phobic Indexes' AS findings_group,
								N'No indexes use includes' AS finding, 'http://BrentOzar.com/go/IndexFeatures' AS URL,
								N'No indexes use includes' AS details,
								N'Entire database' AS index_definition, 
								N'' AS secret_columns, 
								N'N/A' AS index_usage_summary, 
								N'N/A' AS index_size_summary OPTION	( RECOMPILE );

			RAISERROR(N'check_id 31: < 3 percent of indexes have includes', 0,1) WITH NOWAIT;
			IF @percent_indexes_with_includes <= 3 AND @number_indexes_with_includes > 0 
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	31 AS check_id,
								NULL AS index_sanity_id, 
								N'Feature-Phobic Indexes' AS findings_group,
								N'Borderline: Includes are used in < 3% of indexes' AS findings,
								N'http://BrentOzar.com/go/IndexFeatures' AS URL,
								N'Only ' + CAST(@percent_indexes_with_includes AS NVARCHAR(10)) + '% of indexes have includes' AS details, 
								N'Entire database' AS index_definition, 
								N'' AS secret_columns,
								N'N/A' AS index_usage_summary, 
								N'N/A' AS index_size_summary OPTION	( RECOMPILE );

			RAISERROR(N'check_id 32: filtered indexes and indexed views', 0,1) WITH NOWAIT;
			DECLARE @count_filtered_indexes INT;
			DECLARE @count_indexed_views INT;

				SELECT	@count_filtered_indexes=COUNT(*)
				FROM	#IndexSanity
				WHERE	filter_definition <> '' OPTION	( RECOMPILE );

				SELECT	@count_indexed_views=COUNT(*)
				FROM	#IndexSanity AS i
						JOIN #IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
				WHERE	is_indexed_view = 1 OPTION	( RECOMPILE );

			IF @count_filtered_indexes = 0 AND @count_indexed_views=0
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	32 AS check_id, 
								NULL AS index_sanity_id,
								N'Feature-Phobic Indexes' AS findings_group,
								N'Borderline: No filtered indexes or indexed views exist' AS finding, 
								N'http://BrentOzar.com/go/IndexFeatures' AS URL,
								N'These are NOT always needed-- but do you know when you would use them?' AS details,
								N'Entire database' AS index_definition, 
								N'' AS secret_columns,
								N'N/A' AS index_usage_summary, 
								N'N/A' AS index_size_summary OPTION	( RECOMPILE );
		END;

		RAISERROR(N'check_id 33: Potential filtered indexes based on column names.', 0,1) WITH NOWAIT;

		INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										secret_columns, index_usage_summary, index_size_summary )
		SELECT	33 AS check_id, 
				i.index_sanity_id AS index_sanity_id,
				N'Feature-Phobic Indexes' AS findings_group,
				N'Potential filtered index (based on column name)' AS finding, 
				N'http://BrentOzar.com/go/IndexFeatures' AS URL,
				N'A column name in this index suggests it might be a candidate for filtering (is%, %archive%, %active%, %flag%)' AS details,
				i.index_definition, 
				i.secret_columns,
				i.index_usage_summary, 
				sz.index_size_summary
		FROM #IndexColumns ic 
		join #IndexSanity i on 
			ic.[object_id]=i.[object_id] and
			ic.[index_id]=i.[index_id] and
			i.[index_id] > 1 /* non-clustered index */
		JOIN	#IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
		WHERE column_name like 'is%'
			or column_name like '%archive%'
			or column_name like '%active%'
			or column_name like '%flag%'
		OPTION	( RECOMPILE );

		 ----------------------------------------
		--Self Loathing Indexes : Check_id 40-49
		----------------------------------------
		BEGIN

			RAISERROR(N'check_id 40: Fillfactor in nonclustered 80 percent or less', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	40 AS check_id, 
							i.index_sanity_id,
							N'Self Loathing Indexes' AS findings_group,
							N'Low Fill Factor: nonclustered index' AS finding, 
							N'http://BrentOzar.com/go/SelfLoathing' AS URL,
							N'Fill factor on ' + schema_object_indexid + N' is ' + CAST(fill_factor AS NVARCHAR(10)) + N'%. '+
								CASE WHEN (last_user_update is null OR user_updates < 1)
								THEN N'No writes have been made.'
								ELSE
									N'Last write was ' +  CONVERT(NVARCHAR(16),last_user_update,121) + N' and ' + 
									CAST(user_updates as NVARCHAR(25)) + N' updates have been made.'
								END
								AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							sz.index_size_summary
					FROM	#IndexSanity AS i
					JOIN	#IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE	index_id > 1
					and	fill_factor BETWEEN 1 AND 80 OPTION	( RECOMPILE );

			RAISERROR(N'check_id 40: Fillfactor in clustered 90 percent or less', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	40 AS check_id, 
							i.index_sanity_id,
							N'Self Loathing Indexes' AS findings_group,
							N'Low Fill Factor: clustered index' AS finding, 
							N'http://BrentOzar.com/go/SelfLoathing' AS URL,
							N'Fill factor on ' + schema_object_indexid + N' is ' + CAST(fill_factor AS NVARCHAR(10)) + N'%. '+
								CASE WHEN (last_user_update is null OR user_updates < 1)
								THEN N'No writes have been made.'
								ELSE
									N'Last write was ' +  CONVERT(NVARCHAR(16),last_user_update,121) + N' and ' + 
									CAST(user_updates as NVARCHAR(25)) + N' updates have been made.'
								END
								AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							sz.index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE	index_id = 1
					and fill_factor BETWEEN 1 AND 90 OPTION	( RECOMPILE );


			RAISERROR(N'check_id 41: Hypothetical indexes ', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	41 AS check_id, 
							N'Self Loathing Indexes' AS findings_group,
							N'Hypothetical Index' AS finding, 'http://BrentOzar.com/go/SelfLoathing' AS URL,
							N'Hypothetical Index: ' + schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							N'' AS index_usage_summary, 
							N'' AS index_size_summary
					FROM	#IndexSanity AS i
					WHERE	is_hypothetical = 1 OPTION	( RECOMPILE );


			RAISERROR(N'check_id 42: Disabled indexes', 0,1) WITH NOWAIT;
			--Note: disabled NC indexes will have O rows in #IndexSanitySize!
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	42 AS check_id, 
							index_sanity_id,
							N'Self Loathing Indexes' AS findings_group,
							N'Disabled Index' AS finding, 
							N'http://BrentOzar.com/go/SelfLoathing' AS URL,
							N'Disabled Index:' + schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							'DISABLED' AS index_size_summary
					FROM	#IndexSanity AS i
					WHERE	is_disabled = 1 OPTION	( RECOMPILE );

			RAISERROR(N'check_id 43: Heaps with forwarded records or deletes', 0,1) WITH NOWAIT;
			WITH	heaps_cte
					  AS ( SELECT	[object_id], 
									SUM(forwarded_fetch_count) AS forwarded_fetch_count,
									SUM(leaf_delete_count) AS leaf_delete_count
						   FROM		#IndexPartitionSanity
						   GROUP BY	[object_id]
						   HAVING	SUM(forwarded_fetch_count) > 0
									OR SUM(leaf_delete_count) > 0)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	43 AS check_id, 
								i.index_sanity_id,
								N'Self Loathing Indexes' AS findings_group,
								N'Heaps with forwarded records or deletes' AS finding, 
								N'http://BrentOzar.com/go/SelfLoathing' AS URL,
								CAST(h.forwarded_fetch_count AS NVARCHAR(256)) + ' forwarded fetches, '
								+ CAST(h.leaf_delete_count AS NVARCHAR(256)) + ' deletes against heap:'
								+ schema_object_indexid AS details, 
								i.index_definition, 
								i.secret_columns,
								i.index_usage_summary,
								sz.index_size_summary
						FROM	#IndexSanity i
						JOIN heaps_cte h ON i.[object_id] = h.[object_id]
						JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
						WHERE	i.index_id = 0 
				OPTION	( RECOMPILE );

			RAISERROR(N'check_id 44: Heaps with reads or writes.', 0,1) WITH NOWAIT;
			WITH	heaps_cte
					  AS ( SELECT	[object_id], SUM(forwarded_fetch_count) AS forwarded_fetch_count,
									SUM(leaf_delete_count) AS leaf_delete_count
						   FROM		#IndexPartitionSanity
						   GROUP BY	[object_id]
						   HAVING	SUM(forwarded_fetch_count) > 0
									OR SUM(leaf_delete_count) > 0)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	44 AS check_id, 
								i.index_sanity_id,
								N'Self Loathing Indexes' AS findings_group,
								N'Active heap' AS finding, 
								N'http://BrentOzar.com/go/SelfLoathing' AS URL,
								N'Should this table be a heap? ' + schema_object_indexid AS details, 
								i.index_definition, 
								'N/A' AS secret_columns,
								i.index_usage_summary,
								sz.index_size_summary
						FROM	#IndexSanity i
						LEFT JOIN heaps_cte h ON i.[object_id] = h.[object_id]
						JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
						WHERE	i.index_id = 0 
								AND 
									(i.total_reads > 0 OR i.user_updates > 0)
								AND h.[object_id] IS NULL /*don't duplicate the prior check.*/
				OPTION	( RECOMPILE );


			END;
		----------------------------------------
		--Indexaphobia
		--Missing indexes with value >= 5 million: : Check_id 50-59
		----------------------------------------
		BEGIN
			RAISERROR(N'check_id 50: Indexaphobia.', 0,1) WITH NOWAIT;
			WITH	index_size_cte
					  AS ( SELECT	i.[object_id], 
									MAX(i.index_sanity_id) AS index_sanity_id,
								ISNULL (
									CAST(SUM(CASE WHEN index_id NOT IN (0,1) THEN 1 ELSE 0 END)
										 AS NVARCHAR(30))+ N' NC indexes exist (' + 
									CASE WHEN SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END) > 1024
										THEN CAST(CAST(SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END )/1024. 
											AS NUMERIC(29,1)) AS NVARCHAR(30)) + N'GB); ' 
										ELSE CAST(SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END) 
											AS NVARCHAR(30)) + N'MB); '
									END + 
										CASE WHEN MAX(sz.[total_rows]) >= 922337203685477 THEN '>= 922,337,203,685,477'
										ELSE REPLACE(CONVERT(NVARCHAR(30),CAST(MAX(sz.[total_rows]) AS money), 1), '.00', '') 
										END +
									+ N' Estimated Rows;' 
								,N'') AS index_size_summary
							FROM	#IndexSanity AS i
							LEFT	JOIN #IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
						   GROUP BY	i.[object_id])
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   index_usage_summary, index_size_summary, create_tsql, more_info )
						SELECT	50 AS check_id, 
								sz.index_sanity_id,
								N'Indexaphobia' AS findings_group,
								N'High value missing index' AS finding, 
								N'http://BrentOzar.com/go/Indexaphobia' AS URL,
								mi.[statement] + ' estimated benefit: ' + 
									CASE WHEN magic_benefit_number >= 922337203685477 THEN '>= 922,337,203,685,477'
									ELSE REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(magic_benefit_number AS BIGINT) AS money), 1), '.00', '') 
									END AS details,
								missing_index_details AS [definition],
								index_estimated_impact,
								sz.index_size_summary,
								mi.create_tsql,
								mi.more_info
				FROM	#MissingIndexes mi
						LEFT JOIN index_size_cte sz ON mi.[object_id] = sz.object_id
				WHERE magic_benefit_number > 500000
				ORDER BY magic_benefit_number DESC;

	END
		 ----------------------------------------
		--Abnormal Psychology : Check_id 60-79
		----------------------------------------
	BEGIN
			RAISERROR(N'check_id 60: XML indexes', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	60 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'XML Indexes' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							N'' AS index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.is_XML = 1 OPTION	( RECOMPILE );

			RAISERROR(N'check_id 61: Columnstore indexes', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	61 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							CASE WHEN i.is_NC_columnstore=1
								THEN N'NC Columnstore Index' 
								ELSE N'Clustered Columnstore Index' 
								END AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.is_NC_columnstore = 1 OR i.is_CX_columnstore=1
					OPTION	( RECOMPILE );


			RAISERROR(N'check_id 62: Spatial indexes', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	62 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Spatial indexes' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.is_spatial = 1 OPTION	( RECOMPILE );

			RAISERROR(N'check_id 63: Compressed indexes', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	63 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Compressed indexes' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid  + N'. COMPRESSION: ' + sz.data_compression_desc AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE sz.data_compression_desc LIKE '%PAGE%' OR sz.data_compression_desc LIKE '%ROW%' OPTION	( RECOMPILE );

			RAISERROR(N'check_id 64: Partitioned', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	64 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Partitioned indexes' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.partition_key_column_name IS NOT NULL OPTION	( RECOMPILE );

			RAISERROR(N'check_id 65: Non-Aligned Partitioned', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	65 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Non-Aligned index on a partitioned table' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanity AS iParent ON
						i.[object_id]=iParent.[object_id]
						AND iParent.index_id IN (0,1) /* could be a partitioned heap or clustered table */
						AND iParent.partition_key_column_name IS NOT NULL /* parent is partitioned*/         
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.partition_key_column_name IS NULL 
						OPTION	( RECOMPILE );

			RAISERROR(N'check_id 66: Recently created tables/indexes (1 week)', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	66 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Recently created tables/indexes (1 week)' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid + N' was created on ' + 
								CONVERT(NVARCHAR(16),i.create_date,121) + 
								N'. Tables/indexes which are dropped/created regularly require special methods for index tuning.'
									 AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.create_date >= DATEADD(dd,-7,GETDATE()) 
						OPTION	( RECOMPILE );

			RAISERROR(N'check_id 67: Recently modified tables/indexes (2 days)', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
										   secret_columns, index_usage_summary, index_size_summary )
					SELECT	67 AS check_id, 
							i.index_sanity_id,
							N'Abnormal Psychology' AS findings_group,
							N'Recently modified tables/indexes (2 days)' AS finding, 
							N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
							i.schema_object_indexid + N' was modified on ' + 
								CONVERT(NVARCHAR(16),i.modify_date,121) + 
								N'. A large amount of recently modified indexes may mean a lot of rebuilds are occurring each night.'
									 AS details, 
							i.index_definition,
							i.secret_columns,
							i.index_usage_summary,
							ISNULL(sz.index_size_summary,'') AS index_size_summary
					FROM	#IndexSanity AS i
					JOIN #IndexSanitySize sz ON i.index_sanity_id = sz.index_sanity_id
					WHERE i.modify_date > DATEADD(dd,-2,GETDATE()) 
					and /*Exclude recently created tables unless they've been modified after being created.*/
					(i.create_date < DATEADD(dd,-7,GETDATE()) or i.create_date <> i.modify_date)
						OPTION	( RECOMPILE );

			RAISERROR(N'check_id 68: Identity columns within 30 percent of the end of range', 0,1) WITH NOWAIT;
			-- Allowed Ranges: 
				--int -2,147,483,648 to 2,147,483,647
				--smallint -32,768 to 32,768
				--tinyint 0 to 255

				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	68 AS check_id, 
								i.index_sanity_id, 
								N'Abnormal Psychology' AS findings_group,
								N'Identity column within ' + 									
									CAST (calc1.percent_remaining as nvarchar(256))
									+ N' percent  end of range' AS finding,
								N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
								i.schema_object_name + N'.' +  QUOTENAME(ic.column_name)
									+ N' is an identity with type ' + ic.system_type_name 
									+ N', last value of ' 
										+ ISNULL(REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(ic.last_value AS BIGINT) AS money), 1), '.00', ''),N'NULL')
									+ N', seed of '
										+ ISNULL(REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(ic.seed_value AS BIGINT) AS money), 1), '.00', ''),N'NULL')
									+ N', increment of ' + CAST(ic.increment_value AS NVARCHAR(256)) 
									+ N', and range of ' +
										CASE ic.system_type_name WHEN 'int' THEN N'+/- 2,147,483,647'
											WHEN 'smallint' THEN N'+/- 32,768'
											WHEN 'tinyint' THEN N'0 to 255'
										END
										AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexColumns ic on
							i.object_id=ic.object_id
							and i.index_id in (0,1) /* heaps and cx only */
							and ic.is_identity=1
							and ic.system_type_name in ('tinyint', 'smallint', 'int')
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						CROSS APPLY (
							SELECT CAST(CASE WHEN ic.increment_value >= 0
									THEN
										CASE ic.system_type_name 
											WHEN 'int' then (2147483647 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 2147483647.*100
											WHEN 'smallint' then (32768 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 32768.*100
											WHEN 'tinyint' then ( 255 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 255.*100
											ELSE 999
										END
								ELSE --ic.increment_value is negative
										CASE ic.system_type_name 
											WHEN 'int' then ABS(-2147483647 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 2147483647.*100
											WHEN 'smallint' then ABS(-32768 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 32768.*100
											WHEN 'tinyint' then ABS( 0 - (ISNULL(ic.last_value,ic.seed_value) + ic.increment_value)) / 255.*100
											ELSE -1
										END 
								END AS NUMERIC(5,1)) AS percent_remaining
								) as calc1
						WHERE	i.index_id in (1,0)
							and calc1.percent_remaining <= 30
						UNION ALL
						SELECT	68 AS check_id, 
								i.index_sanity_id, 
								N'Abnormal Psychology' AS findings_group,
								N'Identity column using a negative seed or increment other than 1' AS finding,
								N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
								i.schema_object_name + N'.' +  QUOTENAME(ic.column_name)
									+ N' is an identity with type ' + ic.system_type_name 
									+ N', last value of ' 
										+ ISNULL(REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(ic.last_value AS BIGINT) AS money), 1), '.00', ''),N'NULL')
									+ N', seed of '
										+ ISNULL(REPLACE(CONVERT(NVARCHAR(256),CAST(CAST(ic.seed_value AS BIGINT) AS money), 1), '.00', ''),N'NULL')
									+ N', increment of ' + CAST(ic.increment_value AS NVARCHAR(256)) 
									+ N', and range of ' +
										CASE ic.system_type_name WHEN 'int' THEN N'+/- 2,147,483,647'
											WHEN 'smallint' THEN N'+/- 32,768'
											WHEN 'tinyint' THEN N'0 to 255'
										END
										AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexColumns ic on
							i.object_id=ic.object_id
							and i.index_id in (0,1) /* heaps and cx only */
							and ic.is_identity=1
							and ic.system_type_name in ('tinyint', 'smallint', 'int')
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						WHERE	i.index_id in (1,0)
							and (ic.seed_value < 0 or ic.increment_value <> 1)
						ORDER BY finding, details DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 69: Column collation does not match database collation', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								COUNT(*) as column_count
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
								and collation_name <> @collation
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	69 AS check_id, 
								i.index_sanity_id, 
								N'Abnormal Psychology' AS findings_group,
								N'Column collation does not match database collation' AS finding,
								N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
								i.schema_object_name 
									+ N' has ' + CAST(column_count AS NVARCHAR(20))
									+ N' column' + CASE WHEN column_count > 1 THEN 's' ELSE '' END
									+ N' with a different collation than the db collation of '
									+ @collation	AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]
						WHERE	i.index_id in (1,0)
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 70: Replicated columns', 0,1) WITH NOWAIT;
				WITH count_columns AS (
							SELECT [object_id],
								COUNT(*) as column_count,
								SUM(CASE is_replicated WHEN 1 THEN 1 ELSE 0 END) as replicated_column_count
							FROM #IndexColumns ic
							WHERE index_id in (1,0) /*Heap or clustered only*/
							GROUP BY object_id
							)
				INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
											   secret_columns, index_usage_summary, index_size_summary )
						SELECT	70 AS check_id, 
								i.index_sanity_id, 
								N'Abnormal Psychology' AS findings_group,
								N'Replicated columns' AS finding,
								N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
								i.schema_object_name 
									+ N' has ' + CAST(replicated_column_count AS NVARCHAR(20))
									+ N' out of ' + CAST(column_count AS NVARCHAR(20))
									+ N' column' + CASE WHEN column_count > 1 THEN 's' ELSE '' END
									+ N' in one or more publications.'
										AS details,
								i.index_definition,
								secret_columns, 
								ISNULL(i.index_usage_summary,''),
								ISNULL(ip.index_size_summary,'')
						FROM	#IndexSanity i
						JOIN	#IndexSanitySize ip ON i.index_sanity_id = ip.index_sanity_id
						JOIN	count_columns AS cc ON i.[object_id]=cc.[object_id]
						WHERE	i.index_id in (1,0)
							and replicated_column_count > 0
						ORDER BY i.schema_object_name DESC OPTION	( RECOMPILE );

			RAISERROR(N'check_id 71: Cascading updates or cascading deletes.', 0,1) WITH NOWAIT;
			INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
								   secret_columns, index_usage_summary, index_size_summary, more_info )
			SELECT	71 AS check_id, 
					null as index_sanity_id,
					N'Abnormal Psychology' AS findings_group,
					N'Cascading Updates or Deletes' AS finding, 
					N'http://BrentOzar.com/go/AbnormalPsychology' AS URL,
					N'Foreign Key ' + foreign_key_name +
					N' on ' + QUOTENAME(parent_object_name)  + N'(' + LTRIM(parent_fk_columns) + N')'
						+ N' referencing ' + QUOTENAME(referenced_object_name) + N'(' + LTRIM(referenced_fk_columns) + N')'
						+ N' has settings:'
						+ CASE [delete_referential_action_desc] WHEN N'NO_ACTION' THEN N'' ELSE N' ON DELETE ' +[delete_referential_action_desc] END
						+ CASE [update_referential_action_desc] WHEN N'NO_ACTION' THEN N'' ELSE N' ON UPDATE ' + [update_referential_action_desc] END
							AS details, 
					N'N/A' 
							AS index_definition, 
					N'N/A' AS secret_columns,
					N'N/A' AS index_usage_summary,
					N'N/A' AS index_size_summary,
					(SELECT TOP 1 more_info from #IndexSanity i where i.object_id=fk.parent_object_id)
						AS more_info
			from #ForeignKeys fk
			where [delete_referential_action_desc] <> N'NO_ACTION'
			OR [update_referential_action_desc] <> N'NO_ACTION'

	END

		 ----------------------------------------
		--Workaholics: Check_id 80-89
		----------------------------------------
	BEGIN

		RAISERROR(N'check_id 80: Most scanned indexes (index_usage_stats)', 0,1) WITH NOWAIT;
		INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
							   secret_columns, index_usage_summary, index_size_summary )

		--Workaholics according to index_usage_stats
		--This isn't perfect: it mentions the number of scans present in a plan
		--A "scan" isn't necessarily a full scan, but hey, we gotta do the best with what we've got.
		--in the case of things like indexed views, the operator might be in the plan but never executed
		SELECT TOP 5 
			80 AS check_id,
			i.index_sanity_id as index_sanity_id,
			N'Workaholics' as findings_group,
			N'Scan-a-lots (index_usage_stats)' as finding,
			N'http://BrentOzar.com/go/Workaholics' AS URL,
			REPLACE(CONVERT( NVARCHAR(50),CAST(i.user_scans AS MONEY),1),'.00','')
				+ N' scans against ' + i.schema_object_indexid
				+ N'. Latest scan: ' + ISNULL(cast(i.last_user_scan as nvarchar(128)),'?') + N'. ' 
				+ N'ScanFactor=' + cast(((i.user_scans * iss.total_reserved_MB)/1000000.) as NVARCHAR(256)) as details,
			isnull(i.key_column_names_with_sort_order,'N/A') as index_definition,
			isnull(i.secret_columns,'') as secret_columns,
			i.index_usage_summary as index_usage_summary,
			iss.index_size_summary as index_size_summary
		FROM #IndexSanity i
		JOIN #IndexSanitySize iss on i.index_sanity_id=iss.index_sanity_id
		WHERE isnull(i.user_scans,0) > 0
		ORDER BY  i.user_scans * iss.total_reserved_MB DESC;

		RAISERROR(N'check_id 81: Top recent accesses (op stats)', 0,1) WITH NOWAIT;
		INSERT	#BlitzIndexResults ( check_id, index_sanity_id, findings_group, finding, URL, details, index_definition,
							   secret_columns, index_usage_summary, index_size_summary )
		--Workaholics according to index_operational_stats
		--This isn't perfect either: range_scan_count contains full scans, partial scans, even seeks in nested loop ops
		--But this can help bubble up some most-accessed tables 
		SELECT TOP 5 
			81 as check_id,
			i.index_sanity_id as index_sanity_id,
			N'Workaholics' as findings_group,
			N'Top recent accesses (index_op_stats)' as finding,
			N'http://BrentOzar.com/go/Workaholics' AS URL,
			ISNULL(REPLACE(
					CONVERT(NVARCHAR(50),cast((iss.total_range_scan_count + iss.total_singleton_lookup_count) AS MONEY),1),
					N'.00',N'') 
				+ N' uses of ' + i.schema_object_indexid + N'. '
				+ REPLACE(CONVERT(NVARCHAR(50), CAST(iss.total_range_scan_count AS MONEY),1),N'.00',N'') + N' scans or seeks. '
				+ REPLACE(CONVERT(NVARCHAR(50), CAST(iss.total_singleton_lookup_count AS MONEY), 1),N'.00',N'') + N' singleton lookups. '
				+ N'OpStatsFactor=' + cast(((((iss.total_range_scan_count + iss.total_singleton_lookup_count) * iss.total_reserved_MB))/1000000.) as varchar(256)),'') as details,
			isnull(i.key_column_names_with_sort_order,'N/A') as index_definition,
			isnull(i.secret_columns,'') as secret_columns,
			i.index_usage_summary as index_usage_summary,
			iss.index_size_summary as index_size_summary
		FROM #IndexSanity i
		JOIN #IndexSanitySize iss on i.index_sanity_id=iss.index_sanity_id
		WHERE isnull(iss.total_range_scan_count,0)  > 0 or isnull(iss.total_singleton_lookup_count,0) > 0
		ORDER BY ((iss.total_range_scan_count + iss.total_singleton_lookup_count) * iss.total_reserved_MB) DESC;


	END

		 ----------------------------------------
		--FINISHING UP
		----------------------------------------
	BEGIN
				INSERT	#BlitzIndexResults ( check_id, findings_group, finding, URL, details, index_definition,secret_columns,
											   index_usage_summary, index_size_summary )
				VALUES  ( 1000 , N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121)	,
						N'' ,   N'http://www.BrentOzar.com/BlitzIndex' ,
						N'Thanks from the Brent Ozar Unlimited(TM), LLC team.',
						N'We hope you found this tool useful.',
						N'If you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'
						, N'',N''
						);


	END
		RAISERROR(N'Returning results.', 0,1) WITH NOWAIT;
			
		/*Return results.*/
		SELECT isnull(br.findings_group,N'') + 
				CASE WHEN ISNULL(br.finding,N'') <> N'' THEN N': ' ELSE N'' END
				+ br.finding AS [Finding], 
			br.URL, 
			br.details AS [Details: schema.table.index(indexid)], 
			br.index_definition AS [Definition: [Property]] ColumnName {datatype maxbytes}], 
			ISNULL(br.secret_columns,'') AS [Secret Columns],          
			br.index_usage_summary AS [Usage], 
			br.index_size_summary AS [Size],
			COALESCE(br.more_info,sn.more_info,'') AS [More Info],
			COALESCE(br.create_tsql,ts.create_tsql,'') AS [Create TSQL]
		FROM #BlitzIndexResults br
		LEFT JOIN #IndexSanity sn ON 
			br.index_sanity_id=sn.index_sanity_id
		LEFT JOIN #IndexCreateTsql ts ON 
			br.index_sanity_id=ts.index_sanity_id
		ORDER BY [check_id] ASC, blitz_result_id ASC, findings_group;

	END; /* End @Mode=0 (diagnose)*/
	ELSE IF @Mode=1 /*Summarize*/
	BEGIN
	--This mode is to give some overall stats on the database.
		RAISERROR(N'@Mode=1, we are summarizing.', 0,1) WITH NOWAIT;

		SELECT 
			CAST((COUNT(*)) AS NVARCHAR(256)) AS [Number Objects],
			CAST(CAST(SUM(sz.total_reserved_MB)/
				1024. AS numeric(29,1)) AS NVARCHAR(500)) AS [All GB],
			CAST(CAST(SUM(sz.total_reserved_LOB_MB)/
				1024. AS numeric(29,1)) AS NVARCHAR(500)) AS [LOB GB],
			CAST(CAST(SUM(sz.total_reserved_row_overflow_MB)/
				1024. AS numeric(29,1)) AS NVARCHAR(500)) AS [Row Overflow GB],
			CAST(SUM(CASE WHEN index_id=1 THEN 1 ELSE 0 END)AS NVARCHAR(50)) AS [Clustered Tables],
			CAST(SUM(CASE WHEN index_id=1 THEN sz.total_reserved_MB ELSE 0 END)
				/1024. AS numeric(29,1)) AS [Clustered Tables GB],
			SUM(CASE WHEN index_id NOT IN (0,1) THEN 1 ELSE 0 END) AS [NC Indexes],
			CAST(SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
				/1024. AS numeric(29,1)) AS [NC Indexes GB],
			CASE WHEN SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)  > 0 THEN
				CAST(SUM(CASE WHEN index_id IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
					/ SUM(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END) AS NUMERIC(29,1)) 
				ELSE 0 END AS [ratio table: NC Indexes],
			SUM(CASE WHEN index_id=0 THEN 1 ELSE 0 END) AS [Heaps],
			CAST(SUM(CASE WHEN index_id=0 THEN sz.total_reserved_MB ELSE 0 END)
				/1024. AS numeric(29,1)) AS [Heaps GB],
			SUM(CASE WHEN index_id IN (0,1) AND partition_key_column_name IS NOT NULL THEN 1 ELSE 0 END) AS [Partitioned Tables],
			SUM(CASE WHEN index_id NOT IN (0,1) AND  partition_key_column_name IS NOT NULL THEN 1 ELSE 0 END) AS [Partitioned NCs],
			CAST(SUM(CASE WHEN partition_key_column_name IS NOT NULL THEN sz.total_reserved_MB ELSE 0 END)/1024. AS numeric(29,1)) AS [Partitioned GB],
			SUM(CASE WHEN filter_definition <> '' THEN 1 ELSE 0 END) AS [Filtered Indexes],
			SUM(CASE WHEN is_indexed_view=1 THEN 1 ELSE 0 END) AS [Indexed Views],
			MAX(total_rows) AS [Max Row Count],
			CAST(MAX(CASE WHEN index_id IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
				/1024. AS numeric(29,1)) AS [Max Table GB],
			CAST(MAX(CASE WHEN index_id NOT IN (0,1) THEN sz.total_reserved_MB ELSE 0 END)
				/1024. AS numeric(29,1)) AS [Max NC Index GB],
			SUM(CASE WHEN index_id IN (0,1) AND sz.total_reserved_MB > 1024 THEN 1 ELSE 0 END) AS [Count Tables > 1GB],
			SUM(CASE WHEN index_id IN (0,1) AND sz.total_reserved_MB > 10240 THEN 1 ELSE 0 END) AS [Count Tables > 10GB],
			SUM(CASE WHEN index_id IN (0,1) AND sz.total_reserved_MB > 102400 THEN 1 ELSE 0 END) AS [Count Tables > 100GB],	
			SUM(CASE WHEN index_id NOT IN (0,1) AND sz.total_reserved_MB > 1024 THEN 1 ELSE 0 END) AS [Count NCs > 1GB],
			SUM(CASE WHEN index_id NOT IN (0,1) AND sz.total_reserved_MB > 10240 THEN 1 ELSE 0 END) AS [Count NCs > 10GB],
			SUM(CASE WHEN index_id NOT IN (0,1) AND sz.total_reserved_MB > 102400 THEN 1 ELSE 0 END) AS [Count NCs > 100GB],
			MIN(create_date) AS [Oldest Create Date],
			MAX(create_date) AS [Most Recent Create Date],
			MAX(modify_date) as [Most Recent Modify Date],
			1 as [Display Order]
		FROM #IndexSanity AS i
		--left join here so we don't lose disabled nc indexes
		LEFT JOIN #IndexSanitySize AS sz 
			ON i.index_sanity_id=sz.index_sanity_id 
		UNION ALL
		SELECT	N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121)	,		
				N'sp_BlitzIndex(TM) v2.02 - Jan 30, 2014' ,   
				N'From Brent Ozar Unlimited(TM)' ,   
				N'http://BrentOzar.com/BlitzIndex' ,
				N'Thanks from the Brent Ozar Unlimited(TM) team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.',
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,0 as display_order
		ORDER BY [Display Order] ASC
		OPTION (RECOMPILE);
	   	
	END /* End @Mode=1 (summarize)*/
	ELSE IF @Mode=2 /*Index Detail*/
	BEGIN
		--This mode just spits out all the detail without filters.
		--This supports slicing AND dicing in Excel
		RAISERROR(N'@Mode=2, here''s the details on existing indexes.', 0,1) WITH NOWAIT;

		SELECT	database_name AS [Database Name], 
				[schema_name] AS [Schema Name], 
				[object_name] AS [Object Name], 
				ISNULL(index_name, '') AS [Index Name], 
				cast(index_id as VARCHAR(10))AS [Index ID],
				schema_object_indexid AS [Details: schema.table.index(indexid)], 
				CASE	WHEN index_id IN ( 1, 0 ) THEN 'TABLE'
					ELSE 'NonClustered'
					END AS [Object Type], 
				index_definition AS [Definition: [Property]] ColumnName {datatype maxbytes}],
				ISNULL(LTRIM(key_column_names_with_sort_order), '') AS [Key Column Names With Sort],
				ISNULL(count_key_columns, 0) AS [Count Key Columns],
				ISNULL(include_column_names, '') AS [Include Column Names], 
				ISNULL(count_included_columns,0) AS [Count Included Columns],
				ISNULL(secret_columns,'') AS [Secret Column Names], 
				ISNULL(count_secret_columns,0) AS [Count Secret Columns],
				ISNULL(partition_key_column_name, '') AS [Partition Key Column Name],
				ISNULL(filter_definition, '') AS [Filter Definition], 
				is_indexed_view AS [Is Indexed View], 
				is_primary_key AS [Is Primary Key],
				is_XML AS [Is XML],
				is_spatial AS [Is Spatial],
				is_NC_columnstore AS [Is NC Columnstore],
				is_CX_columnstore AS [Is CX Columnstore],
				is_disabled AS [Is Disabled], 
				is_hypothetical AS [Is Hypothetical],
				is_padded AS [Is Padded], 
				fill_factor AS [Fill Factor], 
				is_referenced_by_foreign_key AS [Is Reference by Foreign Key], 
				last_user_seek AS [Last User Seek], 
				last_user_scan AS [Last User Scan], 
				last_user_lookup AS [Last User Lookup],
				last_user_update AS [Last User Update], 
				total_reads AS [Total Reads], 
				user_updates AS [User Updates], 
				reads_per_write AS [Reads Per Write], 
				index_usage_summary AS [Index Usage], 
				sz.partition_count AS [Partition Count],
				sz.total_rows AS [Rows], 
				sz.total_reserved_MB AS [Reserved MB], 
				sz.total_reserved_LOB_MB AS [Reserved LOB MB], 
				sz.total_reserved_row_overflow_MB AS [Reserved Row Overflow MB],
				sz.index_size_summary AS [Index Size], 
				sz.total_row_lock_count AS [Row Lock Count],
				sz.total_row_lock_wait_count AS [Row Lock Wait Count],
				sz.total_row_lock_wait_in_ms AS [Row Lock Wait ms],
				sz.avg_row_lock_wait_in_ms AS [Avg Row Lock Wait ms],
				sz.total_page_lock_count AS [Page Lock Count],
				sz.total_page_lock_wait_count AS [Page Lock Wait Count],
				sz.total_page_lock_wait_in_ms AS [Page Lock Wait ms],
				sz.avg_page_lock_wait_in_ms AS [Avg Page Lock Wait ms],
				sz.total_index_lock_promotion_attempt_count AS [Lock Escalation Attempts],
				sz.total_index_lock_promotion_count AS [Lock Escalations],
				sz.data_compression_desc AS [Data Compression],
				i.create_date AS [Create Date],
				i.modify_date as [Modify Date],
				more_info AS [More Info],
				1 as [Display Order]
		FROM	#IndexSanity AS i --left join here so we don't lose disabled nc indexes
				LEFT JOIN #IndexSanitySize AS sz ON i.index_sanity_id = sz.index_sanity_id
		UNION ALL
		SELECT 	N'Database ' + QUOTENAME(@DatabaseName) + N' as of ' + convert(nvarchar(16),getdate(),121)			
				N'sp_BlitzIndex(TM) v2.02 - Jan 30, 2014' ,   
				N'From Brent Ozar Unlimited(TM)' ,   
				N'http://BrentOzar.com/BlitzIndex' ,
				N'Thanks from the Brent Ozar Unlimited(TM) team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.',
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL, NULL,NULL, NULL, NULL, NULL, NULL,NULL,NULL,
				0 as [Display Order]
		ORDER BY [Display Order] ASC, [Reserved MB] DESC
		OPTION (RECOMPILE);

	END /* End @Mode=2 (index detail)*/
	ELSE IF @Mode=3 /*Missing index Detail*/
	BEGIN
		SELECT 
			database_name AS [Database], 
			[schema_name] AS [Schema], 
			table_name AS [Table], 
			CAST(magic_benefit_number AS BIGINT)
				AS [Magic Benefit Number], 
			missing_index_details AS [Missing Index Details], 
			avg_total_user_cost AS [Avg Query Cost], 
			avg_user_impact AS [Est Index Improvement], 
			user_seeks AS [Seeks], 
			user_scans AS [Scans],
			unique_compiles AS [Compiles], 
			equality_columns AS [Equality Columns], 
			inequality_columns AS [Inequality Columns], 
			included_columns AS [Included Columns], 
			index_estimated_impact AS [Estimated Impact], 
			create_tsql AS [Create TSQL], 
			more_info AS [More Info],
			1 as [Display Order]
		FROM #MissingIndexes
		UNION ALL
		SELECT 				
			N'sp_BlitzIndex(TM) v2.02 - Jan 30, 2014' ,   
			N'From Brent Ozar Unlimited(TM)' ,   
			N'http://BrentOzar.com/BlitzIndex' ,
			100000000000,
			N'Thanks from the Brent Ozar Unlimited(TM) team. We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.',
			NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			NULL, 0 as display_order
		ORDER BY [Display Order] ASC, [Magic Benefit Number] DESC

	END /* End @Mode=3 (index detail)*/
END
END TRY
BEGIN CATCH
		RAISERROR (N'Failure analyzing temp tables.', 0,1) WITH NOWAIT;

		SELECT	@msg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		RAISERROR (@msg, 
               @ErrorSeverity, 
               @ErrorState 
               );
		
		WHILE @@trancount > 0 
			ROLLBACK;

		RETURN;
	END CATCH;
GO




