select b.name as tableName
     , a.type_desc
     , a.name as indexName
     , stuff((select ', ' + xc.name + case x.is_descending_key when 0 then '' else ' DES' end
          from sys.index_columns x 
          join sys.columns xc on x.object_id = xc.object_id and x.column_id = xc.column_id
         where a.object_id = x.object_id
                and a.index_id = x.index_id
            order by x.key_ordinal
            for xml path('')
        ),1,2,'') as indexKeys
  from sys.indexes a
  join sys.tables b on a.object_id = b.object_id 
        and b.schema_id in (schema_id('dbo'), schema_id('Envers'))
        and a.name is not null
    order by b.name
