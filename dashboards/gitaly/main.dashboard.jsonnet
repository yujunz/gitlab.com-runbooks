local basic = import 'basic.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceHealth = import 'service_health.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';

local GITALY_PEAK_WRITE_THROUGHPUT_BYTES_PER_SECOND = 400 * 1024 * 1024;
local GITALY_PEAK_READ_THROUGHPUT_BYTES_PER_SECOND = 1200 * 1024 * 1024;
local GITALY_DISK = 'sdb';

local gitalyConfig = {
  GITALY_PEAK_WRITE_THROUGHPUT_BYTES_PER_SECOND: GITALY_PEAK_WRITE_THROUGHPUT_BYTES_PER_SECOND,
  GITALY_PEAK_READ_THROUGHPUT_BYTES_PER_SECOND: GITALY_PEAK_READ_THROUGHPUT_BYTES_PER_SECOND,
  GITALY_DISK: GITALY_DISK,
};

local selector = 'environment="$environment", type="gitaly", stage="$stage"';

local generalGraphPanel(title, description=null, linewidth=2, sort='increasing') =
  graphPanel.new(
    title,
    linewidth=linewidth,
    fill=0,
    datasource='$PROMETHEUS_DS',
    description=description,
    decimals=2,
    sort=sort,
    legend_show=true,
    legend_values=true,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=false,
    legend_avg=true,
    legend_alignAsTable=true,
    legend_hideEmpty=true,
  )
  .addSeriesOverride(seriesOverrides.goldenMetric('/ service/'))
  .addSeriesOverride(seriesOverrides.upper)
  .addSeriesOverride(seriesOverrides.lower)
  .addSeriesOverride(seriesOverrides.upperLegacy)
  .addSeriesOverride(seriesOverrides.lowerLegacy)
  .addSeriesOverride(seriesOverrides.lastWeek)
  .addSeriesOverride(seriesOverrides.alertFiring)
  .addSeriesOverride(seriesOverrides.alertPending)
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)
  .addSeriesOverride(seriesOverrides.slo);

local readThroughput() = basic.saturationTimeseries(
  title='Average Peak Read Throughput per Node',
  description='Average Peak read throughput as a ratio of specified max (over 30s) per Node, on the Gitaly disk (%(GITALY_DISK)s). Lower is better.' % gitalyConfig,
  query=|||
    avg_over_time(
      max_over_time(
        rate(node_disk_read_bytes_total{environment="$environment", stage="$stage", type="gitaly", device="%(GITALY_DISK)s"}[30s]) / (%(GITALY_PEAK_READ_THROUGHPUT_BYTES_PER_SECOND)s)[5m:30s]
      )[$__interval:1m]
    )
  ||| % gitalyConfig,
  legendFormat='{{ fqdn }}',
  interval='1m',
  intervalFactor=3,
  linewidth=1,
  legend_show=true,
);

local writeThroughput() =
  basic.saturationTimeseries(
    title='Average Peak Write Throughput per Node',
    description='Average Peak write throughput as a ratio of specified max (over 30s) per Node, on the Gitaly disk (%(GITALY_DISK)s). Lower is better.' % gitalyConfig,
    query=|||
      avg_over_time(
        max_over_time(
          rate(node_disk_written_bytes_total{environment="$environment", stage="$stage", type="gitaly", device="%(GITALY_DISK)s"}[30s]) / (%(GITALY_PEAK_WRITE_THROUGHPUT_BYTES_PER_SECOND)s)[5m:30s]
       )[$__interval:1m]
      )
    ||| % gitalyConfig,
    legendFormat='{{ fqdn }}',
    interval='1m',
    intervalFactor=3,
    linewidth=1,
    legend_show=true,
  );

local ratelimitLockPercentage() =
  generalGraphPanel(
    'Request % acquiring rate-limit lock within 1m, by host + method',
    description='Percentage of requests that acquire a Gitaly rate-limit lock within 1 minute, by host and method'
  )
  .addTarget(
    promQuery.target(
      |||
        sum(
          rate(
            gitaly_rate_limiting_acquiring_seconds_bucket{
              environment="$environment",
              stage="$stage",
              le="60"
            }[$__interval]
          )
        ) by (environment, tier, type, stage, fqdn, grpc_method)
        /
        sum(
          rate(
            gitaly_rate_limiting_acquiring_seconds_bucket{
              environment="$environment",
              stage="$stage",
              le="+Inf"
            }[$__interval]
          )
        ) by (environment, tier, type, stage, fqdn, grpc_method)
      |||,
      interval='30s',
      legendFormat='{{fqdn}} - {{grpc_method}}'
    )
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    min=0,
    max=1,
    label='%'
  )
  .addYaxis(
    format='short',
    show=false,
  );

// This needs to be kept manually in sync with the Gitaly apdex rule, in `service_apdex.yml`
local perNodeApdex() =
  basic.apdexTimeseries(
    title='Apdex score per Gitaly Node',
    description='Apdex is a measure of requests that complete within an acceptable threshold duration. Actual threshold vary per service or endpoint. Higher is better.',
    query=|||
      (
        sum(rate(grpc_server_handling_seconds_bucket{environment="$environment", stage="$stage",type="gitaly", tier="stor", grpc_type="unary", le="0.5", grpc_method!~"GarbageCollect|Fsck|RepackFull|RepackIncremental|CommitLanguages|CreateRepositoryFromURL|UserRebase|UserSquash|CreateFork|UserUpdateBranch|FindRemoteRepository|UserCherryPick|FetchRemote|UserRevert|FindRemoteRootRef"}[1m])) by (environment, type, tier, stage, fqdn)
        +
        sum(rate(grpc_server_handling_seconds_bucket{environment="$environment", stage="$stage",type="gitaly", tier="stor", grpc_type="unary", le="1", grpc_method!~"GarbageCollect|Fsck|RepackFull|RepackIncremental|CommitLanguages|CreateRepositoryFromURL|UserRebase|UserSquash|CreateFork|UserUpdateBranch|FindRemoteRepository|UserCherryPick|FetchRemote|UserRevert|FindRemoteRootRef"}[1m])) by (environment, type, tier, stage, fqdn)
      )
      /
      2 / (sum(rate(grpc_server_handling_seconds_count{environment="$environment", stage="$stage",type="gitaly", tier="stor", grpc_type="unary", grpc_method!~"GarbageCollect|Fsck|RepackFull|RepackIncremental|CommitLanguages|CreateRepositoryFromURL|UserRebase|UserSquash|CreateFork|UserUpdateBranch|FindRemoteRepository|UserCherryPick|FetchRemote|UserRevert|FindRemoteRootRef"}[1m])) by (environment, type, tier, stage, fqdn))
    |||,
    legendFormat='{{ fqdn }}',
    interval='1m',
    linewidth=1,
    legend_show=false,
  );

local inflightGitalyCommandsPerNode() =
  basic.timeseries(
    title='Inflight Git Commands per Server',
    description='Number of Git commands running concurrently per node. Lower is better.',
    query=|||
      avg_over_time(gitaly_commands_running{environment="$environment", stage="$stage"}[$__interval])
    |||,
    legendFormat='{{ fqdn }}',
    interval='1m',
    linewidth=1,
    legend_show=false,
  );

local gitalySpawnTimeoutsPerNode() =
  basic.timeseries(
    title='Gitaly Spawn Timeouts per Node',
    description='Golang uses a global lock on process spawning. In order to control contention on this lock Gitaly uses a safety valve. If a request is unable to obtain the lock within a period, a timeout occurs. These timeouts are serious and should be addressed. Non-zero is bad.',
    query=|||
      changes(gitaly_spawn_timeouts_total{environment="$environment", stage="$stage"}[$__interval])
    |||,
    legendFormat='{{ fqdn }}',
    interval='1m',
    linewidth=1,
    legend_show=false,
  );


dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['type:gitaly'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.stage)
.addTemplate(templates.sigma)
.addPanels(keyMetrics.headlineMetricsRow('gitaly', '$stage', startRow=0))
.addPanel(serviceHealth.row('gitaly', '$stage'), gridPos={ x: 0, y: 1000 })
.addPanel(
  row.new(title='Node Performance'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    perNodeApdex(),
    inflightGitalyCommandsPerNode(),
    readThroughput(),
    writeThroughput(),
  ], startRow=2001)
)
.addPanel(
  row.new(title='Gitaly Safety Mechanisms'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    gitalySpawnTimeoutsPerNode(),
    ratelimitLockPercentage(),
  ], startRow=3001)
)
.addPanel(keyMetrics.keyServiceMetricsRow('gitaly', '$stage'), gridPos={ x: 0, y: 4000 })
.addPanel(keyMetrics.keyComponentMetricsRow('gitaly', '$stage'), gridPos={ x: 0, y: 5000 })
.addPanel(nodeMetrics.nodeMetricsDetailRow(selector), gridPos={ x: 0, y: 6000 })
.addPanel(
  saturationDetail.saturationDetailPanels(selector, components=[
    'cgroup_memory',
    'cpu',
    'disk_space',
    'disk_sustained_read_iops',
    'disk_sustained_read_throughput',
    'disk_sustained_write_iops',
    'disk_sustained_write_throughput',
    'memory',
    'open_fds',
    'single_node_cpu',
    'go_memory',
  ]),
  gridPos={ x: 0, y: 6000, w: 24, h: 1 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'gitaly',
    'goserver',
    selector,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'goserver' },
      { title: 'per Node', aggregationLabels: 'fqdn', legendFormat: '{{ fqdn }}' },
    ],
  ), gridPos={ x: 0, y: 7000 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'gitaly',
    'gitalyruby',
    selector,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'gitalyruby' },
      { title: 'per Node', aggregationLabels: 'fqdn', legendFormat: '{{ fqdn }}' },
    ],
  ), gridPos={ x: 0, y: 7100 }
)
.addPanel(capacityPlanning.capacityPlanningRow('gitaly', '$stage'), gridPos={ x: 0, y: 8000 })
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('gitaly') + platformLinks.services +
          [platformLinks.dynamicLinks('Gitaly Detail', 'type:gitaly')],
}
