local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'grafana/colors.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local thresholds = import 'thresholds.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local basic = import 'grafana/basic.libsonnet';
local sliPromQL = import 'sli_promql.libsonnet';

local rowHeight = 8;
local colWidth = 12;

local genGridPos(x, y, h=1, w=1) = {
  x: x * colWidth,
  y: y * rowHeight,
  w: w * colWidth,
  h: h * rowHeight,
};

local generalGraphPanel(title, description=null, sort='increasing') =
  graphPanel.new(
    title,
    datasource='$PROMETHEUS_DS',
    linewidth=2,
    fill=0,
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
  .addSeriesOverride(seriesOverrides.sloViolation);

local generateAnomalyPanel(title, query, minY=6, maxY=6, errorThreshold=8, warningThreshold=6, sort='increasing') =
  graphPanel.new(
    title,
    datasource='$PROMETHEUS_DS',
    description='Each timeseries represents the distance, in standard deviations, that each service is away from its normal range. The further from zero, the more anomalous',
    linewidth=2,
    fill=0,
    decimals=2,
    sort=sort,
    legend_show=true,
    legend_values=false,
    legend_min=false,
    legend_max=false,
    legend_current=false,
    legend_total=false,
    legend_avg=false,
    legend_alignAsTable=false,
    legend_hideEmpty=true,
    thresholds=[
      thresholds.errorLevel('gt', errorThreshold),
      thresholds.warningLevel('gt', warningThreshold),
      thresholds.warningLevel('lt', -warningThreshold),
      thresholds.errorLevel('lt', -errorThreshold),
    ]
  )
  .addTarget(
    promQuery.target(
      |||
        clamp_min(
          clamp_max(
            avg(%(query)s) by (type),
            %(maxY)f),
          %(minY)f)
      ||| % {
        minY: minY,
        maxY: maxY,
        query: query,
      },
      legendFormat='{{ type }} service',
      intervalFactor=3,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    label='Sigma σ',
    min=minY,
    max=maxY,
    show=true,
    decimals=1,
  )
  .addYaxis(
    format='none',
    label='',
    show=false
  );

local activeAlertsPanel =
  grafana.tablePanel.new(
    'Active Alerts',
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
        alias: 'Service',
        decimals: 2,
        pattern: 'type',
        dateFormat: 'YYYY-MM-DD HH:mm:ss',
        mappingType: 2,
        link: true,
        linkUrl: 'https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=${__cell}&var-environment=$environment',
        linkTooltip: 'Open dashboard',
      },
      {
        unit: 'short',
        type: 'number',
        alias: 'Score',
        decimals: 0,
        colors: [
          colors.warningColor,
          colors.errorColor,
          colors.criticalColor,
        ],
        colorMode: 'row',
        pattern: 'Value',
        thresholds: [
          '100',
          '10000',
        ],
        mappingType: 1,
      },
    ],
  )
  .addTarget(  // Alert scoring
    promQuery.target(
      |||
        sort(
          sum(
            ALERTS{environment="$environment", type!="", severity="s1", alertstate="firing"} * 1000000
            or
            ALERTS{environment="$environment", type!="", severity="s2", alertstate="firing"} * 10000
            or
            ALERTS{environment="$environment", type!="", severity="s3", alertstate="firing"} * 100
            or
            ALERTS{environment="$environment", type!="", severity="s4", alertstate="firing"}
          ) by (type)
        )
      |||,
      format='table',
      instant=true
    )
  );

basic.dashboard(
  'Platform Triage',
  tags=['general'],
)
.addTemplate(templates.stage)
.addPanel(activeAlertsPanel, gridPos=genGridPos(0, 0, w=2, h=0.5))
.addPanel(
  generalGraphPanel(
    'Latency: Apdex',
    description='Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.',
    sort='increasing',
  )
  .addTarget(  // Primary metric
    promQuery.target(
      sliPromQL.apdex.serviceApdexQuery({ environment: '$environment', stage: '$stage' }, range='$__interval'),
      legendFormat='{{ type }} service',
      intervalFactor=3,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    max=1,
    label='Apdex %',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  ),
  gridPos=genGridPos(0, 0.5, w=2)
)
.addPanel(
  generalGraphPanel(
    'Error Ratios',
    description='Error rates are a measure of unhandled service exceptions within a minute period. Client errors are excluded when possible. Lower is better',
    sort='decreasing',
  )
  .addTarget(  // Primary metric
    promQuery.target(
      sliPromQL.errorRate.serviceErrorRateQuery({ environment: '$environment', stage: '$stage' }, range='$__interval', clampMax=0.15),
      legendFormat='{{ type }} service',
      intervalFactor=3,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    min=0,
    label='% Requests in Error',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  ),
  gridPos=genGridPos(0, 1.5, w=2)
)
.addPanel(
  generalGraphPanel(
    'Service Requests per Second',
    description='The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier.',
    sort='decreasing',
  )
  .addTarget(  // Primary metric
    promQuery.target(
      sliPromQL.opsRate.serviceOpsRateQuery({ environment: '$environment', stage: '$stage' }, range='$__interval'),
      legendFormat='{{ type }} service',
      intervalFactor=3,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    label='Operations per Second',
    logBase=10,
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  ),
  gridPos=genGridPos(0, 2.5)
)
.addPanel(
  generateAnomalyPanel(
    'Anomaly detection: Requests per second',
    |||
      (
        gitlab_service_ops:rate{environment="$environment", stage="$stage"}
        -
        gitlab_service_ops:rate:prediction{environment="$environment", stage="$stage"}
      )
      /
      gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", stage="$stage"}
    |||,
    maxY=6,
    minY=-3,
    errorThreshold=4,
    warningThreshold=3,
    sort='decreasing',
  ),
  gridPos=genGridPos(1, 2.5)
)
.addPanel(
  // TODO: get rid of this: aggregating these saturation values in this manner makes litter sense
  generalGraphPanel(
    'Saturation',
    description='Saturation is a measure of the most saturated component of the service. Lower is better.',
    sort='decreasing',
  )
  .addTarget(  // Primary metric
    promQuery.target(
      |||
        max(
          max_over_time(
            gitlab_component_saturation:ratio{environment="$environment", stage="$stage"}[$__interval]
          )
        ) by (type)
      |||,
      legendFormat='{{ type }} service',
      intervalFactor=3,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    max=1,
    label='Availability %',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  ),
  gridPos=genGridPos(0, 4.5, w=2)
)
.addPanel(capacityPlanning.environmentCapacityPlanningRow(''), gridPos=genGridPos(0, 6.5))
+ {
  links+: platformLinks.capacityPlanning + platformLinks.services,
}
