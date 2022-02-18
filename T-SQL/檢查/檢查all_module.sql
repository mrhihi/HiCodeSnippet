declare @objects table(name nvarchar(500), md5 varchar(100))

insert into @objects
select b.name, master.dbo.fn_varbintohexstr( master.sys.fn_repl_hash_binary(cast(a.definition as varbinary(max)))) from sys.all_sql_modules a 
join sys.all_objects b on a.object_id = b.object_id and b.schema_id in (select schema_id from sys.schemas where name='dbo')


--select * from sys.all_sql_modules where object_id = OBJECT_ID('dbo.EMP_EMPLOYEE', 'V')

select * from @objects


--declare @name nvarchar(500), @md5 varchar(100)

--DECLARE vendor_cursor CURSOR FOR
--select * from @objects

--OPEN vendor_cursor  

--FETCH NEXT FROM vendor_cursor   
--INTO @name, @md5  

--WHILE @@FETCH_STATUS = 0  
--BEGIN

--create table hihitest(name nvarchar(500), md5 varchar(100))


--    FETCH NEXT FROM vendor_cursor   
--    INTO @name, @md5
--END
--CLOSE vendor_cursor;  
--DEALLOCATE vendor_cursor; 