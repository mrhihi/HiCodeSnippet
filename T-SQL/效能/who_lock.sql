    declare @spid int,
            @bl int,
            @intTransactionCountOnEntry int,
            @intRowcount int,
            @intCountProperties int,
            @intCounter int,
            @hn nvarchar(max),
            @pn nvarchar(max),
            @hp nvarchar(max);


    declare @tmp_lock_who table
    (
        id int identity(1,1),
        spid smallint,
        bl smallint,
        hostname nchar(128),
        program_name nchar(128),
        hostprocess nchar(10)
    )


    IF @@ERROR<>0 begin 
        print @@ERROR
    end


    insert into @tmp_lock_who(spid,bl, hostname, program_name, hostprocess) select  0 ,blocked, hostname, program_name, hostprocess
        from (select * from sys.sysprocesses where  blocked>0 ) a 
        where not exists(select * from (select * from sys.sysprocesses where  blocked>0 ) b 
        where a.blocked=spid)
        union select spid,blocked, hostname, program_name, hostprocess from sys.sysprocesses where  blocked>0

    IF @@ERROR<>0 BEGIN
        print @@ERROR 
    end
    -- 找到臨時表的紀錄數
        select  @intCountProperties = Count(*),@intCounter = 1
        from @tmp_lock_who
        
    IF @@ERROR<>0 begin
        print @@ERROR
    end
        
    if @intCountProperties=0 begin
            select '\現在沒有阻塞和Dead Lock訊息\' as message
    end

    -- 循環開始
    while @intCounter <= @intCountProperties
    begin
    -- 取第一條紀錄
        select  @spid = spid,@bl = bl, @hn = rtrim(isnull(hostname,'')), @pn = rtrim(isnull(program_name,'')), @hp = rtrim(isnull(hostprocess,''))
        from @tmp_lock_who where id = @intCounter 
        begin
            if @spid =0 begin
                select '引起死結的SPID是: '+ CAST(@bl AS VARCHAR(10)) + ',(hostName:'+ isnull(@hn,'') +',programName:'+ isnull(@pn,'') +',hostProcess:'+ isnull(@hp,'') +'),其執行的SQL語法如下'
            end else begin
                select 'SPID：'+ CAST(@spid AS VARCHAR(10))+ '被' + 'SPID：'+ CAST(@bl AS VARCHAR(10)) +'阻塞'+ ',(hostName:'+ isnull(@hn,'') +',programName:'+ isnull(@pn,'') +',hostProcess:'+ isnull(@hp,'') +'),其當前執行的SQL語法如下'
            end
            DBCC INPUTBUFFER (@bl )
        end 
        set @intCounter = @intCounter + 1
    end
