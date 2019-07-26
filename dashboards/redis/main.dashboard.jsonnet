local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local colors = import 'colors.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

dashboard.new(
  'redis Overview',
  schemaVersion=16,
  tags=['redis', 'overview'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanel(row.new(title="Clients"),
  gridPos={
      x: 0,
      y: 0,
      w: 24,
      h: 1,
  }
)
.addPanels(layout.grid([
    basic.timeseries(
      title='Connected Clients',
      yAxisLabel='Clients',
      query='
        avg_over_time(redis_connected_clients{environment="$environment", type="redis"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),
    basic.timeseries(
      title='Blocked Clients',
      description="Blocked clients are waiting for a state change event using commands such as BLPOP. Blocked clients are not a sign of an issue on their own.",
      yAxisLabel='Blocked Clients',
      query='
        avg_over_time(redis_blocked_clients{environment="$environment", type="redis"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),
    basic.timeseries(
      title='Connections Received',
      yAxisLabel='Connections',
      query='
        rate(redis_connections_received_total{environment="$environment", type="redis"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),
  ], cols=2,rowHeight=10, startRow=1)
)
.addPanel(row.new(title="Workload"),
  gridPos={
      x: 0,
      y: 1000,
      w: 24,
      h: 1,
  }
)
.addPanels(layout.grid([
    basic.timeseries(
      title='Operation Rate',
      yAxisLabel='Operations/sec',
      query='
        sum(rate(redis_commands_total{environment="$environment", type="redis"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=1,
    ),
    basic.saturationTimeseries(
      title='Max Single Core Saturation per Node',
      description="redis is single-threaded. This graph shows maximum utilization across all cores on each host. Lower is better.",
      query='
        max(1 - rate(node_cpu_seconds_total{environment="$environment", type="redis", mode="idle", fqdn=~"redis-\\\\d\\\\d.*"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      interval="30s",
      intervalFactor=1,
    ),
    basic.timeseries(
      title='Redis Network Out',
      format='Bps',
      query='
        rate(redis_net_output_bytes_total{environment="$environment", type="redis"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),
    basic.timeseries(
      title='Redis Network In',
      format='Bps',
      query='
        rate(redis_net_input_bytes_total{environment="$environment", type="redis"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),
    basic.timeseries(
      title='Slowlog Events',
      yAxisLabel='Events',
      query='
        changes(redis_slowlog_last_id{environment="$environment", type="redis"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=10,
    ),
    basic.timeseries(
      title='Operation Rate per Command',
      yAxisLabel='Operations/sec',
      legend_show=false,
      query='
        sum(rate(redis_commands_total{environment="$environment", type="redis"}[$__interval])) by (cmd)
      ',
      legendFormat='{{ cmd }}',
      intervalFactor=2,
    ),
    basic.latencyTimeseries(
      title='Average Operation Latency',
      legend_show=false,
      query='
        sum(rate(redis_commands_duration_seconds_total{environment="$environment", type="redis"}[$__interval])) by (cmd)
        /
        sum(rate(redis_commands_total{environment="$environment", type="redis"}[$__interval])) by (cmd)
      ',
      legendFormat='{{ cmd }}',
      intervalFactor=2,
    ),
    basic.latencyTimeseries(
      title='Total Operation Latency',
      legend_show=false,
      query='
        sum(rate(redis_commands_duration_seconds_total{environment="$environment", type="redis"}[$__interval])) by (cmd)
      ',
      legendFormat='{{ cmd }}',
      intervalFactor=2,
    ),

  ], cols=2,rowHeight=10, startRow=1001)
)
.addPanel(row.new(title="Redis Data"),
  gridPos={
      x: 0,
      y: 2000,
      w: 24,
      h: 1,
  }
)
.addPanels(layout.grid([
    basic.timeseries(
      title='Memory Used',
      format='bytes',
      query='
        max_over_time(redis_memory_used_bytes{environment="$environment", type="redis"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),
    basic.timeseries(
      title='Memory Used Rate of Change',
      yAxisLabel='Bytes/sec',
      format='Bps',
      query='
        rate(redis_memory_used_bytes{environment="$environment", type="redis"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),
    basic.timeseries(
      title='Expired Keys',
      yAxisLabel='Keys',
      query='
        rate(redis_expired_keys_total{environment="$environment", type="redis"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),
    basic.timeseries(
      title='Keys Rate of Change',
      yAxisLabel='Keys/sec',
      query='
        sum(rate(redis_db_keys{environment="$environment", type="redis"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),

  ], cols=2,rowHeight=10, startRow=2001)
)
.addPanel(row.new(title="Replication"),
  gridPos={
      x: 0,
      y: 3000,
      w: 24,
      h: 1,
  }
)
.addPanels(layout.grid([
    basic.timeseries(
      title='Connected Secondaries',
      yAxisLabel='Secondaries',
      query='
        avg_over_time(redis_connected_slaves{environment="$environment", type="redis"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),
    basic.timeseries(
      title='Replication Offset',
      yAxisLabel='Bytes',
      format='bytes',
      query='
        redis_master_repl_offset{environment="$environment", type="redis"}
        - on(fqdn) group_right
        redis_connected_slave_offset_bytes{environment="$environment", type="redis"}
      ',
      legendFormat='secondary {{ slave_ip }}',
      intervalFactor=2,
    ),
    basic.timeseries(
      title='Resync Events',
      yAxisLabel='Events',
      query='
        changes(redis_slave_resync_total{environment="$environment", type="redis", fqdn=~"redis-\\\\d\\\\d.*"}[$__interval])
      ',
      legendFormat='{{ fqdn }}',
      intervalFactor=2,
    ),

  ], cols=2,rowHeight=10, startRow=3001)
)

.addPanel(keyMetrics.keyServiceMetricsRow('redis', 'main'), gridPos={ x: 0, y: 4000, })
.addPanel(keyMetrics.keyComponentMetricsRow('redis', 'main'), gridPos={ x: 0, y: 5000, })
.addPanel(nodeMetrics.nodeMetricsDetailRow('type="redis", environment="$environment", fqdn=~"redis-\\\\d\\\\d.*"'), gridPos={ x: 0, y: 6000, })
.addPanel(capacityPlanning.capacityPlanningRow('redis', 'main'), gridPos={ x: 0, y: 7000, })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('redis') + platformLinks.services,
}


