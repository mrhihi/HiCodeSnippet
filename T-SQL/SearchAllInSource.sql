/*
 * 尋找指定文字出現的行數
 */
    set nocount on;
    declare 
    @name nvarchar(4000) = ''        -- SQL 物件名稱 (預設空白查全部)
    , @ignoreCase bit = 0           -- 0: 不忽略大小寫        1: 忽略大小寫
    , @printLine bit = 1            -- 0: 顯示關鍵字到行尾    1: 顯示整行

    DECLARE @SEARCHSTRING1 NVARCHAR(4000)
           ,@SEARCHSTRING2 NVARCHAR(4000)
           ,@SEARCHSTRING3 NVARCHAR(4000)

    select @SEARCHSTRING1 = 'GrossIncome'
          ,@SEARCHSTRING2 = null
          ,@SEARCHSTRING3 = null

    /*
     * sysobjects
     */
    declare @sysobjects table (
        name sysname,
        id int,
        [type] nvarchar(50) COLLATE database_default
        primary key (id)
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

    IF OBJECT_ID(N'tempdb..#definitions') IS NOT NULL Drop table #definitions
    create table #definitions (
        id int,
        [name] sysname,
        [type] nvarchar(50) collate database_default,
        [line] int,
        [text] nvarchar(1000) COLLATE database_default
        primary key(id, [line])
    )

    declare @CRLF varchar(2) = char(13)+char(10)
          , @CR varchar(1) = CHAR(13)
          , @LF varchar(1) = CHAR(10)

    declare @LFPOS int, @lastLFPOS int, @line int
    declare @found1_idx int, @found2_idx int, @found3_idx int
    declare @found_str nvarchar(1000)

    declare @objectid int
          , @text nvarchar(max)

    DECLARE vend_cursor CURSOR  
    FOR select object_id, 
           REPLACE(REPLACE([definition],@CRLF , @LF), @CR, @LF) as text
        from sys.sql_modules a
        where exists (select 'x' from @sysobjects x where a.object_id = x.id)

    OPEN vend_cursor  
    FETCH NEXT FROM vend_cursor INTO @objectid, @text
    WHILE @@FETCH_STATUS = 0  
    BEGIN

        -- 先找一次，有找到再切，沒找到就 pass
        if @ignoreCase = 1 begin
            select @found1_idx = CHARINDEX(@SEARCHSTRING1, @text collate chinese_taiwan_stroke_ci_as)
                 , @found2_idx = CHARINDEX(@SEARCHSTRING2, @text collate chinese_taiwan_stroke_ci_as)
                 , @found3_idx = CHARINDEX(@SEARCHSTRING3, @text collate chinese_taiwan_stroke_ci_as)
        end else begin
            select @found1_idx = CHARINDEX(@SEARCHSTRING1, @text collate chinese_taiwan_stroke_cs_as)
                 , @found2_idx = CHARINDEX(@SEARCHSTRING2, @text collate chinese_taiwan_stroke_cs_as)
                 , @found3_idx = CHARINDEX(@SEARCHSTRING3, @text collate chinese_taiwan_stroke_cs_as)    
        end

        if (@found1_idx > 0 or @found2_idx > 0 or @found3_idx > 0)
        begin

            select @LFPOS = charindex(@LF, @text, 0), @lastLFPOS = 0, @line = 0
            while(@LFPOS) > 0
            begin
                set @line = @line + 1
                set @found_str = substring(@text, @lastLFPOS, @LFPOS - @lastLFPOS)
                -- 每一行找，找到才寫
                if @ignoreCase = 1 begin
                    select @found1_idx = CHARINDEX(@SEARCHSTRING1, @found_str collate chinese_taiwan_stroke_ci_as)
                         , @found2_idx = CHARINDEX(@SEARCHSTRING2, @found_str collate chinese_taiwan_stroke_ci_as)
                         , @found3_idx = CHARINDEX(@SEARCHSTRING3, @found_str collate chinese_taiwan_stroke_ci_as)
                end else begin
                    select @found1_idx = CHARINDEX(@SEARCHSTRING1, @found_str collate chinese_taiwan_stroke_cs_as)
                         , @found2_idx = CHARINDEX(@SEARCHSTRING2, @found_str collate chinese_taiwan_stroke_cs_as)
                         , @found3_idx = CHARINDEX(@SEARCHSTRING3, @found_str collate chinese_taiwan_stroke_cs_as)
                end

                if (@found1_idx > 0 or @found2_idx > 0 or @found3_idx > 0)
                begin
                    insert into #definitions(id, [name], [type], [line], [text])
                    select @objectid, a.[name], a.[type], @line, @found_str
                    from @sysobjects a where a.id = @objectid

                end
                select  @lastLFPOS = @LFPOS ,
                        @LFPOS = charindex(@LF, @text, @LFPOS+1)
            end

        end
        FETCH NEXT FROM vend_cursor INTO @objectid, @text
    END
    CLOSE vend_cursor;  
    DEALLOCATE vend_cursor; 

    select *
    from #definitions a
    order by a.id, a.[line]
