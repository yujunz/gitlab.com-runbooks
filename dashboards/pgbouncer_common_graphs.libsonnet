local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';

local PGBOUNCER_WARNING = ' - THESE GRAPHS ARE INCORRECT. SEE https://gitlab.com/gitlab-com/gl-infra/production/issues/1078';

{
  workloadStats(serviceType, startRow):: layout.grid([
    basic.timeseries(
      title="Queries Pooled per Node" + PGBOUNCER_WARNING,
      description="Total number of SQL queries pooled - stats_total_query_count",
      query='
        sum(rate(pgbouncer_stats_queries_pooled_total{type="' + serviceType + '", environment="$environment"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      format='ops',
      interval="1m",
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title="Total Time in Queries per Node" + PGBOUNCER_WARNING,
      description="Total number of seconds spent by pgbouncer when actively connected to PostgreSQL, executing queries - stats.total_query_time",
      query='
        sum(rate(pgbouncer_stats_queries_duration_seconds{type="' + serviceType + '", environment="$environment"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      format='ops',
      interval="1m",
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title="SQL Transactions Pooled per Node" + PGBOUNCER_WARNING,
      description="Total number of SQL transactions pooled - stats.total_xact_count",
      query='
        sum(rate(pgbouncer_stats_sql_transactions_pooled_total{type="' + serviceType + '", environment="$environment"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      format='ops',
      interval="1m",
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title="Time in Transaction per Server" + PGBOUNCER_WARNING,
      description="Total number of seconds spent by pgbouncer when connected to PostgreSQL in a transaction, either idle in transaction or executing queries - stats.total_xact_time",
      query='
        sum(rate(pgbouncer_stats_server_in_transaction_seconds{type="' + serviceType + '", environment="$environment"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      format='s',
      interval="1m",
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    )
  ], cols=2,rowHeight=10, startRow=startRow),
  networkStats(serviceType, startRow):: layout.grid([
    basic.timeseries(
      title="Sent Bytes" + PGBOUNCER_WARNING,
      description="Total volume in bytes of network traffic sent by pgbouncer, shown as bytes - stats.total_sent",
      query='
        sum(rate(pgbouncer_stats_sent_bytes_total{type="' + serviceType + '", environment="$environment"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      format='Bps',
      interval="1m",
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title="Received Bytes" + PGBOUNCER_WARNING,
      description="Total volume in bytes of network traffic received by pgbouncer, shown as bytes - stats.total_received",
      query='
        sum(rate(pgbouncer_stats_received_bytes_total{type="' + serviceType + '", environment="$environment"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      format='Bps',
      interval="1m",
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    )

  ], cols=2,rowHeight=10, startRow=startRow),
  connectionPoolingPanels(serviceType, startRow):: layout.grid([
    basic.timeseries(
      title="Server Connection Pool Active Connections per Node" + PGBOUNCER_WARNING,
      description="Number of active connections per node",
      query='
        sum(max_over_time(pgbouncer_pools_server_active_connections{type="' + serviceType + '", environment="$environment", user="gitlab", database!="pgbouncer"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      interval="1m",
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=1
    ),
    basic.saturationTimeseries(
      title='Server Connection Pool Saturation per Pool' + PGBOUNCER_WARNING,
      yAxisLabel='Server Pool Utilization',
      query='
          max(
            max_over_time(pgbouncer_pools_server_active_connections{type="' + serviceType + '", environment="$environment", user="gitlab", database!="pgbouncer"}[$__interval]) /
            (
              (
                pgbouncer_pools_server_idle_connections{type="' + serviceType + '", environment="$environment", user="gitlab", database!="pgbouncer"} +
                pgbouncer_pools_server_active_connections{type="' + serviceType + '", environment="$environment", user="gitlab", database!="pgbouncer"} +
                pgbouncer_pools_server_testing_connections{type="' + serviceType + '", environment="$environment", user="gitlab", database!="pgbouncer"} +
                pgbouncer_pools_server_used_connections{type="' + serviceType + '", environment="$environment", user="gitlab", database!="pgbouncer"} +
                pgbouncer_pools_server_login_connections{type="' + serviceType + '", environment="$environment", user="gitlab", database!="pgbouncer"}
              )
              > 0
            )
          ) by (database)
      ',
      legendFormat='{{ database }} pool',
      interval="30s",
      intervalFactor=5,
    ),
    basic.queueLengthTimeseries(
      title='Waiting Client Connections per Pool' + PGBOUNCER_WARNING,
      query='
        sum(avg_over_time(pgbouncer_pools_client_waiting_connections{type="' + serviceType + '", environment="$environment", database!="pgbouncer"}[$__interval])) by (database)
      ',
      legendFormat='{{ database }} pool',
      intervalFactor=5,
    ),
    basic.queueLengthTimeseries(
      title='Active Backend Server Connections per Database' + PGBOUNCER_WARNING,
      yAxisLabel='Active Connections',
      query='
        sum(avg_over_time(pgbouncer_pools_server_active_connections{type="' + serviceType + '", environment="$environment", database!="pgbouncer"}[$__interval])) by (database)
      ',
      legendFormat='{{ database }} database',
      intervalFactor=5,
    ),
    basic.queueLengthTimeseries(
      title='Active Backend Server Connections per User' + PGBOUNCER_WARNING,
      yAxisLabel='Active Connections',
      query='
        sum(avg_over_time(pgbouncer_pools_server_active_connections{type="' + serviceType + '", environment="$environment", database!="pgbouncer"}[$__interval])) by (user)
      ',
      legendFormat='{{ user }}',
      intervalFactor=5,
    ),
    basic.saturationTimeseries(
      title='Max Single Core Saturation per Node' + PGBOUNCER_WARNING,
      description="pgbouncer is single-threaded. This graph shows maximum utilization across all cores on each host. Lower is better.",
      query='
        max(1 - rate(node_cpu_seconds_total{type="' + serviceType + '", environment="$environment", mode="idle"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      interval="30s",
      intervalFactor=1,
    ),
    basic.latencyTimeseries(
      title='Maximum Connection Waiting Time per Pool' + PGBOUNCER_WARNING,
      query='
        max(max_over_time(pgbouncer_pools_client_maxwait_seconds{type="' + serviceType + '", environment="$environment", database!="pgbouncer"}[$__interval])) by (database)
      ',
      legendFormat='{{ database }} pool',
      interval="30s",
      intervalFactor=1,
    ),
  ], cols=2,rowHeight=10, startRow=startRow)
}
