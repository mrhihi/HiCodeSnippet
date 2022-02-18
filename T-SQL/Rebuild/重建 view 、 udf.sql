declare @rebuildSP bit = 0; -- 是否連 stored procedure 都要重建(refresh + recompile)
DECLARE c CURSOR
FOR
    SELECT  name, type
    FROM    sys.objects
    WHERE   (type_desc ='VIEW' OR  type IN ('FN','TF','IF','P'))
    AND name NOT IN ('fnGetEmailList4TaxReturnLoop')
    and lower(schema_name(schema_id)) in ('dbo','envers')
    and ( ( @rebuildSP = 0 and [type] <> 'P' )
        or 
          ( @rebuildSP = 1)
        )

OPEN c;
DECLARE @objName VARCHAR(500);
DECLARE @type VARCHAR(500);
FETCH NEXT FROM c INTO @objName, @type;
WHILE @@fetch_status = 0
    BEGIN
        BEGIN TRY
            --PRINT '執行:' + @objName
            IF @type = 'VIEW' BEGIN
                EXEC sp_refreshView @objName;
            END ELSE IF @type = 'P' begin
                EXEC sp_refreshsqlmodule @objName;
                EXEC sp_recompile @objName;
            END ELSE BEGIN
                EXEC sp_refreshsqlmodule @objName;
            END
        END TRY
        BEGIN CATCH
            PRINT '失敗:' + @objName;

            -- 這邊不做 rollback 有可能會造成 trnas 未結束。
            -- Roll back any active or uncommittable transactions before
            -- inserting information in the ErrorLog.
            IF XACT_STATE() <> 0
            BEGIN
                ROLLBACK;
            END

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

        END CATCH;
        FETCH NEXT FROM c INTO @objName, @type;
    END;
CLOSE c;
DEALLOCATE c;

--sp_refreshsqlmodule @name='fnCalHealthPremium'
--SELECT * FROM sys.objects WHERE name = 'fnCalHealthPremium'

--SELECT DISTINCT type,type_desc FROM sys.objects WHERE type_desc LIKE '%FUNCTION%'


--SELECT name AS function_name
--,SCHEMA_NAME(schema_id) AS schema_name
--,type_desc
--FROM sys.objects
--WHERE type_desc LIKE '%FUNCTION%';
--GO

--SELECT * FROM sys.objects WHERE type = 'V'