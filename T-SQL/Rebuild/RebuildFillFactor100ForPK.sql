-- http://sqlmag.com/blog/what-best-value-fill-factor-index-fill-factor-and-performance-part-2
-- 尋找所有 PK 含 Identity 欄位的索引，重建成 Fill factor = 100 
declare @sql nvarchar(max);

select @sql = (
select 'alter index '+ idx.name + ' on ' + sc.name + '.' + obj.name + ' rebuild with (fillfactor = 100);'
--select * 
from sys.indexes idx 
join sys.objects obj on idx.object_id = obj.object_id and obj.type = 'U'
join sys.schemas sc on obj.schema_id = sc.schema_id and sc.name = 'dbo'
where exists(
    SELECT 'x' FROM sys.index_columns a where exists (select 'x' 
                                                        from sys.all_columns x 
                                                        where x.is_identity = 1 
                                                        and a.object_id = x.object_id and a.index_column_id = x.column_id)
                                            and idx.object_id = a.object_id
                                            and idx.index_id = a.index_id
) and is_primary_key = 1
for xml path(''))

exec (@sql)


-- rebuild table
select @sql = (
select 'alter table '+ a.name + ' rebuild;'
FROM sys.objects a
join sys.schemas b on a.schema_id = b.schema_id and b.name='dbo'
where a.type='U' 
for xml path(''))

exec (@sql)

exec spDataEncryptionGenerater

exec sp_updatestats