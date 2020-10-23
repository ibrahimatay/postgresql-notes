-- Ref:https://www.postgresql.org/docs/9.1/information-schema.html

SELECT * FROM information_schema.tables WHERE table_schema='<schema name>' -- get tables
SELECT * FROM information_schema.columns WHERE table_name='<table name>' -- get table columns

select 
    c.table_schema,
    c.table_name,
    c.column_name,
    c.ordinal_position,
    c.column_default,
    c.data_type,
    d.description
from information_schema.columns c
inner join pg_class c1 on c.table_name=c1.relname
inner join pg_catalog.pg_namespace n on c.table_schema=n.nspname
and c1.relnamespace=n.oid left join pg_catalog.pg_description d on d.objsubid=c.ordinal_position and d.objoid=c1.oid
where c.table_name='<table name>'
and c.table_schema='<schema name>' -- get column description
