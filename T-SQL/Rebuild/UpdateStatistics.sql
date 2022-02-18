DECLARE @sqls NVARCHAR(500)

DECLARE db_cursor CURSOR FOR
select 'UPDATE STATISTICS '+SCHEMA_NAME(schema_id)+'.'+[name]+';' 
from sys.tables where schema_id in (SCHEMA_ID('dbo'), SCHEMA_ID('Envers'))

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @sqls

WHILE @@FETCH_STATUS = 0
BEGIN
    begin TRY
        print 'Executing: ' + @sqls
        exec ( @sqls )
    end TRY
    begin CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);  
        DECLARE @ErrorSeverity INT;  
        DECLARE @ErrorState INT;  

        SET @ErrorMessage = ERROR_MESSAGE();  
        SET @ErrorSeverity = ERROR_SEVERITY();  
        SET @ErrorState = ERROR_STATE();  

        -- Use RAISERROR inside the CATCH block to return error  
        -- information about the original error that caused  
        -- execution to jump to the CATCH block.  
        RAISERROR (@ErrorMessage, -- Message text.  
                    @ErrorSeverity, -- Severity.  
                    @ErrorState -- State.  
                    ); 
    end catch;
    FETCH NEXT FROM db_cursor INTO @sqls
END

CLOSE db_cursor
DEALLOCATE db_cursor
GO

