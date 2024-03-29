declare @tmpAll table(schemaName nvarchar(500), tableName nvarchar(500), object_id int, index_id int, indexName nvarchar(500), columnName nvarchar(500), columnOrder int)

declare @allIndex table(schemaName nvarchar(500), tableName nvarchar(500), object_id int, index_id int, indexName nvarchar(500), sqlscript nvarchar(max), used_in_mb numeric(10,2), tbl_rows bigint)

declare @schemaName nvarchar(500), @tableName nvarchar(500), @objectId int, @indexId int, @indexName nvarchar(500), @sqlscript nvarchar(max), @used_in_mb numeric(10,2), @tbl_rows bigint

insert into @tmpAll(schemaName, tableName, object_id, index_id, indexName, columnName, columnOrder)
SELECT
	 s.name as schemaName,
     t.name tableName,
     ind.object_id as objectId,
     ind.index_id,
     ind.name indexName,
     col.name columnName,
     key_ordinal columnOrder
FROM
     sys.indexes ind
INNER JOIN
     sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id
INNER JOIN
     sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id
INNER JOIN
     sys.tables t ON ind.object_id = t.object_id
inner join sys.schemas s on t.schema_id = s.schema_id
WHERE
     ind.is_primary_key = 0
     AND ind.is_unique = 0
     AND ind.is_unique_constraint = 0
     AND t.is_ms_shipped = 0
ORDER BY
     t.name, ind.name, ind.index_id, ic.index_column_id

declare vendor_cursor cursor for 
select a.schemaName, a.tableName, a.object_id, a.index_id, a.indexName 
    , cast(SUM(p.used_page_count * 8 )/1024.0 as numeric(10,2)) AS used_in_mb
    , sum(p.row_count) as tbl_rows
from @tmpAll a
join sys.dm_db_partition_stats p on a.object_id = p.object_id and a.index_id = p.index_id
group by a.schemaName, a.tableName, a.object_id, a.index_id, a.indexName

open vendor_cursor
fetch next from vendor_cursor
into @schemaName, @tableName, @objectId, @indexId, @indexName
    , @used_in_mb, @tbl_rows

while @@FETCH_STATUS = 0
begin

	select @sqlscript=stuff((select ','+ columnName from @tmpAll where schemaName=@schemaName and tableName=@tableName and indexName=@indexName order by columnOrder for xml path('')),1,1,'')
	insert into @allIndex(schemaName, tableName, object_id, index_id, indexName, sqlscript, used_in_mb, tbl_rows)
	select @schemaName, @tableName, @objectId, @indexId, @indexName, @sqlscript, @used_in_mb, @tbl_rows

	fetch next from vendor_cursor
	into @schemaName, @tableName, @objectId, @indexId, @indexName
        , @used_in_mb, @tbl_rows
end
close vendor_cursor
deallocate vendor_cursor

select a.schemaName, a.tableName, a.indexName, a.sqlscript
     , b.user_seeks, b.user_scans, b.user_lookups, b.user_updates
     , a.used_in_mb, a.tbl_rows
from @allIndex a 
join sys.dm_db_index_usage_stats b on a.object_id = b.object_id and a.index_id = b.index_id
order by (tbl_rows * user_scans) desc

