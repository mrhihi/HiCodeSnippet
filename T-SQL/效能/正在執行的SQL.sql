--參考資料： https://blog.miniasp.com/post/2010/10/13/How-to-get-current-executing-statements-in-SQL-Server.aspx

SELECT      r.scheduler_id as 排程器識別碼,
            status         as 要求的狀態,
            r.session_id   as SPID,
            r.blocking_session_id as BlkBy,
            substring(
				ltrim(q.text),
				r.statement_start_offset/2+1,
				(CASE
                 WHEN r.statement_end_offset = -1
                 THEN LEN(CONVERT(nvarchar(MAX), q.text)) * 2
                 ELSE r.statement_end_offset
                 END - r.statement_start_offset)/2)
                 AS [正在執行的 T-SQL 命令],
            r.cpu_time      as [CPU Time(ms)],
            r.start_time    as [開始時間],
            r.total_elapsed_time as [執行總時間],
            r.reads              as [讀取數],
            r.writes             as [寫入數],
            r.logical_reads      as [邏輯讀取數],
            -- q.text, /* 完整的 T-SQL 指令碼 */
            d.name               as [資料庫名稱]
FROM        sys.dm_exec_requests r 
			CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS q
			LEFT JOIN sys.databases d ON (r.database_id=d.database_id)
WHERE       r.session_id > 50 AND r.session_id <> @@SPID
ORDER BY    r.total_elapsed_time desc