--看 disk I/O 平均超過 20ms 就不好
--https://www.facebook.com/mrhihi/posts/10154552186115849
--Measuring Disk IO performance for SQL Servers
SELECT
*
,wait_time_ms/waiting_tasks_count AS 'Avg Wait in ms'
FROM
sys.dm_os_wait_stats 
WHERE
waiting_tasks_count > 0
ORDER BY
wait_time_ms DESC

-- Calculates average stalls per read, per write, and per total input/output
-- for each database file.
SELECT  DB_NAME(database_id) AS [Database Name] ,
        file_id ,
        io_stall_read_ms ,
        num_of_reads ,
        CAST(io_stall_read_ms / ( 1.0 + num_of_reads ) AS NUMERIC(10, 1)) AS [avg_read_stall_ms] ,
        io_stall_write_ms ,
        num_of_writes ,
        CAST(io_stall_write_ms / ( 1.0 + num_of_writes ) AS NUMERIC(10, 1)) AS [avg_write_stall_ms] ,
        io_stall_read_ms + io_stall_write_ms AS [io_stalls] ,
        num_of_reads + num_of_writes AS [total_io] ,
        CAST(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads
                                                          + num_of_writes ) AS NUMERIC(10,
                                                              1)) AS [avg_io_stall_ms]
FROM    sys.dm_io_virtual_file_stats(NULL, NULL)
where DB_NAME(database_id) like 'ESB%'
ORDER BY avg_io_stall_ms DESC;