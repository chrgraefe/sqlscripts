use tempdb
go

DECLARE
	@DEC_FACTOR NUMERIC(15, 1) = 1.0
;

SELECT 
df.NAME
,df.type_desc
,fs.num_of_reads
,fs.io_stall_read_ms
,fs.io_stall_read_ms / NULLIF(fs.num_of_reads, 0) io_stall_per_read_ms
,(@DEC_FACTOR * fs.num_of_bytes_read / 1024 / 1024) num_of_MBytes_read

,fs.num_of_writes
,(@DEC_FACTOR * fs.num_of_bytes_written / 1024 / 1024) num_of_MBytes_written
,fs.io_stall_write_ms
,fs.io_stall_write_ms / NULLIF(fs.num_of_writes, 0) io_stall_per_write_ms

,(@DEC_FACTOR * df.size * 8 / 1024) size_in_MB

FROM sys.dm_io_virtual_file_stats(NULL, NULL) fs
INNER JOIN sys.database_files df ON df.file_id = fs.file_id
WHERE	fs.database_id = DB_ID()
order by NAME
;