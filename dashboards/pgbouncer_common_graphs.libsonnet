local basic = import 'basic.libsonnet';
local layout = import 'layout.libsonnet';

// TECHNICAL DEBT:
// Remove this once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9981
// is fixed
local WAIT_TIME_CORRECTION_FACTOR = 1000000;

local saturationQuery(aggregationLabels, nodeSelector, poolSelector) =
  local formatConfig = {
    nodeSelector: nodeSelector,
    poolSelector: poolSelector,
    aggregationLabels: std.join(', ', aggregationLabels),
  };
  |||
    sum by (%(aggregationLabels)s) (
      pgbouncer_pools_server_active_connections{%(poolSelector)s} +
      pgbouncer_pools_server_testing_connections{%(poolSelector)s} +
      pgbouncer_pools_server_used_connections{%(poolSelector)s} +
      pgbouncer_pools_server_login_connections{%(poolSelector)s}
    )
    /
    sum by (%(aggregationLabels)s) (
      label_replace(
        pgbouncer_databases_pool_size{%(nodeSelector)s},
        "database", "gitlabhq_production_sidekiq", "name", "gitlabhq_production_sidekiq"
      )
    )
  ||| % formatConfig;

{
  workloadStats(serviceType, startRow)::
    local formatConfig = {
      serviceType: serviceType,
    };

    layout.grid([
      basic.timeseries(
        title='Queries Pooled per Node',
        description='Total number of SQL queries pooled - stats_total_query_count',
        query=|||
          sum(rate(pgbouncer_stats_queries_pooled_total{type="%(serviceType)s", environment="$environment"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='ops',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='',
        legend_show=true,
        linewidth=2
      ),
      basic.timeseries(
        title='Total Time in Queries per Node',
        description='Total number of seconds spent by pgbouncer when actively connected to PostgreSQL, executing queries - stats.total_query_time',
        query=|||
          sum(rate(pgbouncer_stats_queries_duration_seconds{type="%(serviceType)s", environment="$environment"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='ops',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='',
        legend_show=true,
        linewidth=2
      ),
      basic.timeseries(
        title='SQL Transactions Pooled per Node',
        description='Total number of SQL transactions pooled - stats.total_xact_count',
        query=|||
          sum(rate(pgbouncer_stats_sql_transactions_pooled_total{type="%(serviceType)s", environment="$environment"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='ops',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='',
        legend_show=true,
        linewidth=2
      ),
      basic.timeseries(
        title='Time in Transaction per Server',
        description='Total number of seconds spent by pgbouncer when connected to PostgreSQL in a transaction, either idle in transaction or executing queries - stats.total_xact_time',
        query=|||
          sum(rate(pgbouncer_stats_server_in_transaction_seconds{type="%(serviceType)s", environment="$environment"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='s',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='',
        legend_show=true,
        linewidth=2
      ),
    ], cols=2, rowHeight=10, startRow=startRow),
  networkStats(serviceType, startRow)::
    local formatConfig = {
      serviceType: serviceType,
    };

    layout.grid([
      basic.timeseries(
        title='Sent Bytes',
        description='Total volume in bytes of network traffic sent by pgbouncer, shown as bytes - stats.total_sent',
        query=
        |||
          sum(rate(pgbouncer_stats_sent_bytes_total{type="%(serviceType)s", environment="$environment"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='Bps',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='',
        legend_show=true,
        linewidth=2
      ),
      basic.timeseries(
        title='Received Bytes',
        description='Total volume in bytes of network traffic received by pgbouncer, shown as bytes - stats.total_received',
        query=
        |||
          sum(rate(pgbouncer_stats_received_bytes_total{type="%(serviceType)s", environment="$environment"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='Bps',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='',
        legend_show=true,
        linewidth=2
      ),

    ], cols=2, rowHeight=10, startRow=startRow),
  connectionPoolingPanels(serviceType, startRow)::
    local nodeSelector = 'type="%(serviceType)s", environment="$environment"' % { serviceType: serviceType};
    local poolSelector = '%(nodeSelector)s, user="gitlab", database!="pgbouncer"' % { nodeSelector: nodeSelector };

    local formatConfig = {
      serviceType: serviceType,
      nodeSelector: nodeSelector,
      poolSelector: poolSelector,
      WAIT_TIME_CORRECTION_FACTOR: WAIT_TIME_CORRECTION_FACTOR,
    };

    layout.grid([
      basic.timeseries(
        title='Server Connection Pool Active Connections per Node',
        description='Number of active connections per node',
        query=
        |||
          sum(max_over_time(pgbouncer_pools_server_active_connections{%(poolSelector)s}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='1m',
        intervalFactor=2,
        yAxisLabel='',
        legend_show=true,
        linewidth=1
      ),
      basic.saturationTimeseries(
        title='Connection Saturation per Pool',
        description='Shows connection saturation per pgbouncer pool. Lower is better.',
        yAxisLabel='Server Pool Utilization',
        query=saturationQuery(
          aggregationLabels=['database', 'env', 'environment', 'shard', 'stage', 'tier', 'type'],
          nodeSelector=nodeSelector,
          poolSelector=poolSelector,
        ),
        legendFormat='{{ database }} pool',
        interval='30s',
        intervalFactor=3,
      ),
      basic.saturationTimeseries(
        title='Connection Saturation per Pool per Node',
        description='Shows connection saturation per pgbouncer pool, per pgbouncer node. Lower is better.',
        yAxisLabel='Server Pool Utilization',
        query=saturationQuery(
          aggregationLabels=['database', 'env', 'environment', 'fqdn', 'job', 'shard', 'stage', 'tier', 'type'],
          nodeSelector=nodeSelector,
          poolSelector=poolSelector,
        ),
        legendFormat='{{ fqdn }} {{ database }} pool',
        interval='30s',
        intervalFactor=3,
        linewidth=1,
      ),
      basic.latencyTimeseries(
        title='Total Connection Wait Time',
        description='Total aggregated time spend waiting for a backend connection. Lower is better',
        query=|||
          sum by (database, environment, type) (rate(pgbouncer_stats_client_wait_seconds{%(nodeSelector)s, database!="pgbouncer"}[$__interval]) / %(WAIT_TIME_CORRECTION_FACTOR)g)
        ||| % formatConfig,
        legendFormat='{{ database }}',
        format='s',
        yAxisLabel='Latency',
        interval='1m',
        intervalFactor=1
      ),
      basic.latencyTimeseries(
        title='Average Wait Time per SQL Transaction',
        description='Average time spent waiting for a backend connection from the pool. Lower is better',
        query=|||
          sum by (database, environment, type) (rate(pgbouncer_stats_client_wait_seconds{%(nodeSelector)s, database!="pgbouncer"}[$__interval]) / %(WAIT_TIME_CORRECTION_FACTOR)g)
          /
          sum by (database, environment, type) (pgbouncer_stats_sql_transactions_pooled_total{%(nodeSelector)s, database!="pgbouncer"})
        ||| % formatConfig,
        legendFormat='{{ database }}',
        format='s',
        yAxisLabel='Latency',
        interval='1m',
        intervalFactor=1
      ),
      basic.queueLengthTimeseries(
        title='Waiting Client Connections per Pool (⚠️ possibly inaccurate, occassionally polled value, do not make assumptions based on this)',
        query=
        |||
          sum(avg_over_time(pgbouncer_pools_client_waiting_connections{%(poolSelector)s}[$__interval])) by (database)
        ||| % formatConfig,
        legendFormat='{{ database }} pool',
        intervalFactor=5,
      ),
      basic.queueLengthTimeseries(
        title='Active Backend Server Connections per Database',
        yAxisLabel='Active Connections',
        query=
        |||
          sum(avg_over_time(pgbouncer_pools_server_active_connections{%(poolSelector)s}[$__interval])) by (database)
        ||| % formatConfig,
        legendFormat='{{ database }} database',
        intervalFactor=5,
      ),
      basic.queueLengthTimeseries(
        title='Active Backend Server Connections per User',
        yAxisLabel='Active Connections',
        query=|||
          sum(avg_over_time(pgbouncer_pools_server_active_connections{%(poolSelector)s}[$__interval])) by (user)
        ||| % formatConfig,
        legendFormat='{{ user }}',
        intervalFactor=5,
      ),
      // This requires https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9980
      // for pgbouncer nodes
      basic.saturationTimeseries(
        title='pgbouncer Single Threaded CPU Saturation per Node',
        description=|||
          pgbouncer is single-threaded. This graph shows maximum utilization across all cores on each host. Lower is better.

          Missing data? [https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9980](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9980)
        |||,
        query=|||
          sum(
            rate(
              namedprocess_namegroup_cpu_seconds_total{groupname=~"pgbouncer.*", %(nodeSelector)s}[1m]
            )
          ) by (groupname, fqdn, type, tier, stage, environment)
        ||| % formatConfig,
        legendFormat='{{ groupname }} {{ fqdn }}',
        interval='30s',
        intervalFactor=1,
      ),
    ], cols=2, rowHeight=10, startRow=startRow),
}
