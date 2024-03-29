-- 參考： https://stackify.com/performance-tuning-in-sql-server-find-slow-queries/


SELECT TOP 30
      qs.execution_count
    , qs.min_worker_time/1000000.0 as min_worker_time_in_S
    , qs.max_worker_time/1000000.0 as max_worker_time_in_S
    , qs.total_elapsed_time/1000000.0 as total_elapsed_time_in_S
    , qs.last_elapsed_time/1000000.0 as last_elapsed_time_in_S
    , SUBSTRING(qt.text
            , (qs.statement_start_offset/2)+1,
            ((CASE qs.statement_end_offset
                WHEN -1 THEN DATALENGTH(qt.text)
                        ELSE qs.statement_end_offset
                END - qs.statement_start_offset)/2)+1
            ) as sqltext
    , qs.total_logical_reads, qs.last_logical_reads
    , qs.total_logical_writes, qs.last_logical_writes
    , qs.total_worker_time
    , qs.last_worker_time
    , qs.last_execution_time
    , qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
order by qs.min_worker_time DESC -- CPU time
