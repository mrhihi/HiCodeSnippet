

-- https://ithelp.ithome.com.tw/articles/10079890
-- https://docs.microsoft.com/zh-tw/sql/relational-databases/system-dynamic-management-views/sys-dm-os-sys-memory-transact-sql?view=sql-server-ver15

SELECT
cpu_count AS [邏輯CPU數],
hyperthread_ratio AS [邏輯和實體處理器數目的比率],
cpu_count/hyperthread_ratio AS [實體CPU數],
physical_memory_kb/(1024) AS [實體記憶體MB]
FROM sys.dm_os_sys_info;



-- https://dba.stackexchange.com/questions/198045/how-to-get-the-cpu-speed-in-sql-server

DECLARE @outval VARCHAR(256)

EXEC master.sys.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',
                           @key = 'HARDWARE\DESCRIPTION\System\CentralProcessor\0',
                           @value_name = 'ProcessorNameString',
                           @value = @outval OUTPUT;

SELECT @outval AS [full_string], 
        SUBSTRING(@outval, CHARINDEX('@ ', @outval) + 1, LEN(@outval)) AS [speed_only]



-- https://dotblogs.com.tw/stanley14/2017/09/18/sqldm_os_host_info
--db
SELECT
 LEFT(@@VERSION, CHARINDEX('-', @@VERSION)-1) N'DB Version' , 
 SERVERPROPERTY('Edition') N'Edition',
 SERVERPROPERTY('ProductVersion') N'ProductVersion',
 SERVERPROPERTY('ProductLevel') N'ProductLevel',
 DATABASEPROPERTYEX('master','Version') N'Version'
