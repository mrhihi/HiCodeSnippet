--�ѦҸ�ơG https://blog.miniasp.com/post/2010/10/13/How-to-get-current-executing-statements-in-SQL-Server.aspx

SELECT      r.scheduler_id as �Ƶ{���ѧO�X,
            status         as �n�D�����A,
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
                 AS [���b���檺 T-SQL �R�O],
            r.cpu_time      as [CPU Time(ms)],
            r.start_time    as [�}�l�ɶ�],
            r.total_elapsed_time as [�����`�ɶ�],
            r.reads              as [Ū����],
            r.writes             as [�g�J��],
            r.logical_reads      as [�޿�Ū����],
            -- q.text, /* ���㪺 T-SQL ���O�X */
            d.name               as [��Ʈw�W��]
FROM        sys.dm_exec_requests r 
			CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS q
			LEFT JOIN sys.databases d ON (r.database_id=d.database_id)
WHERE       r.session_id > 50 AND r.session_id <> @@SPID
ORDER BY    r.total_elapsed_time desc