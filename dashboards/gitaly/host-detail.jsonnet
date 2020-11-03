local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local processExporter = import 'process_exporter.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';

local ratelimitLockPercentage(selector) =
  basic.percentageTimeseries(
    'Request % acquiring rate-limit lock within 1m, by host + method',
    description='Percentage of requests that acquire a Gitaly rate-limit lock within 1 minute, by host and method',
    query=|||
      sum(
        rate(
          gitaly_rate_limiting_acquiring_seconds_bucket{
            %(selector)s,
            le="60"
          }[$__interval]
        )
      ) by (environment, tier, type, stage, fqdn, grpc_method)
      /
      sum(
        rate(
          gitaly_rate_limiting_acquiring_seconds_bucket{
            %(selector)s,
            le="+Inf"
          }[$__interval]
        )
      ) by (environment, tier, type, stage, fqdn, grpc_method)
    ||| % { selector: selector },
    legendFormat='{{fqdn}} - {{grpc_method}}'
  );

local inflightGitalyCommandsPerNode(selector) =
  basic.timeseries(
    title='Inflight Git Commands per Server',
    description='Number of Git commands running concurrently per node. Lower is better.',
    query=|||
      avg_over_time(gitaly_commands_running{%(selector)s}[$__interval])
    ||| % { selector: selector },
    legendFormat='{{ fqdn }}',
    interval='1m',
    linewidth=1,
    legend_show=false,
  );

local gitalySpawnTimeoutsPerNode(selector) =
  basic.timeseries(
    title='Gitaly Spawn Timeouts per Node',
    description='Golang uses a global lock on process spawning. In order to control contention on this lock Gitaly uses a safety valve. If a request is unable to obtain the lock within a period, a timeout occurs. These timeouts are serious and should be addressed. Non-zero is bad.',
    query=|||
      increase(gitaly_spawn_timeouts_total{%(selector)s}[$__interval])
    ||| % { selector: selector },
    legendFormat='{{ fqdn }}',
    interval='1m',
    linewidth=1,
    legend_show=false,
  );


local environmentSelectorHash = {
  environment: '$environment',
  env: '$environment',
};

local selectorHash = {
  fqdn: { re: '$fqdn' },
};

local selector = selectors.serializeHash(selectorHash);

local headlineRow(startRow=1) =
  local metricsCatalogServiceInfo = metricsCatalog.getService('gitaly');
  local serviceSelector = environmentSelectorHash { type: 'gitaly', fqdn: { re: '$fqdn' } };

  local cells =
    (
      if metricsCatalogServiceInfo.hasApdex() then
        [
          keyMetrics.serviceNodeApdexPanel(
            serviceType='gitaly',
            selectorHash=serviceSelector,
            environmentSelectorHash=environmentSelectorHash,
          ),
        ]
      else
        []
    )
    +
    (
      if metricsCatalogServiceInfo.hasErrorRate() then
        [
          keyMetrics.serviceNodeErrorRatePanel(
            serviceType='gitaly',
            selectorHash=serviceSelector,
            environmentSelectorHash=environmentSelectorHash,
          ),
        ]
      else
        []
    )
    +
    [
      keyMetrics.serviceNodeQpsPanel(
        serviceType='gitaly',
        selectorHash=serviceSelector,
        environmentSelectorHash=environmentSelectorHash,
      ),
    ];

  layout.singleRow(cells, startRow=startRow);

basic.dashboard(
  'Host Detail',
  tags=['type:gitaly'],
)
.addTemplate(templates.fqdn(query='gitlab_version_info{type="gitaly", component="gitaly", environment="$environment"}', current='file-01-stor-gprd.c.gitlab-production.internal'))
.addPanels(
  headlineRow(startRow=100)
)
.addPanels(
  metricsCatalogDashboards.componentNodeOverviewMatrix(
    serviceType='gitaly',
    selectorHash=environmentSelectorHash { fqdn: '$fqdn' },
    startRow=200,
    environmentSelectorHash=environmentSelectorHash,
  )
)
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
    inflightGitalyCommandsPerNode(selector),
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
    gitalySpawnTimeoutsPerNode(selector),
    ratelimitLockPercentage(selector),
  ], startRow=3001)
)
.addPanel(nodeMetrics.nodeMetricsDetailRow(selector), gridPos={ x: 0, y: 6000 })
.addPanel(
  saturationDetail.saturationDetailPanels(selectorHash, components=[
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
    selectorHash,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'goserver' },
    ],
  ), gridPos={ x: 0, y: 7000 }
)
.addPanel(
  metricsCatalogDashboards.componentDetailMatrix(
    'gitaly',
    'gitalyruby',
    selectorHash,
    [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'gitalyruby' },
    ],
  ), gridPos={ x: 0, y: 7100 }
)
.addPanel(
  row.new(title='git process activity'),
  gridPos={
    x: 0,
    y: 8000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  processExporter.namedGroup(
    'git processes',
    selectorHash
    {
      groupname: { re: 'git.*' },
    },
    aggregationLabels=['groupname'],
    startRow=8001
  )
)
.addPanel(
  row.new(title='gitaly-ruby process activity'),
  gridPos={
    x: 0,
    y: 9000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  processExporter.namedGroup(
    'gitaly-ruby processes',
    selectorHash
    {
      groupname: 'gitaly-ruby',
    },
    aggregationLabels=[],
    startRow=9001
  )
)

.trailer()
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('gitaly') + platformLinks.services +
          [platformLinks.dynamicLinks('Gitaly Detail', 'type:gitaly')],
}
