/**
 * 名稱：查詢資料庫使用量
 * 目的：
 *       查詢資料庫使用量，將結果依 資料庫名稱 及 使用量大到小 做排序 呈現。
 * 說明：
 *       沒有 clustered 索引時， index_nmae 為 'HEAP'。
 *       預設排序會將相同 table 的所有資料量(index 、 heap) sum 在一起排序。
 * 輸入參數：
 *   @dts       欲查詢的資料庫，多個時用逗號隔開 ex 'DB_ABC,DB_DEF'
 */


declare @dts varchar(200)='HRS_RADAR_M,HRS_ENVERS_M,HRS_DATAHUB_M,HRS_SC30_M' /* 改這裡 */

/* 以下不用改 */
declare @sql nvarchar(4000)
/* 欲查詢資料佔用量的資料庫清單 */
declare @dbs table (dbname nvarchar(100))
set @dts = ','+@dts+','
insert into @dbs 
    select name from sys.databases 
    where name not in ('master', 'tempdb', 'model','msdb') 
        and (@dts=',,' or charindex(','+name+',', @dts,0)>0)
    order by name

if object_id('tempdb..#DBUsage') is not null drop table  #DBUsage

create table #DBUsage (DBName Nvarchar(50), schema_table nvarchar(100), index_name nvarchar(100), used_in_kb int, reserved_in_kb int, used_in_mb numeric(10,2), reserved_in_mb numeric(10,2), rows int)

declare @statment nvarchar(4000) = N'
insert into #DBUsage
    SELECT  DB_NAME() as DBName, t.schema_name + '' – '' + t.table_name AS schema_table ,
            t.index_name ,
            SUM(t.used) AS used_in_kb ,
            SUM(t.reserved) AS reserved_in_kb ,
            cast(SUM(t.used)/1024.0 as numeric(10,2)) AS used_in_mb ,
            cast(SUM(t.reserved)/1024.0 as numeric(10,2)) AS reserved_in_mb ,
            SUM(t.tbl_rows) AS rows
    FROM    ( SELECT    s.name schema_name ,
                        o.name table_name ,
                        COALESCE(i.name, ''HEAP'') index_name ,
                        p.used_page_count * 8 used ,
                        p.reserved_page_count * 8 reserved ,
                        p.row_count ind_rows ,
                        CASE WHEN i.index_id IN ( 0, 1 ) THEN p.row_count
                             ELSE 0
                        END tbl_rows
              FROM      sys.dm_db_partition_stats p
                        INNER JOIN sys.objects AS o ON o.object_id = p.object_id
                        INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
                        LEFT OUTER JOIN sys.indexes AS i ON i.object_id = p.object_id
                                                            AND i.index_id = p.index_id
              WHERE     o.type_desc = ''USER_TABLE''
                        AND o.is_ms_shipped = 0
            ) AS t
    GROUP BY t.schema_name ,
            t.table_name ,
            t.index_name

'
DECLARE vendor_cursor CURSOR FOR select 'use ' + dbname + ';' + @statment as statment from @dbs 
OPEN vendor_cursor FETCH NEXT FROM vendor_cursor INTO @sql

WHILE @@FETCH_STATUS = 0 BEGIN  

    exec sp_executesql @sql

    FETCH NEXT FROM vendor_cursor INTO @sql

END   
CLOSE vendor_cursor;  
DEALLOCATE vendor_cursor; 

select a.DBName, c.db_total_used_in_mb, 
       a.schema_table, b.table_total_used_in_mb, 
       a.index_name, a.used_in_kb, a.reserved_in_kb, a.used_in_mb, a.reserved_in_mb, a.rows
from #DBUsage a
join (select cast(sum(used_in_kb)/1024.0 as numeric(10,2)) as table_total_used_in_mb, DBName, schema_table 
      from #DBUsage group by DBName, schema_table) b on a.DBName = b.DBName and a.schema_table = b.schema_table
join (select cast(sum(used_in_kb)/1024.0 as numeric(10,2)) as db_total_used_in_mb, DBName
     from #DBUsage group by DBName) c on a.DBName = c.DBName
where b.table_total_used_in_mb > 0
order by c.db_total_used_in_mb desc, b.table_total_used_in_mb desc, a.used_in_kb desc
