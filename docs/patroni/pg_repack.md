# Pg_repack using gitlab-pgrepack

[gitlab-pgrepack](https://gitlab.com/gitlab-com/gl-infra/gitlab-pgrepack.git) is a helper tool for running pg_repack in Gitlab environments. It is open source and works on top of the [pg_repack PostgreSQL](https://github.com/reorg/pg_repack) extension.

## What is bloat?
Bloat can be seen as the "remains" of UPDATE and DELETE activity. When a row is updated, postgreSQL uses temporary extra "rows" to do this job. After transaction finish, that transient row/s are what a so call "dead rows", and the accumulation of dead rows is called "bloat", and affect tables and indexes too.

## Why pg_repack?
VACUUM is a standard tool that can be used to clean dead rows. But, as opposed to `autovacuum`, VACUUM uses locks more aggresively to do his job, and can interfere with regular database activity. `Pg_repack` uses a model that requires minimal locks, suitable for database with high and concurrent activity.

## Prerequisites

- Request an auth token for Grafana annotations and modify `auth_key` accordingly.


## Setting up the tool

At the time of this writing, the `gitlab-repack` tool is available at _/var/opt/gitlab/postgresql/gitlab-pgrepack/bin/gitlab-pgrepack_.
If needed, you can install it manually in your $HOME as follows:

```

cd $HOME

gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

curl -sSL https://get.rvm.io | bash -s stable --ruby

source ~/.rvm/scripts/rvm


git clone https://gitlab.com/gitlab-com/gl-infra/gitlab-pgrepack.git
cd gitlab-pgrepack
bundle update --bundler
bundle install 

## Configure gitlab-pgrepack

The configuration file is located at `/var/opt/gitlab/postgresql/gitlab-pgrepack/config/gitlab-repack.yml`. Main parameters to check/modify are:

- host: must point to the cluster leader
- ratio_threshold: Estimation of "how much bloat" is needed to be considered a `gitlab-repack` target. Any number between 60 and 80 are reasonable.
- real_size_threshold: minimum size (in bytes) to be considered a `gitlab-repack` target. Using 10000000 (10 MB) seems reasonable.


For fresh installs, you can configure the tool with this command (Modify vaues as appropiate):

cat > /var/opt/gitlab/postgresql/gitlab-pgrepack/config/gitlab-repack.yml <<EOF
general:
  env: local
database:
  adapter: postgresql
  host: patroni-04-db-gstg.c.gitlab-staging-1.internal
  user: gitlab-superuser
  password: xxx
  database: gitlabhq_production
estimate:
  ratio_threshold: 80 # bloat ratio threshold in % (set to 0 for testing)
  real_size_threshold: 10000000 # real size of object in bytes (set to 0 for testing)
  objects_per_repack: 1
repack:
- command: PGPASSWORD=xxx pg_repack -h patroni-04-db-gstg.c.gitlab-staging-1.internal -p 5432 -U gitlab-superuser -d gitlabhq_production --no-kill-backend

# Optional: Grafana annotations
grafana:
  auth_key: false # put API key here to enable
  base_url: https://dashboards.gitlab.net
EOF

```

## Get objects that needs to be repacked

The bellow command, outputs both tables and indexes that will require repack:

```
/var/opt/gitlab/postgresql/gitlab-pgrepack/bin/gitlab-pgrepack estimate

```
Depending on the values of 
 - ratio_threshold and
 - real_size_threshold
 in your `gitlab-repack` configuration file, output will vary, but in general, it will output the list of commands you need to execute. You can save them in a safe place, while you analyze the right order/time to do so:

 ```
gerardoherzig@patroni-04-db-gstg.c.gitlab-staging-1.internal:~$ /var/opt/gitlab/postgresql/gitlab-pgrepack/bin/gitlab-pgrepack estimate

I, [2020-06-23T21:07:10.079325 #7531]  INFO -- : SET statement_timeout=0
I, [2020-06-23T21:07:10.079882 #7531]  INFO -- : SET idle_in_transaction_session_timeout=0
Note: This is based on an estimation of database bloat.
Note: Executing full table repacking also removes index bloat.

TABLE bloat:
64.64 GiB of bloat (24.5 % ratio of total size)
Recommended repacking for table bloat:
gitlab-pgrepack repack --type=tables --objects=public.project_mirror_data
gitlab-pgrepack repack --type=tables --objects=public.remote_mirrors
gitlab-pgrepack repack --type=tables --objects=public.ci_build_trace_section_names
gitlab-pgrepack repack --type=tables --objects=public.import_export_uploads
gitlab-pgrepack repack --type=tables --objects=public.geo_event_log
gitlab-pgrepack repack --type=tables --objects=public.ci_triggers
gitlab-pgrepack repack --type=tables --objects=public.pages_domains
gitlab-pgrepack repack --type=tables --objects=public.geo_repository_updated_events
gitlab-pgrepack repack --type=tables --objects=public.suggestions
gitlab-pgrepack repack --type=tables --objects=public.geo_node_statuses
Expected cleanup of 311.34 MiB of bloat.

INDEX bloat:
44.90 GiB of bloat (31.2 % ratio of total size)
Recommended repacking for index bloat:
gitlab-pgrepack repack --type=btrees --objects=public.index_user_highest_roles_on_user_id_and_highest_access_level
gitlab-pgrepack repack --type=btrees --objects=public.user_highest_roles_pkey
gitlab-pgrepack repack --type=btrees --objects=public.index_geo_reset_checksum_events_on_project_id
gitlab-pgrepack repack --type=btrees --objects=public.index_geo_event_log_on_container_repository_updated_event_id
gitlab-pgrepack repack --type=btrees --objects=public.geo_event_log_pkey
gitlab-pgrepack repack --type=btrees --objects=public.geo_reset_checksum_events_pkey
gitlab-pgrepack repack --type=btrees --objects=public.index_geo_event_log_on_reset_checksum_event_id
gitlab-pgrepack repack --type=btrees --objects=public.index_merge_request_diffs_on_merge_request_id_and_id_partial
gitlab-pgrepack repack --type=btrees --objects=public.index_namespaces_on_runners_token
gitlab-pgrepack repack --type=btrees --objects=public.index_namespaces_on_runners_token_encrypted
gitlab-pgrepack repack --type=btrees --objects=public.users_reset_password_token_key
gitlab-pgrepack repack --type=btrees --objects=public.index_users_on_group_view
gitlab-pgrepack repack --type=btrees --objects=public.index_users_on_accepted_term_id


 ```



## Script


- Open a `tmux` session before running this script.

```
### pg_repack can generate lots of WAL.
### Also, giving pg_repack more memory can speed up the process considerably.

sudo gitlab-psql -c "ALTER SYSTEM SET max_wal_size TO '16GB'";
sudo gitlab-psql -c "ALTER SYSTEM SET maintenance_work_mem TO '20GB'";
sudo gitlab-psql -c "SELECT pg_reload_conf();"


### REPACKING GOES HERE

## Example of an index
/var/opt/gitlab/postgresql/gitlab-pgrepack/bin/gitlab-pgrepack repack --type=btrees --objects=public.index_chat_names_on_user_id_and_service_id

## Example for a table
/var/opt/gitlab/postgresql/gitlab-pgrepack/bin/gitlab-pgrepack repack --type=tables --objects=public.geo_node_statuses


### Restore the previous settings
sudo gitlab-psql -c "ALTER SYSTEM RESET maintenance_work_mem";
sudo gitlab-psql -c "ALTER SYSTEM RESET max_wal_size";
sudo gitlab-psql -c "SELECT pg_reload_conf();"


```




## Monitoring

### Locking

Locking activity must be properly monitored. Refer to the [locking activity](postgresql-locking.md) runbook for hints.

Both things can happen: pg_repack being blocked or pg_repack being blocking.

The first can be OK in many cases (for example, VACUUM can block pg_repack). You can just wait for VACUUM to finish or *not* use `--no-kill-backend` in your `gitlab-repack` configuration (with care).

Pg_repack should never block regular database activity. In the case of normal queries being blocked by pg_repack activity, gitlab-repack should be canceled immediately!


### Activity
Most of the activity of pg_repack is to build the temporary table that will, eventually, replace the original:

```
-[ RECORD 1 ]----+----------------------------------------------------------------------------
datid            | 241498
datname          | pgrepack_test
pid              | 24505
usesysid         | 10
usename          | postgres
application_name | pg_repack
client_addr      | 127.0.0.1
client_hostname  | 
client_port      | 54102
backend_start    | 2020-06-16 11:24:34.604791-03
xact_start       | 2020-06-16 11:25:35.270385-03
query_start      | 2020-06-16 11:25:35.27519-03
state_change     | 2020-06-16 11:25:35.275191-03
wait_event_type  | 
wait_event       | 
state            | active
backend_xid      | 2481299
backend_xmin     | 2481299
query            | INSERT INTO repack.table_241537 SELECT id,"time",data FROM ONLY public.test
backend_type     | client backend
```

## Clean up activity
Under some circunstances (i.e. if your session crushes), pg_repack may not have been shutdown cleanly. If pg_repack is not longer running, you may need to make some actions to anually cleanup some things.

1.Check for trigger (ussually called "repack_trigger") over the table/s you were woking:

```
pgrepack_test=# \d test
                                      Table "public.test"
 Column |            Type             | Collation | Nullable |             Default              
--------+-----------------------------+-----------+----------+----------------------------------
 id     | integer                     |           | not null | nextval('test_id_seq'::regclass)
 time   | timestamp without time zone |           |          | 
 data   | text                        |           |          | 
Indexes:
    "test_pkey" PRIMARY KEY, btree (id)
Triggers firing always:
    repack_trigger AFTER INSERT OR DELETE OR UPDATE ON test FOR EACH ROW EXECUTE PROCEDURE repack.repack_trigger('INSERT INTO repack.log_241537(pk, row) VALUES( CASE WHEN $1 IS NULL THEN NULL ELSE (ROW($1.id)::repack.pk_241537) END, $2)')
```

If thats the case, you can drop that trigger manually with:
```sql
drop trigger repack_trigger ON test ;
```

1. You might also need to manually cleanup a TABLE that pg_repack creates. First check for existence:

```

pgrepack_test=# \dt repack.
           List of relations
 Schema |    Name    | Type  |  Owner   
--------+------------+-------+----------
 repack | log_241537 | table | postgres
(1 row)

```


Then drop it with:

```sql
drop table repack.log_241537;
```



