declare @tmpAll table(schemaName nvarchar(500), tableName nvarchar(500), indexName nvarchar(500), columnName nvarchar(500), columnOrder int)

declare @allIndex table(schemaName nvarchar(500), tableName nvarchar(500), indexName nvarchar(500), sqlscript nvarchar(max))

declare @schemaName nvarchar(500), @tableName nvarchar(500), @indexName nvarchar(500), @sqlscript nvarchar(max)

insert into @tmpAll(schemaName, tableName, indexName, columnName, columnOrder)
SELECT
	 s.name as schemaName,
     t.name tableName,
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
select schemaName, tableName, indexName from @tmpAll group by schemaName, tableName, indexName

open vendor_cursor
fetch next from vendor_cursor
into @schemaName, @tableName, @indexName

while @@FETCH_STATUS = 0
begin

	select @sqlscript=stuff((select ','+ columnName from @tmpAll where schemaName=@schemaName and tableName=@tableName and indexName=@indexName order by columnOrder for xml path('')),1,1,'')
	insert into @allIndex(schemaName, tableName, indexName, sqlscript)
	select @schemaName, @tableName, @indexName, @sqlscript

	fetch next from vendor_cursor
	into @schemaName, @tableName, @indexName
end
close vendor_cursor
deallocate vendor_cursor

select * from @allIndex