/**
 * 名稱：查看索引使用情況與對應 Table 的筆數
 * 目的：
 *      不好的索引
 *        索引被更新(user_updates)次數遠大於使用次數
 *        user_seeks 遠小於 user_scans
 * 說明：
 *       seeks 的速度比較快，如果索引可以有效用到 seek 的話會比較好，都在用 scan 的話要考慮一下是不是需要建立別的索引
 * 輸入參數： 無
 * 參考資料：
 *      https://blog.ite2.com/%E5%A6%82%E4%BD%95%E5%B0%8B%E6%89%BEms-sql%E6%95%88%E8%83%BD%E4%B8%8D%E5%A5%BD%E7%9A%84%E7%B4%A2%E5%BC%95/
 *      https://jengting.blogspot.com/2014/02/index-usage-stats.html
 *      https://blog.miniasp.com/post/2011/08/12/How-to-find-out-unnecessary-SQL-Server-Index-from-Index-Usage-Statistics-Report
 */


SELECT 
  s.name AS SchemaName ,
  t.name AS TableName ,
  ix.name AS IndexName ,
  ix.type_desc ,
  us.user_seeks ,
  us.user_scans ,
  us.user_lookups ,
  us.user_updates ,
  r.row_count as table_row_count
FROM sys.tables AS t 
  JOIN sys.schemas s on t.[schema_id] = s.[schema_id]
  JOIN sys.indexes AS ix ON t.[object_id] = ix.[object_id]
  JOIN sys.dm_db_index_usage_stats AS us ON ix.[object_id] = us.[object_id]
                                           AND ix.index_id = us.index_id    
left join (
    SELECT
        s.schema_id,
        o.object_id as table_id,
        p.row_count
    FROM      sys.dm_db_partition_stats p
            INNER JOIN sys.objects AS o ON o.object_id = p.object_id
            INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
            LEFT OUTER JOIN sys.indexes AS i ON i.object_id = p.object_id
                                                AND i.index_id = p.index_id
    WHERE     o.type_desc = 'USER_TABLE'
            AND o.is_ms_shipped = 0
            and i.index_id in ( 0, 1 )
) r on t.schema_id = r.schema_id and t.object_id = r.table_id
WHERE t.type = 'U' -- 使用者自訂 Table
-- and t.name = 'SCUserEmployee'
order by case when ix.type_desc='HEAP' then 1 else 0 end 
      , r.row_count desc
      , us.user_scans desc

