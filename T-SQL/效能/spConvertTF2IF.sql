SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

create procedure spConvertTF2IF 
/*
-- =============================================
-- Author:		<mrhihi>
-- Create date: <2015.09.25>
-- Description:	<�N Table value UDF �ഫ�� Inline Table value UDF>
-- History:     <2015.09.25>	[V1.0] New Create
-- Ex.	
			
    exec spConvertTF2IF @udfName='fnGetPayrollRuleParam'
	
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

    if (not exists (select id from sysobjects where xtype = 'TF' and id = @oid)) begin
        print @oname + ' ���O Table value ���A�� UDF! �N���|�B�z�ഫ!';
        return;
    end
    if (isnull(@oname, '')='') begin
        print @oid + ' �䤣��Ӫ���!';
        return;
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

    declare @tempbody nvarchar(max); select @tempbody=''

    begin /** �B�z�}�Y�� returns result_if2tf as */
        declare @pos1 int, @pos2 int, @pos3 int;
        select @tempbody = upper(@maxbody);
        select @pos1 = charindex('RETURNS', @tempbody);
        if (@pos1>0) begin
            select @pos2 = charindex(@TMPTBLNAME, @maxbody, @pos1+7)
            if (@pos2>0) begin
                select @pos3 = charindex(@TMPTBLNAME, @maxbody, @pos2+len(@TMPTBLNAME))
                if (@pos3>0) begin
                    select @maxbody = substring(@maxbody, 0, @pos1+7) + ' TABLE AS RETURN( ' + substring(@maxbody, @pos3+len(@TMPTBLNAME), datalength(@maxbody))
                    select @tempbody = substring(@tempbody, 0, @pos1+7) + ' TABLE AS RETURN( ' + substring(@tempbody, @pos3+len(@TMPTBLNAME), datalength(@tempbody))
                end
            end else begin
                print @oname + ' ���O�ϥ� spConvertIF2TF �ഫ�L�� UDF �A�N���|�B�z�ഫ!'
                return;
            end
        end
    end

    begin /** �B�z�̫᪺ return end */
        select @tempbody = reverse(@tempbody);
        declare @pos4 int, @pos5 int;
        select @pos4 = charindex('DNE', @tempbody)
        if (@pos4>0) begin
            select @pos5 = charindex('NRUTER', @tempbody, @pos4+3)
            if (@pos5>0) begin
                select @maxbody = substring(@maxbody, 0, len(@maxbody)-@pos5-6+1) + ')'
            end
        end
    end

    -- select @maxbody+'' for xml path('');

    BEGIN TRY
        begin tran
            exec ('drop function ' + @oname + @CRLF)
            exec (@maxbody)
        commit
        print @oname + ' �q TF �ഫ�� IF ����!';
    END TRY
    BEGIN CATCH
        rollback
        declare @errmsg nvarchar(4000); set @errmsg = @oname + ' �q TF �ഫ�� IF ����!' + @CRLF+ @CRLF + ERROR_MESSAGE();
        print @errmsg;
    END CATCH
end
GO
