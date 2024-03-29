-- 1、找出最耗用IO的語法
SELECT TOP 10
total_logical_reads,
total_logical_writes,
execution_count,
total_logical_reads+total_logical_writes AS [IO_total],
st.text AS query_text,
db_name(st.dbid) AS database_name,
st.objectid AS object_id
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
WHERE total_logical_reads+total_logical_writes> 0
ORDER BY [IO_total] DESC

-- 2、列出目前最耗用CPU的前50個查詢
SELECT  TOP 50
qs.total_worker_time / qs.execution_count AS[Avg CPU Time],
SUBSTRING(qt.text, qs.statement_start_offset / 2,
(CASE WHEN qs.statement_end_offset = -1 THEN len(CONVERT (NVARCHAR (MAX), qt.text)) * 2
ELSE qs.statement_end_offset END - qs.statement_start_offset) / 2) AS query_text,
qt.dbid,
qt.objectid
FROM     sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) AS qt
ORDER BY [Avg CPU Time] DESC;

-- 3、列出目前最耗用Worker Time的前50個查詢
SELECT   TOP 50 sum(qs.total_worker_time) AS total_cpu_time,
                sum(qs.execution_count) AS total_execution_count,
                count(*) AS '#_statements',
                qt.dbid,
                qt.objectid,
                qs.sql_handle,
                qt.[text]
FROM     sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text (qs.sql_handle) AS qt
GROUP BY qt.dbid, qt.objectid, qs.sql_handle, qt.[text]
ORDER BY sum(qs.total_worker_time) DESC, qs.sql_handle;