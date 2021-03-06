-- picking the tables that qualify CCI
-- Key logic is
-- (a) Table does not have CCI
-- (b) At least one partition has > 1 million rows and does not have 
--     unsupported types for CCI
-- (c) Range queries account for > 50% of all operations
-- (d) DML Update/Delete operations < 10% of all operations

select 
  table_id
, table_name 
from (
  select 
   quotename(object_schema_name(dmv_ops_stats.object_id)) + N'.' + quotename(object_name (dmv_ops_stats.object_id)) as table_name
  ,dmv_ops_stats.object_id as table_id
  ,SUM (leaf_delete_count + range_scan_count + singleton_lookup_count + leaf_update_count) as total_ops_count
  ,SUM (leaf_delete_count + leaf_update_count) as total_dml_count
  ,SUM (range_scan_count + singleton_lookup_count) as total_query_count
  ,SUM (range_scan_count) as range_scan_count
  from sys.dm_db_index_operational_stats (db_id(), null, null, null) as dmv_ops_stats 
  where 
    (index_id = 0 or index_id = 1) 
  AND dmv_ops_stats.object_id in (
                        select distinct object_id 
                        from sys.partitions p
                        where data_compression <= 2 and (index_id = 0 or index_id = 1) 
                        AND rows > 1048576
                        AND object_id in (
                            select distinct object_id
                            from sys.partitions p, sysobjects o
                            where 
                              o.type = 'u' 
                            and p.object_id = o.id
                        )
        )
  AND dmv_ops_stats.object_id not in 
    ( select distinct object_id 
      from sys.columns
      where 
        user_type_id IN (34, 35, 241)
      OR ((user_type_id = 165 OR user_type_id = 167) and max_length = -1)
    )
  AND dmv_ops_stats.object_id not in 
    ( select distinct object_id
      from sys.partitions
      where data_compression > 2
    )
  group by dmv_ops_stats.object_id 
 ) summary_table

where 
  ((total_dml_count * 100.0/NULLIF(total_ops_count, 0) < 10.0)
and (range_scan_count*100.0/NULLIF(total_query_count, 0) > 50.0))
;