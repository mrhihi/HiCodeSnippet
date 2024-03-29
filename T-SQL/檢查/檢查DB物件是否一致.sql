/*
比對資料庫物件(TR、FN、P、TF、IF、V )
用法：先在 source 資料庫執行，會產生一段 sql 語法，
把這段 sql 語法拿去 target 資料庫執行即可。
PS. 預設語法會過慮掉 source 有， target 沒有 或 target 有 source 沒有，只產生「不一樣的」部份。
*/


select 
'declare @cust table (
    name nvarchar(100),
    [type] varchar(10),
    md5 varchar(200),
    primary key (name, type, md5)
)
Declare @prod table (
    name nvarchar(100),
    [type] varchar(10),
    md5 varchar(200),
    primary key (name, type, md5)
)
insert into @prod
' + (
    select stuff((
    select 'union select ''' + b.name + ''','
         , '''' + b.[type] + ''','
         , '''' + sys.fn_varbintohexstr(sys.fn_repl_hash_binary(cast(rtrim(ltrim(replace(replace(a.definition,char(13),''),char(10),''))) as varbinary(max)))) + ''''
      from sys.all_sql_modules a
            join sys.all_objects b on a.object_id = b.object_id
                and b.schema_id in (
                    select schema_id
                   from sys.schemas
                    where name in ('dbo', 'hangfire', 'Envers')
                    )
                    and b.name not like 'Audit%'
            order by b.[type], b.name
    for xml path('')), 1, 6, '')
) + '
insert into @cust
select b.name
      ,b.[type]
      ,sys.fn_varbintohexstr(sys.fn_repl_hash_binary(cast(rtrim(ltrim(replace(replace(a.definition,char(13),''''),char(10),''''))) as varbinary(max))))
    from sys.all_sql_modules a
        join sys.all_objects b on a.object_id = b.object_id
            and b.schema_id in (
                select schema_id
                from sys.schemas
                where name in (''dbo'', ''hangfire'', ''Envers'')
                )
                and b.name not like ''Audit%''
        order by b.[type], b.name
        option (optimize for unknown)

select ''prod'', a.*, ''|**|'', c.[type], c.md5
  from @prod a
  left join @cust b on a.name = b.name and a.[type] = b.[type] and a.md5 = b.md5
  left join @cust c on a.name = c.name
  where b.name is null and c.name is not null
union all
select ''cust'', a.*, ''|**|'', c.[type], c.md5
  from @cust a
  left join @prod b on a.name = b.name and a.[type] = b.[type] and a.md5 = b.md5
  left join @prod c on a.name = c.name
  where b.name is null and c.name is not null
option (optimize for unknown)

'
for xml path('')
