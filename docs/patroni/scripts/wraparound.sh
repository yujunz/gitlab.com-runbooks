
#!/bin/bash 

###functions 
quit () { exit; }
help () {
               echo "Script for check wraparound status and generate FREEZE command " 
               echo "wraparound.sh  -m check -p 95"
               echo "options"
               echo " mode: -m check/generate (default check)"
               echo " size: -s size threshold of tables to check/generate (default 10000000000 [10GB])"
               echo " percent: -p % threshold of age (default 95 )"
               quit
           }

mode='check'
size=10000000000
percent=95

 
while getopts m:s:p:h option 
do 
 case "${option}" 
 in 
 m) mode=${OPTARG};; #mode check/generate
 s) size=${OPTARG};; #size threshold of tables
 p) percent=${OPTARG};; #% of age 
 h) help
 esac 
done 
 
echo "mode: "$mode, "size: "$size, "percent: "$percent 

if [ $mode = 'check' ]
then
query="WITH tabfreeze AS (
    SELECT pg_class.oid::regclass AS full_table_name,
    greatest(age(pg_class.relfrozenxid), age(toast.relfrozenxid)) as freeze_age,
    pg_total_relation_size(pg_class.oid),
    case
          when array_to_string(pg_class.reloptions, '') like '%autovacuum_freeze_max_age%' then regexp_replace(array_to_string(pg_class.reloptions, ''), '.*autovacuum_freeze_max_age=([0-9.]+).*', E'\\1')::int8
          else current_setting('autovacuum_freeze_max_age')::int8
        end as autovacuum_freeze_max_age
FROM pg_class JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
    LEFT OUTER JOIN pg_class as toast
        ON pg_class.reltoastrelid = toast.oid
WHERE nspname not in ('pg_catalog', 'information_schema')
    AND nspname NOT LIKE 'pg_temp%'
    AND pg_class.relkind = 'r'
)
SELECT full_table_name,  pg_size_pretty(pg_total_relation_size),freeze_age, (freeze_age*1)::bigint/(autovacuum_freeze_max_age/100) as "percent"
FROM tabfreeze
WHERE pg_total_relation_size >=  $size
AND (freeze_age*1)::bigint/(autovacuum_freeze_max_age/100)>=$percent
ORDER BY 4 DESC;
" 
sudo gitlab-psql -c "$query"
quit
fi

if [ $mode = 'generate' ]
then
query="WITH tabfreeze AS (
    SELECT pg_class.oid::regclass AS full_table_name,
    greatest(age(pg_class.relfrozenxid), age(toast.relfrozenxid)) as freeze_age,
    pg_total_relation_size(pg_class.oid),
    case
          when array_to_string(pg_class.reloptions, '') like '%autovacuum_freeze_max_age%' then regexp_replace(array_to_string(pg_class.reloptions, ''), '.*autovacuum_freeze_max_age=([0-9.]+).*', E'\\1')::int8
          else current_setting('autovacuum_freeze_max_age')::int8
        end as autovacuum_freeze_max_age
FROM pg_class JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
    LEFT OUTER JOIN pg_class as toast
        ON pg_class.reltoastrelid = toast.oid
WHERE nspname not in ('pg_catalog', 'information_schema')
    AND nspname NOT LIKE 'pg_temp%'
    AND pg_class.relkind = 'r'
)
SELECT 'VACUUM FREEZE ANALYZE '|| full_table_name||'; select pg_sleep(2);' as command
FROM tabfreeze
WHERE pg_total_relation_size >   $size
AND (freeze_age*1)::bigint/(autovacuum_freeze_max_age/100)>= $percent
ORDER BY (freeze_age*1)::bigint/(autovacuum_freeze_max_age/100) DESC;
"
sudo gitlab-psql -c "$query"
quit
fi

help 





