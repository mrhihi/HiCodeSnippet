-- ����p�e�֨�
    -- https://jonesyeh.wordpress.com/2015/06/01/�M������p�ecache�άd�߰���p�ecache�y�k/
    -- https://msdn.microsoft.com/zh-tw/communitydocs/sql-server/ta13031901
-- �d�ߧ֨�
    -- http://ithelp.ithome.com.tw/articles/10187558

    CHECKPOINT;
    DBCC DROPCLEANBUFFERS ;
    dbcc FREEPROCCACHE;
    go
