/*
 * 尋找文字第一次出現的位置
 */
declare 
    @name nvarchar(max) = ''        -- SQL 物件名稱 (預設空白查全部)
    , @ignoreCase bit = 0           -- 0: 不忽略大小寫        1: 忽略大小寫
    , @printLine bit = 1            -- 0: 顯示關鍵字到行尾    1: 顯示整行

    DECLARE @SEARCHSTRING1 NVARCHAR(MAX)
           ,@SEARCHSTRING2 NVARCHAR(MAX)
           ,@SEARCHSTRING3 NVARCHAR(MAX)

    select @SEARCHSTRING1 = 'fnTranOTHR'
          ,@SEARCHSTRING2 = null
          ,@SEARCHSTRING3 = null

    /*
     * sysobjects
     */
    declare @sysobjects table (
        name sysname,
        id int,
        [type] nvarchar(50) COLLATE database_default
    )

    -- https://msdn.microsoft.com/zh-tw/library/ms177596.aspx
    insert into @sysobjects(name, id, [type])
    select name, id, CASE WHEN xtype = 'P' THEN 'Stored Proc'
                        WHEN xtype = 'TF' THEN 'Table Function'
                        WHEN xtype = 'TR' THEN 'Trigger'
                        WHEN xtype = 'FN' THEN 'UDF'
                        ELSE xtype 
                END 
      from sysobjects
     where category = 0
       and (len(isnull(@name,''))=0 or charindex(upper(@name), upper(sysobjects.name))>0)
       --and sysobjects.name not like 'TRI[_]EN%'

    /*
     * syscomments
     */
    declare @syscomments table(
        id int,
        [text] nvarchar(max) COLLATE database_default,
        -- 關鍵字位置
        idx1 int,  idx2 int, idx3 int,
        line1 int, line2 int, line3 int,
        -- 關鍵字後第一個換行符號位置
        idx1_end int, idx2_end int, idx3_end int,
        -- substring 要用的
        idx1_takestar int, idx2_takestar int, idx3_takestar int,
        idx1_takelen int, idx2_takelen int, idx3_takelen int,
        primary key (id)
    )
    declare @CRLF varchar(2) = char(13)+char(10)
          , @CR varchar(1) = CHAR(13)
          , @LF varchar(1) = CHAR(10)
    insert into @syscomments(id, [text])
    select object_id, 
           REPLACE(REPLACE([definition],@CRLF , @LF), @CR, @LF) as text
      from sys.sql_modules a
      where exists (select 'x' from @sysobjects x where a.object_id = x.id)

    if @ignoreCase = 1 begin
        update @syscomments
           set idx1 = CHARINDEX(@SEARCHSTRING1, [text] collate chinese_taiwan_stroke_ci_as),
               idx2 = CHARINDEX(@SEARCHSTRING2, [text] collate chinese_taiwan_stroke_ci_as),
               idx3 = CHARINDEX(@SEARCHSTRING3, [text] collate chinese_taiwan_stroke_ci_as)
    end else begin
        update @syscomments
           set idx1 = CHARINDEX(@SEARCHSTRING1, [text] collate chinese_taiwan_stroke_cs_as),
               idx2 = CHARINDEX(@SEARCHSTRING2, [text] collate chinese_taiwan_stroke_cs_as),
               idx3 = CHARINDEX(@SEARCHSTRING3, [text] collate chinese_taiwan_stroke_cs_as)
    end

    update @syscomments
       set -- 關鍵字後的第一個換行符號的位置
           idx1_end = charindex(@LF, [text], idx1),
           idx2_end = charindex(@LF, [text], idx2),
           idx3_end = charindex(@LF, [text], idx3),
           -- 計算行數
           line1 = case when idx1=0 then 0 else idx1 - len(replace(substring([text], 1, idx1),@LF,'')) + 1 end,
           line2 = case when idx2=0 then 0 else idx2 - len(replace(substring([text], 1, idx2),@LF,'')) + 1 end,
           line3 = case when idx3=0 then 0 else idx3 - len(replace(substring([text], 1, idx3),@LF,'')) + 1 end
    where (idx1 >0 or  idx2 > 0 or idx3 > 0) 

    if @printLine = 1 begin
        update b
           set idx1_takestar = a.idx1_takestar
             , idx2_takestar = a.idx2_takestar
             , idx3_takestar = a.idx3_takestar
             , idx1_takelen = case idx1_end when 0 then a.idx1 - a.idx1_takestar else idx1_end - a.idx1_takestar end
             , idx2_takelen = case idx2_end when 0 then a.idx2 - a.idx2_takestar else idx2_end - a.idx2_takestar end
             , idx3_takelen = case idx3_end when 0 then a.idx3 - a.idx3_takestar else idx3_end - a.idx3_takestar end
           from (
                select len(rs1) - charindex(@LF, rs1) + 2 as idx1_takestar ,
                       len(rs2) - charindex(@LF, rs2) + 2 as idx2_takestar ,
                       len(rs3) - charindex(@LF, rs3) + 2 as idx3_takestar ,
                       aa.idx1, aa.idx2, aa.idx3,
                       aa.id
                from (select case idx1 when 0 then '' else reverse(substring([text], 1, idx1)) end as rs1,
                             case idx2 when 0 then '' else reverse(substring([text], 1, idx2)) end as rs2,
                             case idx3 when 0 then '' else reverse(substring([text], 1, idx3)) end as rs3,
                             idx1, idx2, idx3,
                             id
                    from @syscomments
                ) aa
           ) a
           join @syscomments b on a.id = b.id

    end else begin
        update @syscomments
           set idx1_takestar = idx1 ,
               idx2_takestar = idx2 ,
               idx3_takestar = idx3 ,
               idx1_takelen = case when idx1_end=0 then len([text])-idx1 else idx1_end - idx1 end + 1,
               idx2_takelen = case when idx2_end=0 then len([text])-idx2 else idx2_end - idx2 end + 1,
               idx3_takelen = case when idx3_end=0 then len([text])-idx3 else idx3_end - idx3 end + 1
    end


    select b.name, 
        b.[type],
        a.line1,
        case when idx1>0 then SUBSTRING([text], idx1_takestar, idx1_takelen) else '' end as [SEARCHSTRING1],
        a.line2,
        case when idx2>0 then SUBSTRING([text], idx2_takestar, idx2_takelen) else '' end as [SEARCHSTRING2],
        a.line3,
        case when idx3>0 then SUBSTRING([text], idx3_takestar, idx3_takelen) else '' end as [SEARCHSTRING3]
      from @syscomments a 
      join @sysobjects b on a.id = b.id
      where (idx1 >0 or  idx2 > 0 or idx3 > 0) 
      order by b.[type], b.name
