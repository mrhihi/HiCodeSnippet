-- 參考資料： https://technet.microsoft.com/en-us/library/jj643251.aspx?f=255&MSPPError=-2147217396

-- Calculates average stalls per read, per write, and per total input/output
-- for each database file.
SELECT DB_NAME(database_id) AS [Database Name] , file_id , io_stall_read_ms , num_of_reads , CAST(io_stall_read_ms / ( 1.0 + num_of_reads ) AS NUMERIC(10, 1)) AS [avg_read_stall_ms] , io_stall_write_ms , num_of_writes ,
CAST(io_stall_write_ms / ( 1.0 + num_of_writes ) AS NUMERIC(10, 1)) AS [avg_write_stall_ms] , io_stall_read_ms + io_stall_write_ms AS [io_stalls] , num_of_reads + num_of_writes AS [total_io] , CAST(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads
+ num_of_writes) AS NUMERIC(10,1)) AS [avg_io_stall_ms]FROM sys.dm_io_virtual_file_stats(NULL, NULL)ORDER BY avg_io_stall_ms DESC ;


-- Look at pending I/O requests by file
SELECT DB_NAME(mf.database_id) AS [Database] , mf.physical_name ,r.io_pending , r.io_pending_ms_ticks , r.io_type , fs.num_of_reads , fs.num_of_writes
FROM sys.dm_io_pending_io_requests AS r 
INNER JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS fs ON r.io_handle = fs.file_handle 
INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
AND fs.file_id = mf.file_id
ORDER BY r.io_pending , r.io_pending_ms_ticks DESC ;


