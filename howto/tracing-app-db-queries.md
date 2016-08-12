# Application Database Queries

## Tracing the Source

If the database experiences high load, you may see the same queries duplicated in the
database log. For example, let's suppose you see hundreds of these [queries in the active
list](howto/postgresql.md#get-a-list-of-all-active-queries)

```sql
SELECT COUNT(*) FROM "projects" WHERE "projects"."pending_delete" = $1
```

How do you find the source of the problem? Sometimes it's easy to tell what the
query is doing and trace it back to the code. But sometimes that's difficult, and you
need a more systematic way of identifying the cause. Here's how:

1. Look at the application name in the DB. For PostgreSQL, this is the `application_name`
   column in `pg_stat_activity`. This should be `unicorn` if it's coming from the Rails application
   or `sidekiq` if it's coming from Sidekiq.

2. Insert a snippet of code that prints a log message when this expression is executed. For example,
   you can add similar code to `/opt/gitlab/embedded/service/gitlab-rails/config/initializers/log_query.rb`:

    ```ruby
    ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, details|
      if details[:sql] =~ /SELECT COUNT\(\*\) FROM "projects" WHERE "projects"."pending_delete"/
        Rails.logger.info("*** Query is #{details[:sql]}")
        Rails.logger.info(caller.join("\n"))
        Rails.logger.info("*" * 50)
      end
    end
    ```

3. Restart the application (e.g. `sudo gitlab-ctl restart unicorn`).

4. Look in `/var/log/gitlab/gitlab-rails/production.log` for these log entries. You will see a
   backtrace telling you where the query came from:

    ```ruby
    *** Query is SELECT COUNT(*) FROM "projects" WHERE "projects"."pending_delete" = $1
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activesupport-4.2.7/lib/active_support/notifications/fanout.rb:127:in `call'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activesupport-4.2.7/lib/active_support/notifications/fanout.rb:127:in `finish'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activesupport-4.2.7/lib/active_support/notifications/fanout.rb:46:in `block in finish'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activesupport-4.2.7/lib/active_support/notifications/fanout.rb:46:in `each'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activesupport-4.2.7/lib/active_support/notifications/fanout.rb:46:in `finish'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activesupport-4.2.7/lib/active_support/notifications/instrumenter.rb:36:in `finish'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activesupport-4.2.7/lib/active_support/notifications/instrumenter.rb:25:in `instrument'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/connection_adapters/abstract_adapter.rb:478:in `log'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/connection_adapters/postgresql_adapter.rb:601:in `exec_cache'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/connection_adapters/postgresql_adapter.rb:585:in `execute_and_clear'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/connection_adapters/postgresql/database_statements.rb:160:in `exec_query'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/connection_adapters/abstract/database_statements.rb:356:in `select'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/connection_adapters/abstract/database_statements.rb:32:in `select_all'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/connection_adapters/abstract/query_cache.rb:68:in `block in select_all'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/connection_adapters/abstract/query_cache.rb:83:in `cache_sql'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/connection_adapters/abstract/query_cache.rb:68:in `select_all'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/relation/calculations.rb:270:in `execute_simple_calculation'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/relation/calculations.rb:227:in `perform_calculation'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/relation/calculations.rb:133:in `calculate'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.7/lib/active_record/relation/calculations.rb:48:in `count'
    /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/kaminari-0.17.0/lib/kaminari/models/active_record_relation_methods.rb:33:in `total_count'
    /opt/gitlab/embedded/service/gitlab-rails/lib/api/helpers.rb:382:in `add_pagination_headers'
    /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/instrumentation.rb:152:in `block in add_pagination_headers'
    /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/method_call.rb:23:in `measure'
    /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/transaction.rb:71:in `measure_method'
    /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/instrumentation.rb:152:in `add_pagination_headers'
    /opt/gitlab/embedded/service/gitlab-rails/lib/api/helpers.rb:122:in `block in paginate'
    ```
