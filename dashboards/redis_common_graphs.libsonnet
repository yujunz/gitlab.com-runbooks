local basic = import 'basic.libsonnet';
local layout = import 'layout.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';

{
  clientPanels(serviceType, startRow)::
    local formatConfig = {
      serviceType: serviceType,
    };
    layout.grid([
      basic.timeseries(
        title='Connected Clients',
        yAxisLabel='Clients',
        query=|||
          sum(avg_over_time(redis_connected_clients{environment="$environment", type="%(serviceType)s"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Blocked Clients',
        description='Blocked clients are waiting for a state change event using commands such as BLPOP. Blocked clients are not a sign of an issue on their own.',
        yAxisLabel='Blocked Clients',
        query=|||
          sum(avg_over_time(redis_blocked_clients{environment="$environment", type="%(serviceType)s"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Connections Received',
        yAxisLabel='Connections',
        query=|||
          sum(rate(redis_connections_received_total{environment="$environment", type="%(serviceType)s"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
    ], cols=2, rowHeight=10, startRow=startRow),

  workload(serviceType, startRow)::
    local formatConfig = {
      serviceType: serviceType,
      primarySelectorSnippet: 'and on (instance) redis_instance_info{role="master"}',
      replicaSelectorSnippet: 'and on (instance) redis_instance_info{role="slave"}',
    };
    layout.grid([
      basic.timeseries(
        title='Operation Rate - Primary',
        yAxisLabel='Operations/sec',
        query=|||
          sum(rate(redis_commands_total{environment="$environment", type="%(serviceType)s"}[$__interval]) %(primarySelectorSnippet)s ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=1,
      ),
      basic.timeseries(
        title='Operation Rate - Replicas',
        yAxisLabel='Operations/sec',
        query=|||
          sum(rate(redis_commands_total{environment="$environment", type="%(serviceType)s"}[$__interval]) %(replicaSelectorSnippet)s ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=1,
      ),
      basic.saturationTimeseries(
        title='Redis CPU per Node - Primary',
        description='redis is single-threaded. This graph shows maximum utilization across all cores on each host. Lower is better.',
        query=|||
          max(
            max_over_time(instance:redis_cpu_usage:rate1m{environment="$environment", type="%(serviceType)s", fqdn=~"%(serviceType)s-\\d\\d.*"}[$__interval])
              %(primarySelectorSnippet)s
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='30s',
        intervalFactor=1,
      ),
      basic.saturationTimeseries(
        title='Redis CPU per Node - Replicas',
        description='redis is single-threaded. This graph shows maximum utilization across all cores on each host. Lower is better.',
        query=|||
          max(
            max_over_time(instance:redis_cpu_usage:rate1m{environment="$environment", type="%(serviceType)s", fqdn=~"%(serviceType)s-\\d\\d.*"}[$__interval])
              %(replicaSelectorSnippet)s
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='30s',
        intervalFactor=1,
      ),
      basic.timeseries(
        title='Redis Network Out - Primary',
        format='Bps',
        query=|||
          sum(rate(redis_net_output_bytes_total{environment="$environment", type="%(serviceType)s"}[$__interval])
           %(primarySelectorSnippet)s
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Redis Network Out - Replicas',
        format='Bps',
        query=|||
          sum(rate(redis_net_output_bytes_total{environment="$environment", type="%(serviceType)s"}[$__interval])
           %(replicaSelectorSnippet)s
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Redis Network In - Primary',
        format='Bps',
        query=|||
          sum(rate(redis_net_input_bytes_total{environment="$environment", type="%(serviceType)s"}[$__interval])
            %(primarySelectorSnippet)s
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Redis Network In - Replicas',
        format='Bps',
        query=|||
          sum(rate(redis_net_input_bytes_total{environment="$environment", type="%(serviceType)s"}[$__interval])
            %(replicaSelectorSnippet)s
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Slowlog Events - Primary',
        yAxisLabel='Events',
        query=|||
          sum(changes(redis_slowlog_last_id{environment="$environment", type="%(serviceType)s"}[$__interval])
            %(primarySelectorSnippet)s
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=10,
      ),
      basic.timeseries(
        title='Slowlog Events - Replicas',
        yAxisLabel='Events',
        query=|||
          sum(changes(redis_slowlog_last_id{environment="$environment", type="%(serviceType)s"}[$__interval])
            %(replicaSelectorSnippet)s
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=10,
      ),
      basic.timeseries(
        title='Operation Rate per Command - Primary',
        yAxisLabel='Operations/sec',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_total{environment="$environment", type="%(serviceType)s"}[$__interval])
            %(primarySelectorSnippet)s
          ) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Operation Rate per Command - Replicas',
        yAxisLabel='Operations/sec',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_total{environment="$environment", type="%(serviceType)s"}[$__interval])
            %(replicaSelectorSnippet)s
          ) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Average Operation Latency - Primary',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_duration_seconds_total{environment="$environment", type="%(serviceType)s"}[$__interval])
            %(primarySelectorSnippet)s
          ) by (cmd)
          /
          sum(rate(redis_commands_total{environment="$environment", type="%(serviceType)s"}[$__interval])) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Average Operation Latency - Replicas',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_duration_seconds_total{environment="$environment", type="%(serviceType)s"}[$__interval])
            %(replicaSelectorSnippet)s
          ) by (cmd)
          /
          sum(rate(redis_commands_total{environment="$environment", type="%(serviceType)s"}[$__interval])) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Total Operation Latency - Primary',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_duration_seconds_total{environment="$environment", type="%(serviceType)s"}[$__interval])
            %(primarySelectorSnippet)s
          ) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),
      basic.latencyTimeseries(
        title='Total Operation Latency - Replicas',
        legend_show=false,
        query=|||
          sum(rate(redis_commands_duration_seconds_total{environment="$environment", type="%(serviceType)s"}[$__interval])
            %(replicaSelectorSnippet)s
          ) by (cmd)
        ||| % formatConfig,
        legendFormat='{{ cmd }}',
        intervalFactor=2,
      ),

    ], cols=2, rowHeight=10, startRow=startRow),

  data(serviceType, startRow)::
    local formatConfig = {
      serviceType: serviceType,
    };
    layout.grid([
      basic.saturationTimeseries(
        title='Memory Saturation',
        // TODO: After upgrading to Redis 4, we should include the rdb_last_cow_size in this value
        // so that we include the RDB snapshot utilization in our memory usage
        // See https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3785#note_234689504
        description='Redis holds all data in memory. Avoid memory saturation in Redis at all cost ',
        query=|||
          max(
            label_replace(redis_memory_used_rss_bytes{environment="$environment", type="%(serviceType)s"}, "memtype", "rss","","")
            or
            label_replace(redis_memory_used_bytes{environment="$environment", type="%(serviceType)s"}, "memtype", "used","","")
          ) by (type, tier, stage, environment, fqdn)
          / on(fqdn) group_left
          node_memory_MemTotal_bytes{environment="$environment", type="%(serviceType)s"}
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='30s',
        intervalFactor=1,
      )
      .addSeriesOverride(seriesOverrides.degradationSlo)
      .addSeriesOverride(seriesOverrides.outageSlo)
      .addTarget(
        promQuery.target(
          |||
            max(slo:max:soft:gitlab_component_saturation:ratio{component="redis_memory", environment="$environment"})
          ||| % formatConfig,
          interval='5m',
          legendFormat='Degradation SLO',
        ),
      )
      .addTarget(
        promQuery.target(
          |||
            max(slo:max:hard:gitlab_component_saturation:ratio{component="redis_memory", environment="$environment"})
          ||| % formatConfig,
          interval='5m',
          legendFormat='Outage SLO',
        ),
      ),
      basic.timeseries(
        title='Memory Used',
        format='bytes',
        query=|||
          max_over_time(redis_memory_used_bytes{environment="$environment", type="%(serviceType)s"}[$__interval])
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Memory Used Rate of Change',
        yAxisLabel='Bytes/sec',
        format='Bps',
        query=|||
          sum(rate(redis_memory_used_bytes{environment="$environment", type="%(serviceType)s"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Redis RSS Usage',
        description='Depending on the memory allocator used, Redis may not return memory to the operating system at the same rate that applications release keys. RSS indicates the operating systems perspective of Redis memory usage. So, even if usage is low, if RSS is high, the OOM killer may terminate the Redis process',
        format='bytes',
        query=|||
          max_over_time(redis_memory_used_rss_bytes{environment="$environment", type="%(serviceType)s"}[$__interval])
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Memory Fragmentation',
        description='The fragmentation ratio in Redis should ideally be around 1.0 and generally below 1.5. The higher the value, the more wasted memory.',
        query=|||
          redis_memory_used_rss_bytes{environment="$environment", type="%(serviceType)s"} / redis_memory_used_bytes{environment="$environment", type="%(serviceType)s"}
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Expired Keys',
        yAxisLabel='Keys',
        query=|||
          sum(rate(redis_expired_keys_total{environment="$environment", type="%(serviceType)s"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Keys Rate of Change',
        yAxisLabel='Keys/sec',
        query=|||
          sum(rate(redis_db_keys{environment="$environment", type="%(serviceType)s"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
    ], cols=2, rowHeight=10, startRow=startRow),

  replication(serviceType, startRow)::
    local formatConfig = {
      serviceType: serviceType,
    };
    layout.grid([
      basic.timeseries(
        title='Connected Secondaries',
        yAxisLabel='Secondaries',
        query=|||
          sum(avg_over_time(redis_connected_slaves{environment="$environment", type="%(serviceType)s"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Replication Offset',
        yAxisLabel='Bytes',
        format='bytes',
        query=|||
          redis_master_repl_offset{environment="$environment", type="%(serviceType)s"}
          - on(fqdn) group_right
          redis_connected_slave_offset_bytes{environment="$environment", type="%(serviceType)s"}
        ||| % formatConfig,
        legendFormat='secondary {{ slave_ip }}',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Resync Events',
        yAxisLabel='Events',
        query=|||
          sum(increase(redis_slave_resync_total{environment="$environment", type="%(serviceType)s", fqdn=~"%(serviceType)s-\\\\d\\\\d.*"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        intervalFactor=2,
      ),
    ], cols=2, rowHeight=10, startRow=startRow),

}
