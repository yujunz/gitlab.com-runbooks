local basic = import 'basic.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceDashboard = import 'service_dashboard.libsonnet';
local thresholds = import 'thresholds.libsonnet';

serviceDashboard.overview(
  'monitoring',
  'inf',
  environmentSelectorHash={ environment: 'ops', env: 'ops', type: 'monitoring', stage: '$stage' },
  saturationEnvironmentSelectorHash={ environment: { re: 'ops|gprd|ci-prd' }, type: 'monitoring', stage: '$stage' }
)
.addPanel(
  row.new(title='Grafana Latencies'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(layout.grid([
  basic.latencyTimeseries(
    title='Grafana API Dataproxy (logn scale)',
    legend_show=false,
    format='ms',
    query=|||
      grafana_api_dataproxy_request_all_milliseconds{environment="ops", quantile="0.5"}
    |||,
    legendFormat='p50 {{ fqdn }}',
    intervalFactor=2,
    logBase=10,
    min=10
  )
  .addTarget(
    promQuery.target(
      |||
        grafana_api_dataproxy_request_all_milliseconds{environment="ops", quantile="0.9"}
      |||,
      legendFormat='p90 {{ fqdn }}',
      intervalFactor=2,
    )
  )
  .addTarget(
    promQuery.target(
      |||
        grafana_api_dataproxy_request_all_milliseconds{environment="ops", quantile="0.99"}
      |||,
      legendFormat='p99 {{ fqdn }}',
      intervalFactor=2,
    )
  ) + {
    thresholds: [
      thresholds.warningLevel('gt', 10000),
      thresholds.errorLevel('gt', 30000),
    ],
  },
], cols=1, rowHeight=10, startRow=1001))
.overviewTrailer()
