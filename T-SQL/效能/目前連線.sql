--�ثe�s�u��
SELECT 'User Connections', cntr_value AS User_Connections FROM sys.sysperfinfo AS sp
WHERE sp.object_name='SQLServer:General Statistics'
AND sp.counter_name='User Connections'

--���椤���s�u��
SELECT 'Running Connection Count:', COUNT(1)
FROM sys.dm_exec_connections c left join sys.dm_exec_sessions s on c.session_id = s.session_id
where status='running'

--�s�u����
SELECT c.session_id, c.connect_time, s.login_time, c.client_net_address, s.login_name, s.status
FROM sys.dm_exec_connections c left join sys.dm_exec_sessions s on c.session_id = s.session_id
order by case status when 'running' then 1 when 'sleeping' then 2 when 'dormant' then 3 else 0 end, login_name, client_net_address

