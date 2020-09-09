local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'service_dashboard.libsonnet';
local colors = import 'grafana/colors.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local multiburnFactors = import 'mwmbr/multiburn_factors.libsonnet';

local selector = 'environment="$environment", type="gitaly", stage="$stage"';

local gitalyServiceInfo = metricsCatalog.getService('gitaly');

local hostChart(
  title,
  query,
  valueColumnTitle,
  thresholds,
  thresholdColors,
  sortDescending
      ) =
  grafana.tablePanel.new(
    title,
    datasource='$PROMETHEUS_DS',
    styles=[
      {
        type: 'hidden',
        pattern: 'Time',
        alias: 'Time',
      },
      {
        unit: 'short',
        type: 'string',
        alias: 'fqdn',
        decimals: 2,
        pattern: 'fqdn',
        mappingType: 2,
        link: true,
        linkUrl: '/d/gitaly-host-detail/gitaly-host-detail?orgId=1&var-environment=$environment&var-stage=$stage&var-fqdn=${__cell}',
        linkTooltip: 'Click to navigate to Gitaly Host Detail Dashboard',
      },
      {
        unit: 'percentunit',
        type: 'number',
        alias: valueColumnTitle,
        decimals: 2,
        colors: thresholdColors,
        colorMode: 'row',
        pattern: 'Value',
        thresholds: thresholds,
        mappingType: 1,
      },
    ],
  )
  .addTarget(
    promQuery.target(
      query,
      format='table',
      instant=true
    )
  ) + {
    sort: {
      col: null,
      desc: sortDescending,
    },
  };

serviceDashboard.overview('gitaly', 'stor')
.addPanel(
  row.new(title='Node Investigation'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    hostChart(
      title='Worst Performing Gitaly Nodes by Apdex Score SLI',
      query=|||
        bottomk(8,
          avg by (fqdn) (
            gitlab_service_node_apdex:ratio_5m{environment="$environment", type="gitaly", stage="$stage"}
          )
        )
      |||,
      valueColumnTitle='Apdex Score',
      thresholds=[
        multiburnFactors.apdexRatioThreshold1h(gitalyServiceInfo.monitoringThresholds.apdexScore),
        multiburnFactors.apdexRatioThreshold6h(gitalyServiceInfo.monitoringThresholds.apdexScore),
      ],
      thresholdColors=[
        colors.criticalColor,
        colors.errorColor,
        colors.black,
      ],
      sortDescending=true
    ),
    hostChart(
      title='Worst Performing Gitaly Nodes by Error Rate SLI',
      query=|||
        topk(8,
          avg by (fqdn) (
            gitlab_service_node_errors:ratio_5m{environment="$environment", type="gitaly", stage="$stage"}
          )
        )
      |||,
      valueColumnTitle='Error Rate',
      thresholds=[
        multiburnFactors.errorRatioThreshold6h(gitalyServiceInfo.monitoringThresholds.errorRatio),
        multiburnFactors.errorRatioThreshold1h(gitalyServiceInfo.monitoringThresholds.errorRatio),
      ],
      thresholdColors=[
        colors.black,
        colors.errorColor,
        colors.criticalColor,
      ],
      sortDescending=false
    ),

  ], startRow=2001, cols=2)
)
.overviewTrailer()
