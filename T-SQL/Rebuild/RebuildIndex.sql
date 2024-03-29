exec sp_updatestats

DECLARE @refresh_index VARCHAR(MAX)
      , @avg_frag float
      , @table_tobe varchar(200)

DECLARE db_cursor CURSOR FAST_FORWARD FOR
        SELECT distinct 'ALTER INDEX [' + ix.name + '] ON [' + s.name + '].[' + t.name + '] ' +
            CASE
                    WHEN ps.avg_fragmentation_in_percent > 15
                    THEN 'REBUILD With (MAXDOP=1)'
                    ELSE 'REORGANIZE With (MAXDOP=1)'
            END +
            CASE
                    WHEN pc.partition_count > 1
                    THEN ' PARTITION = ' + CAST(ps.partition_number AS nvarchar(MAX))
                    ELSE ''
            END as sqltext
            , ps.avg_fragmentation_in_percent
            , t.name
        FROM sys.indexes AS ix
        JOIN sys.tables t ON t.object_id = ix.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        join sys.stats ss on t.object_id = ss.object_id
        JOIN
            (SELECT object_id
                    , index_id
                    , avg_fragmentation_in_percent
                    , partition_number
                FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL)
            ) ps ON t.object_id = ps.object_id
                    AND ix.index_id = ps.index_id
        JOIN
            (SELECT object_id
                    , index_id
                    , COUNT(DISTINCT partition_number) AS partition_count
                FROM sys.partitions
                GROUP BY object_id, index_id
            ) pc ON t.object_id = pc.object_id
                    AND ix.index_id = pc.index_id
        WHERE  ps.avg_fragmentation_in_percent > 11
          AND ix.name IS NOT NULL
          AND t.name not in ('SCUserServiceLog', 'LOL_WCAL')
        order by ps.avg_fragmentation_in_percent desc


OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @refresh_index, @avg_frag, @table_tobe

WHILE @@FETCH_STATUS = 0
BEGIN
       print 'Updating: ' + @table_tobe
       exec ( @refresh_index )
       FETCH NEXT FROM db_cursor INTO @refresh_index, @avg_frag, @table_tobe
END

CLOSE db_cursor
DEALLOCATE db_cursor
GO

-- exec sp_updatestats

GO