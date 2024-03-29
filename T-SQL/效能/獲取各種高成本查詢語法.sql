-- 參考來源： https://medium.com/ricos-note/sql-server-%E7%8D%B2%E5%8F%96%E5%90%84%E7%A8%AE%E9%AB%98%E6%88%90%E6%9C%AC%E6%9F%A5%E8%A9%A2%E8%AA%9E%E6%B3%95-6939bcc29420
-- [SQL SERVER][TSQL]獲取各種高成本查詢語法
-- 昨天MSN那頭傳來:我該如何知道現有資料庫有那些高成本的查詢，
-- 好加在以前自己在幹DBA時，有養成蒐集和整理好用的語法習慣，
-- 故將查詢語法整理如下，分享給有需要的朋友。
-- 以下語法在SQL2005~2016均能正常執行。

--I/O的高成本查詢   
  SELECT TOP 10 
  [Average IO] = (total_logical_reads + total_logical_writes) / qs.execution_count
  ,[Total IO] = (total_logical_reads + total_logical_writes)
  ,[Execution count] = qs.execution_count
  ,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
  (CASE WHEN qs.statement_end_offset = -1 
  THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
  ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) 
  ,[Parent Query] = qt.text
  ,DatabaseName = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average IO] DESC;

--CPU的高成本查詢   
  SELECT TOP 10 
  [Average CPU used] = total_worker_time / qs.execution_count
  ,[Total CPU used] = total_worker_time
  ,[Execution count] = qs.execution_count
  ,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
  (CASE WHEN qs.statement_end_offset = -1 
  THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
  ELSE qs.statement_end_offset END - 
  qs.statement_start_offset)/2)
  ,[Parent Query] = qt.text
  ,DatabaseName = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average CPU used] DESC;

--CLR的高成本查詢   
  SELECT TOP 10 
  [Average CLR Time] = total_clr_time / execution_count 
  ,[Total CLR Time] = total_clr_time 
  ,[Execution count] = qs.execution_count
  ,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
  (CASE WHEN qs.statement_end_offset = -1 
  THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
  ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
  ,[Parent Query] = qt.text
  ,DatabaseName = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats as qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  WHERE total_clr_time <> 0
  ORDER BY [Average CLR Time] DESC;

--最常執行的查詢   
  SELECT TOP 10 
  [Execution count] = execution_count
  ,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
  (CASE WHEN qs.statement_end_offset = -1 
  THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
  ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
  ,[Parent Query] = qt.text
  ,DatabaseName = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Execution count] DESC;

--遭到封鎖的查詢   
  SELECT TOP 10 
  [Average Time Blocked] = (total_elapsed_time - total_worker_time) / 1000000.0 / qs.execution_count
  ,[Total Time Blocked] = (total_elapsed_time - total_worker_time) / 1000000.0 
  ,[Execution count] = qs.execution_count
  ,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
  (CASE WHEN qs.statement_end_offset = -1 
  THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
  ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) 
  ,[Parent Query] = qt.text
  ,DatabaseName = DB_NAME(qt.dbid)
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
  ORDER BY [Average Time Blocked] DESC;