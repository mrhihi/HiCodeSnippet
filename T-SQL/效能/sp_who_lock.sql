USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_who_lock]    Script Date: 2016/10/5 下午 06:55:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  procedure [dbo].[sp_who_lock]
as
begin
		declare @spid int,
				@bl int,
				@intTransactionCountOnEntry int,
				@intRowcount int,
				@intCountProperties int,
				@intCounter int;
	

		 create table #tmp_lock_who 
		 (
		 id int identity(1,1),
		 spid smallint,
		 bl smallint)
		 
		 		 
		 IF @@ERROR<>0 RETURN @@ERROR
		 
		 insert into #tmp_lock_who(spid,bl) select  0 ,blocked
		   from (select * from sysprocesses where  blocked>0 ) a 
		   where not exists(select * from (select * from sysprocesses where  blocked>0 ) b 
		   where a.blocked=spid)
		   union select spid,blocked from sysprocesses where  blocked>0

		 IF @@ERROR<>0 RETURN @@ERROR 
		  
		-- 找到臨時表的紀錄數
		 select  @intCountProperties = Count(*),@intCounter = 1
		 from #tmp_lock_who
		 
		 IF @@ERROR<>0 RETURN @@ERROR 
		 
		 if @intCountProperties=0
		  select '\現在沒有阻塞和Dead Lock訊息\' as message

		
		-- 循環開始
		while @intCounter <= @intCountProperties
		begin
		-- 取第一條紀錄
		  select  @spid = spid,@bl = bl
		  from #tmp_lock_who where id = @intCounter 
		 begin
		  if @spid =0 
					select '引起死結的SPID是: '+ CAST(@bl AS VARCHAR(10)) + ',其執行的SQL語法如下'
		 else
			select 'SPID：'+ CAST(@spid AS VARCHAR(10))+ '被' + 'SPID：'+ CAST(@bl AS VARCHAR(10)) +'阻塞,其當前執行的SQL語法如下'
		 DBCC INPUTBUFFER (@bl )
		 end 

		 set @intCounter = @intCounter + 1
		end

		drop table #tmp_lock_who

		return 0
end