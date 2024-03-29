-- 文字顯示執行計劃
-- SET SHOWPLAN_TEXT OFF
-- SET SHOWPLAN_ALL ON

-- show conftig
dbcc showcontig('PartyRole') with tableresults

-- 使用空間
sp_spaceused 'dbo.PartyRole'

-- 效能相關簡報
-- https://www.slideshare.net/cwchiu/sql-server-2008-1917302?next_slideshow=1


-- sys.dm_db_index_physical_stats 說明
-- https://docs.microsoft.com/zh-tw/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver15

-- 填滿因素
-- https://docs.microsoft.com/zh-tw/sql/relational-databases/indexes/specify-fill-factor-for-an-index?view=sql-server-ver15


-- 索引架構和設計指南
-- https://docs.microsoft.com/zh-tw/sql/relational-databases/sql-server-index-design-guide?view=sql-server-ver15


-- 檢查執行計畫的 handle
SELECT plan_handle, st.text  
FROM sys.dm_exec_cached_plans   
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st  
WHERE text LIKE N'select * from PartyRole where PartyRoleID> 0'; 

-- 清除指定執行計畫的快取
SELECT 'DBCC FREEPROCCACHE(', plan_handle,')'  
FROM sys.dm_exec_cached_plans   
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st  
WHERE text LIKE N'%SYNONYM_WF20_NOTIFICATION_QUEUE%'; 


-- https://www.mssqltips.com/sqlservertip/5908/what-is-the-best-value-for-fill-factor-in-sql-server/
-- 檢查索引碎裂程度
-- 'DETAILED' 'SIMPLE'
SELECT tbl.name TableName
    , idx.name IndexName, idx.fill_factor
    , CAST(Fragmentation.avg_page_space_used_in_percent AS DECIMAL(4,1)) ActualFillFactor
    , CAST(Fragmentation.avg_fragmentation_in_percent AS DECIMAL(4,1)) CurrentFragmentation
    , Fragmentation.fragment_count
    , CAST(Fragmentation.avg_fragment_size_in_pages AS DECIMAL(8,1)) AvgFragmentSize 
FROM sys.tables tbl 
JOIN sys.indexes idx ON tbl.object_id = idx.object_id
CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), null, null, 0, null) Fragmentation
where tbl.object_id = Fragmentation.object_id
    and idx.index_id = Fragmentation.index_id
    and tbl.name LIKE 'PartyRole';	

-- 索引碎裂程序簡易版
SELECT i.name as IndexName, * 
FROM sys.dm_db_index_physical_stats(DB_ID(N'CRF_RADAR_M'), OBJECT_ID(N'dbo.PartyRole'), NULL, NULL , 'DETAILED') s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id]
AND s.index_id = i.index_id

-- 重建索引並指定 fillfactor
alter index IDX_PartyRole_2 on dbo.PartyRole rebuild with(fillfactor=100)
alter index PK_PartyRole on dbo.PartyRole rebuild with(fillfactor=100)
alter table dbo.PartyRole rebuild
