declare @lookDB table (dbname varchar(100))
insert into @lookDB select 'HR31_RADAR_E'

declare @lockinfo table( spid int, dbName varchar(200), ObjId int,
    TableName varchar(200), IndId int, [Type] varchar(4), 
    [Resource] varchar(32), [Mode] varchar(8), [Status] varchar(5)
)
-- 取得被鎖定資源的資訊
    insert into @lockinfo
    select
        convert (smallint, req_spid) As spid,
        d.name,
        rsc_objid As ObjId,
        isnull(t.name,'') As TableName ,
        rsc_indid As IndId,
        substring (v.name, 1, 4) As Type,
        substring (rsc_text, 1, 32) as Resource,
        substring (u.name, 1, 8) As Mode,
        substring (x.name, 1, 5) As Status
    from sys.syslockinfo a
        join master.dbo.spt_values v on a.rsc_type = v.number and v.type = 'LR'
        join master.dbo.spt_values x on a.req_status = x.number and x.type = 'LS'
        join master.dbo.spt_values u on a.req_mode + 1 = u.number and u.type = 'L'
        join sys.databases d on a.rsc_dbid = d.database_id
        left join sys.tables t on a.rsc_objid = t.object_id and substring (v.name, 1, 4) in ('KEY','TAB')
    where substring (u.name, 1, 8) like '%X%'
    and d.name in (select dbname from @lookDB)

-- 取得鎖定資源的 spid 的資訊
SELECT
      d.transaction_begin_time
    , datediff(second, d.transaction_begin_time, getdate()) as tot_tran_second
    , a.login_time AS [Login Time]
    , a.program_name AS [Application]
    , a.spid AS [Process ID]
    , a.status AS [Status]
    , a.hostname AS [Host Name]
    , a.hostprocess AS [Host Process]
    , a.loginame AS [User], a.open_tran AS [Open Trans], a.cmd AS [Command]
    , a.blocked AS [Blocked], CONVERT(VARCHAR(19), a.waittime) AS [Wait Time]
    , [Waiting] =Case a.waittype
                 WHEN 0x0000 THEN SPACE(256) Else a.waitresource END
    , (SELECT [text] FROM sys.dm_exec_sql_text(a.sql_handle)) AS SqlCommand
FROM sys.sysprocesses a WITH (NOLOCK)
left join sys.dm_exec_sessions b on a.spid = b.session_id
left join sys.dm_tran_session_transactions c on a.spid = c.session_id
left join sys.dm_tran_active_transactions d on c.transaction_id = d.transaction_id
where exists (select 'x' from @lockinfo b where a.spid = b.spid )
order by a.spid, d.transaction_begin_time

-- 被鎖定資源的內容
select distinct spid, dbName, TableName, [Type], Mode, [Status] from @lockinfo order by spid

