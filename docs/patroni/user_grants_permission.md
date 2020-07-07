# Roles/Users grants and permission Runbook


## Intro
PostgreSQL uses the concept of [roles](https://www.postgresql.org/docs/11/user-manag.html) to manage database access permissions. The roles are database instance global objects which means that a role doesn't belong to a specific database and can access all databases if given the appropriate permissions.

The term of `roles` encapsulates the concepts of groups and users at the same time:

 * roles: Can be group (can't no login) and user 
 * group: can't login

PostgreSQL has default roles that provide access to some database information - you can find more information [here](https://www.postgresql.org/docs/11/default-roles.html). In addition, there is a default superuser, generally called `postgres`.


In the following sections, we will see  some common activities to manage roles and user in PostgreSQL

*Note: To do some of the following operations you will need to have `superuser` or `create role` permissions or be owner of the objects.*

## Create new roles and users
To create roles/user you can use the command [`CREATE ROLE`](https://www.postgresql.org/docs/11/sql-createrole.html)

### create role
 ```
 --create readonly_roles group  
   
  CREATE ROLE readonly_roles;
 ```

### create user
```
 --create user1 user with password 'pass1'
  CREATE ROLE user1 WITH login password 'pass1';
 ```

You also can use the command:  [`CREATE USER`](https://www.postgresql.org/docs/11/sql-createuser.html), it is an alias for CREATE ROLE + LOGIN clause

To check the created Roles/Users in the database instance, you can use the [meta-commands](https://www.postgresql.org/docs/11/app-psql.html#APP-PSQL-META-COMMANDS) `\dg` or  `\du`



```
postgres=# \dg

                                      List of roles
    Role name    |                         Attributes                         | Member of 
-----------------+------------------------------------------------------------+-----------
 postgres        | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 readonly_roles  | Cannot login                                               | {}
 user1           |                                                            | {}



```
## The most common rights for Roles/Users
To define access privileges to roles/users, you must use the command [`GRANT`](https://www.postgresql.org/docs/11/sql-grant.html)
### In schemas

**USAGE**: Permission of usage
```
GRANT USAGE on SCHEMA new_schema to user1;
```
**CREATE**: Permission of create objects
```
GRANT CREATE on SCHEMA new_schema to user1;
```


### In tables

**USAGE**: Permission of SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER
```
--grant select privileges new_table to user1
GRANT SELECT on new_schema.new_table to user1;
```
```
--grant insert privileges new_table to user1
GRANT INSERT on new_schema.new_table to user1;
```
```
--grant update and delete privileges new_table to user1
GRANT UPDATE, DELETE on new_schema.new_table to user1;
```
You can use the clause `ALL PRIVILEGES`  to grant all permission, if we want to grant permission on all the tables of a specific schema can use `ALL TABLES IN SCHEMA ` clause

There are [another types](https://www.postgresql.org/docs/11/sql-grant.html) of object to granting permission, for example, SEQUENCE, FUNCTIONS, DOMAIN, etc

### In Roles
You also can grant permission from `role/user` to another `role/user`:

```
--grant readonly_roles role permission to user1
postgres=# GRANT readonly_roles to user1 ;
GRANT ROLE
postgres=# \dg

                                      List of roles
    Role name    |                         Attributes                         | Member of 
-----------------+------------------------------------------------------------+-----------
 postgres        | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 readonly_roles  | Cannot login                                               | {}
 user1           |                                                            | {readonly_roles}

--user1 will INHERIT permissions from readonly_roles
grant SELECT on ALL tables in schema public to readonly_roles ;

```
## Verify the access of roles/users

```
select grantor,grantee,table_schema||'.'||table_name as table, string_agg(privilege_type,',') as permissions ,string_agg( is_grantable,',') granteable from information_schema.table_privileges where table_schema<> 'pg_catalog' and table_schema<>'information_schema' and  grantee='readonly_roles'  group by 1,2,3 order by 3;

     grantor      |    grantee     |                         table                          | permissions | granteable 
------------------+----------------+--------------------------------------------------------+-------------+------------
 gitlab           | readonly_roles | public.abuse_reports                                   | SELECT      | NO
 gitlab           | readonly_roles | public.alert_management_alert_assignees                | SELECT      | NO
 gitlab           | readonly_roles | public.alert_management_alert_user_mentions            | SELECT      | NO
 gitlab           | readonly_roles | public.alert_management_alerts                         | SELECT      | NO
...

```

## Revoke permission
To revoke access privileges from roles/users, you must use the command [`REVOKE`](https://www.postgresql.org/docs/11/sql-revoke.html)
```
REVOKE SELECT on all tables in schema public from readonly_roles ;
```


## Decommission a user
A roles/users can be deleted from the database using commnad [`DROP ROLE`](https://www.postgresql.org/docs/11/sql-droprole.html), make sure the user doesn't have permission dependencies

```
DROP ROLE readonly_roles ;
```

## Modify pg_hba conf
PostgreSQL manages client authentication using a configuration file called [`pg_hba.conf`](https://www.postgresql.org/docs/11/auth-pg-hba-conf.html) and sometimes it is required to adjust this file for access rights - if you don't have permission to connect, you will see an error similar to:

```
connect to PostgreSQL server: FATAL: no pg_hba.conf entry for host "XXX.XXX.XX.XXX", user "userXXX", database "dbXXX"...

```
You must fix it adding a row for the user in the `pg_hba.conf` file, example:

```
# TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD

host    dbXXX         userXXX         XXX.XXX.XX.XXX/N_mask_byte     md5

```


## Propagated user to PGBouncer 
PGBouncer also needs to be setup for authenticating users. This can be done via a pgbouncer authentication file or by setting up an auth_query against postgres. In our case we are using the [auth_query](https://www.pgbouncer.org/config.html#auth_query) parameter:

```
auth_query = SELECT username, password FROM public.pg_shadow_lookup($1)
```
