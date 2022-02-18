SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

create procedure spConvertIF2TF 
/*
-- =============================================
-- Author:		<mrhihi>
-- Create date: <2015.09.25>
-- Description:	<�N Inline Table value UDF �ഫ�� Table value UDF>
-- History:     <2015.09.25>	[V1.0] New Create
-- Ex.	
			
    exec spConvertIF2TF @udfName='fnGetPayrollRuleParam'
	
-- =============================================
*/
(
    @udfName varchar(1000)
) as
begin
    set nocount on;

    declare @oid int; select @oid = object_id(@udfName);
    declare @oname nvarchar(max); select @oname = object_name(@oid);

    declare @CRLF nvarchar(max); set @CRLF = char(13)+char(10);
    declare @TMPTBLNAME nvarchar(max); set @TMPTBLNAME = '@result_if2tf';
    declare @NEWLINETAG nvarchar(max); set @NEWLINETAG='[NEWLINE]';

    begin /** �ˬd��J�ѼƬO�_�X�k */
        if (not exists (select id from sysobjects where xtype = 'IF' and id = @oid)) begin
            print @oname + ' ���O Inline Table ���A�� UDF! �N���|�B�z�ഫ!';
            return;
        end
        if (isnull(@oname, '')='') begin
            print @oid + ' �䤣��Ӫ���!';
            return;
        end
    end

    begin /** �X�� udf sql �y�k(�]���@���u�O 8000 ���A�W�����|�Q���n�X��) */
        declare @i int = 0;
        declare @body nvarchar(4000); select @body=''
        declare @maxbody nvarchar(max); select @maxbody='';

        while (@body is not null) begin
            select @i = @i + 1, @body = null
            select @body = text from syscomments where id = @oid and colid = @i

            if (@body is null) Break
            select @maxbody = @maxbody + convert(nvarchar(max), @body)

        end
    end

    begin /** ���o udf �^�� table �� layout */
        declare @resultSchema varchar(8000)
        select @resultSchema = replace(stuff((select ',' + Sql + @NEWLINETAG from fnHelp2(@oid) for xml path('')), 1, 1,''),@NEWLINETAG, @CRLF)
    end

    declare @tempbody nvarchar(max); select @tempbody=''

    begin /** �� returns as �������J table layout */
        declare @pos1 int, @pos2 int;
        select @tempbody = upper(@maxbody);
        select @pos1 = charindex('RETURNS', @tempbody);
        if (@pos1>0)begin
            select @pos2 = charindex('AS', @tempbody, @pos1+7)
            if (@pos2>0) begin 

                select @maxbody = substring(@maxbody, 0, @pos1+7) + ' '+ @TMPTBLNAME +' TABLE ' + '('+ @resultSchema +')' + substring(@maxbody, @pos2, datalength(@maxbody))
                select @tempbody = substring(@tempbody, 0, @pos1+7) + ' '+ @TMPTBLNAME +' TABLE ' + '('+ @resultSchema +')' + substring(@tempbody, @pos2, datalength(@tempbody))
            end
        end
    end

    begin /** �B�z Inline table �}�Y�� "return (" �令 begin �� insert into */
        declare @pos3 int, @pos4 int;
        select @pos3 = charindex('RETURN', @tempbody, @pos2 + 2);
        if (@pos3>0) begin
            select @pos4 = charindex('(', @tempbody, @pos3);
            if (@pos4 >0) begin
                select @maxbody = substring(@maxbody, 0, @pos3-1) + ' BEGIN ' + @CRLF + 'insert into '+ @TMPTBLNAME +'' + substring(@maxbody, @pos4+1, datalength(@maxbody)) + @CRLF + 'end'
                select @tempbody = substring(@tempbody, 0, @pos3-1) + ' BEGIN ' + @CRLF + 'insert into '+ @TMPTBLNAME +'' + substring(@tempbody, @pos4+1, datalength(@tempbody)) + @CRLF + 'end'
            end
        end
    end

    begin /** �B�z�̫᪺�A�� ")" */
        select @tempbody = reverse(@maxbody);
        declare @pos5 int, @pos6 int;
        select @pos5 = charindex('dne', @tempbody);
        if (@pos5>0) begin
            select @pos6 = charindex(')', @tempbody, @pos5+3)
            if (@pos6>0) begin
                select @maxbody = substring(@maxbody, 0, len(@maxbody)-@pos6+1) + @CRLF + 'return' + @CRLF + 'end'
            end
        end
    end

    -- select @maxbody+'' for xml path('');

    BEGIN TRY
        begin tran
            exec ('drop function ' + @oname + @CRLF)
            exec (@maxbody)
        commit
        print @oname + ' �q IF �ഫ�� TF ����!';
    END TRY
    BEGIN CATCH
        rollback
        declare @errmsg nvarchar(4000); set @errmsg = @oname + ' �q TF �ഫ�� IF ����!' + @CRLF+ @CRLF + ERROR_MESSAGE();
        print @errmsg;
    END CATCH

end
GO
