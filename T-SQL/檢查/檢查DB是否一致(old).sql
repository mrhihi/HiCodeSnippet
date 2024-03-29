/* 用 DB 中各 Table 的資料表名稱、索引名稱及其筆數，計算 HASH ，用以檢查兩個 DB 是否一樣 */
declare @exesql nvarchar(max)
declare @sql nvarchar(max), @sql2 nvarchar(max)
set @sql = '
declare @infoCount int, @idx int
declare @dbinfo table(schema_table nvarchar(200), index_name nvarchar(200), row_count int, idx int identity)

insert into @dbinfo(schema_table, index_name, row_count)
SELECT  t.schema_name + '' – '' + t.table_name AS schema_table , 
        t.index_name , 
        SUM(t.tbl_rows) AS rows 
FROM    ( SELECT    s.name schema_name , 
                    o.name table_name , 
                    COALESCE(i.name, ''HEAP'') index_name , 
                    p.row_count ind_rows , 
                    CASE WHEN i.index_id IN ( 0, 1 ) THEN p.row_count 
                         ELSE 0 
                    END tbl_rows 
          FROM      {dbname}.sys.dm_db_partition_stats p 
                    INNER JOIN {dbname}.sys.objects AS o ON o.object_id = p.object_id 
                    INNER JOIN {dbname}.sys.schemas AS s ON s.schema_id = o.schema_id 
                    LEFT OUTER JOIN {dbname}.sys.indexes AS i ON i.object_id = p.object_id 
                                                        AND i.index_id = p.index_id 
          WHERE     o.type_desc = ''USER_TABLE'' 
                    AND o.is_ms_shipped = 0 
					and ( o.name in ({tables}) or '''' in ({tables}))
        ) AS t 
GROUP BY t.schema_name , 
        t.table_name , 
        t.index_name 
ORDER BY 1,2
'
set @sql2 ='
declare @hashresult varchar(32)
declare @schema_table nvarchar(200), @index_name nvarchar(200), @row_count int

select @infoCount = count(1) from @dbinfo
select @idx =  0, @hashresult = ''''
while @idx < @infoCount
begin
	set @idx = @idx + 1
	select @schema_table = schema_table
		, @index_name = index_name
		, @row_count = row_count
	from @dbinfo
	where idx = @idx
	set @hashresult = sys.fn_varbintohexsubstring(0, hashbytes( ''MD5'', @hashresult + sys.fn_varbintohexsubstring(0, hashbytes( ''MD5'', @schema_table + @index_name + convert(varchar(100), @row_count) ), 1, 0) ), 1, 0)
end

select ''{dbname}'', @hashresult

'

declare @result table(dbName nvarchar(200), hash varchar(max))
declare @variableTable table(dbName nvarchar(200), tables nvarchar(max), idx int identity)
declare @var_count int, @idx int
declare @var_dbname nvarchar(200), @var_tables nvarchar(max)
/* dbName: 欲檢查的資料庫
 * tables: 欲檢查的資料表(空字串表示全找)(以逗號分隔 ex: '''EMP_EMPLOYEE'',''ORG_DEPART''')
 **/
insert into @variableTable(dbName, tables) select 'HR31_SC30_E', ''''''
insert into @variableTable(dbName, tables) select 'HR31_WF20_T', ''''''
insert into @variableTable(dbName, tables) select 'HR31_RADAR_E', ''''''
select @idx = 0, @var_count = (select count(1) from @variableTable)

while @idx < @var_count
begin 
	set @idx = @idx + 1
	select @var_dbname = dbName , @var_tables = tables from @variableTable where idx = @idx
	set @exesql = replace(replace(@sql + @sql2, '{dbname}', @var_dbname), '{tables}', @var_tables)
	print replace(replace(@sql, '{dbname}', @var_dbname), '{tables}', @var_tables) + 'select * from @dbinfo'
	insert into @result(dbName, hash)
	exec ( @exesql )	
end 

select * from @result


