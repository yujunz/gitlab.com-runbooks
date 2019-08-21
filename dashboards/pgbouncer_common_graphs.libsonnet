local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';

{
  connectionPoolingPanels(serviceType, startRow):: layout.grid([
    basic.saturationTimeseries(
      title='Server Connection Pool Saturation per Pool',
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
      title='Waiting Client Connections per Pool',
      query='
        sum(avg_over_time(pgbouncer_pools_client_waiting_connections{type="' + serviceType + '", environment="$environment", database!="pgbouncer"}[$__interval])) by (database)
      ',
      legendFormat='{{ database }} pool',
      intervalFactor=5,
    ),
    basic.queueLengthTimeseries(
      title='Active Backend Server Connections per Database',
      yAxisLabel='Active Connections',
      query='
        sum(avg_over_time(pgbouncer_pools_server_active_connections{type="' + serviceType + '", environment="$environment", database!="pgbouncer"}[$__interval])) by (database)
      ',
      legendFormat='{{ database }} database',
      intervalFactor=5,
    ),
    basic.queueLengthTimeseries(
      title='Active Backend Server Connections per User',
      yAxisLabel='Active Connections',
      query='
        sum(avg_over_time(pgbouncer_pools_server_active_connections{type="' + serviceType + '", environment="$environment", database!="pgbouncer"}[$__interval])) by (user)
      ',
      legendFormat='{{ user }}',
      intervalFactor=5,
    ),
    basic.saturationTimeseries(
      title='Max Single Core Saturation per Node',
      description="pgbouncer is single-threaded. This graph shows maximum utilization across all cores on each host. Lower is better.",
      query='
        max(1 - rate(node_cpu_seconds_total{type="' + serviceType + '", environment="$environment", mode="idle"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      interval="30s",
      intervalFactor=1,
    ),
    basic.latencyTimeseries(
      title='Maximum Connection Waiting Time per Pool',
      query='
        max(max_over_time(pgbouncer_pools_client_maxwait_seconds{type="' + serviceType + '", environment="$environment", database!="pgbouncer"}[$__interval])) by (database)
      ',
      legendFormat='{{ database }} pool',
      interval="30s",
      intervalFactor=1,
    ),
  ], cols=2,rowHeight=10, startRow=startRow)
}
