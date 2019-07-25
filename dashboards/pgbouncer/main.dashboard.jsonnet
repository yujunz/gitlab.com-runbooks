local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local colors = import 'colors.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
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
  'pgbouncer Overview',
  schemaVersion=16,
  tags=['pgbouncer'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanel(row.new(title="pgbouncer Connection Pooling"),
  gridPos={
      x: 0,
      y: 0,
      w: 24,
      h: 1,
  }
)
.addPanels(layout.grid([
    basic.saturationTimeseries(
      title='Server Connection Pool Saturation per Pool',
      yAxisLabel='Server Pool Utilization',
      query='
          max(
            max_over_time(pgbouncer_pools_server_active_connections{type="pgbouncer", environment="$environment", user="gitlab", database!="pgbouncer"}[$__interval]) /
            (
              (
                pgbouncer_pools_server_idle_connections{type="pgbouncer", environment="$environment", user="gitlab", database!="pgbouncer"} +
                pgbouncer_pools_server_active_connections{type="pgbouncer", environment="$environment", user="gitlab", database!="pgbouncer"} +
                pgbouncer_pools_server_testing_connections{type="pgbouncer", environment="$environment", user="gitlab", database!="pgbouncer"} +
                pgbouncer_pools_server_used_connections{type="pgbouncer", environment="$environment", user="gitlab", database!="pgbouncer"} +
                pgbouncer_pools_server_login_connections{type="pgbouncer", environment="$environment", user="gitlab", database!="pgbouncer"}
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
        sum(avg_over_time(pgbouncer_pools_client_waiting_connections{type="pgbouncer", environment="$environment", database!="pgbouncer"}[$__interval])) by (database)
      ',
      legendFormat='{{ database }} pool',
      intervalFactor=5,
    ),
    basic.queueLengthTimeseries(
      title='Active Backend Server Connections per Database',
      yAxisLabel='Active Connections',
      query='
        sum(avg_over_time(pgbouncer_pools_server_active_connections{type="pgbouncer", environment="$environment", database!="pgbouncer"}[$__interval])) by (database)
      ',
      legendFormat='{{ database }} database',
      intervalFactor=5,
    ),
    basic.queueLengthTimeseries(
      title='Active Backend Server Connections per User',
      yAxisLabel='Active Connections',
      query='
        sum(avg_over_time(pgbouncer_pools_server_active_connections{type="pgbouncer", environment="$environment", database!="pgbouncer"}[$__interval])) by (user)
      ',
      legendFormat='{{ user }}',
      intervalFactor=5,
    ),
    basic.saturationTimeseries(
      title='Max Single Core Saturation per Node',
      description="pgbouncer is single-threaded. This graph shows maximum utilization across all cores on each host. Lower is better.",
      query='
        max(1 - rate(node_cpu_seconds_total{type="pgbouncer", environment="$environment", mode="idle"}[$__interval])) by (fqdn)
      ',
      legendFormat='{{ fqdn }}',
      interval="30s",
      intervalFactor=1,
    ),
    basic.latencyTimeseries(
      title='Maximum Connection Waiting Time per Pool',
      query='
        max(max_over_time(pgbouncer_pools_client_maxwait_seconds{type="pgbouncer", environment="$environment", database!="pgbouncer"}[$__interval])) by (database)
      ',
      legendFormat='{{ database }} pool',
      interval="30s",
      intervalFactor=1,
    ),
  ], cols=2,rowHeight=10, startRow=1)
)
.addPanel(keyMetrics.keyServiceMetricsRow('pgbouncer', 'main'), gridPos={ x: 0, y: 1000, })
.addPanel(keyMetrics.keyComponentMetricsRow('pgbouncer', 'main'), gridPos={ x: 0, y: 2000, })
.addPanel(nodeMetrics.nodeMetricsDetailRow('type="pgbouncer", environment="$environment"'), gridPos={ x: 0, y: 3000, })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('pgbouncer'),
}


