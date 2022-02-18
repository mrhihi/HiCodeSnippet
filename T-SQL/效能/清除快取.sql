-- 執行計畫快取
    -- https://jonesyeh.wordpress.com/2015/06/01/清除執行計畫cache及查詢執行計畫cache語法/
    -- https://msdn.microsoft.com/zh-tw/communitydocs/sql-server/ta13031901
-- 查詢快取
    -- http://ithelp.ithome.com.tw/articles/10187558

    CHECKPOINT;
    DBCC DROPCLEANBUFFERS ;
    dbcc FREEPROCCACHE;
    go
