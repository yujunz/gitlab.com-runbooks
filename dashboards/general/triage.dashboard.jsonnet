local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local thresholds = import 'thresholds.libsonnet';
local colors = import 'colors.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;

local rowHeight = 8;
local colWidth = 12;

local genGridPos(x,y,h=1,w=1) = {
  x: x * colWidth,
  y: y * rowHeight,
  w: w * colWidth,
  h: h * rowHeight,
};

local generalGraphPanel(
  title,
  description=null
) = graphPanel.new(
    title,
    datasource="$PROMETHEUS_DS",
    linewidth=2,
    fill=0,
    description=description,
    decimals=2,
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

local generateAnomalyPanel(
  title,
  query,
  minY=6,
  maxY=6,
  errorThreshold=8,
  warningThreshold=6,
  ) =
  graphPanel.new(
    title,
    datasource="$PROMETHEUS_DS",
    description="Each timeseries represents the distance, in standard deviations, that each service is away from its normal range. The further from zero, the more anomalous",
    linewidth=2,
    fill=0,
    decimals=2,
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
      thresholds.errorLevel("gt", errorThreshold),
      thresholds.warningLevel("gt", warningThreshold),
      thresholds.warningLevel("lt", -warningThreshold),
      thresholds.errorLevel("lt", -errorThreshold),
    ]
  )
  .addTarget(
    promQuery.target(
      '
      clamp_min(
        clamp_max(
          avg(
                ' + query + '
            ) by (type),
          ' + maxY + '),
        ' + minY + ')
      ',
      legendFormat='{{ type }} service',
      intervalFactor=3,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    label="Sigma σ",
    min=minY,
    max=maxY,
    show=true,
    decimals=1,
  )
  .addYaxis(
    format='none',
    label="",
    show=false
  );

local activeAlertsPanel = grafana.tablePanel.new(
    'Active Alerts',
    datasource="$PROMETHEUS_DS",
    styles=[{
      "type": "hidden",
      "pattern": "Time",
      "alias": "Time",
    }, {
      "unit": "short",
      "type": "string",
      "alias": "Service",
      "decimals": 2,
      "pattern": "type",
      "dateFormat": "YYYY-MM-DD HH:mm:ss",
      "mappingType": 2,
      "link": true,
      "linkUrl": "https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=${__cell}&var-environment=$environment",
      "linkTooltip": "Open dashboard",
    },
    {
      "unit": "short",
      "type": "number",
      "alias": "Score",
      "decimals": 0,
      "colors": [
        colors.warningColor,
        colors.errorColor,
        colors.criticalColor
      ],
      "colorMode": "row",
      "pattern": "Value",
      "thresholds": [
        "100",
        "10000"
      ],
      "mappingType": 1
    }
  ],
  )
  .addTarget( // Alert scoring
    promQuery.target('
      sort(
        sum(
          ALERTS{environment="$environment", type!="", severity="critical", alertstate="firing"} * 10000
          or
          ALERTS{environment="$environment", type!="", severity="error", alertstate="firing"} * 100
          or
          ALERTS{environment="$environment", type!="", severity="warn", alertstate="firing"}
        ) by (type)
      )
      ',
      format="table",
      instant=true
    )
  );

dashboard.new(
  'Platform Triage',
  schemaVersion=16,
  tags=['general'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.stage)
.addPanel(activeAlertsPanel, gridPos=genGridPos(0,0,w=2,h=0.5))
.addPanel(
  generalGraphPanel(
    "Latency: Apdex",
    description="Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.",
  )
  .addTarget( // Primary metric
    promQuery.target('
      avg(
        gitlab_service_apdex:ratio{environment="$environment", stage="$stage"}
      ) by (type)
      ',
      legendFormat='{{ type }} service',
      intervalFactor=3,
    )
  )
  .addTarget( // SLO Violations
    promQuery.target('
      avg(
          gitlab_service_apdex:ratio{environment="$environment", stage="$stage"}
      ) by (type)
      <= on(type) group_left
      avg(slo:min:gitlab_service_apdex:ratio) by (type)
      ',
      legendFormat='{{ type }} SLO violation',
      intervalFactor=3,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    max=1,
    label="Apdex %",
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  , gridPos=genGridPos(0, 0.5)
)
.addPanel(
  generateAnomalyPanel(
    'Anomaly detection: Latency: Apdex Score',
    '
      (
        gitlab_service_apdex:ratio{environment="$environment", stage="$stage"}
        - gitlab_service_apdex:ratio:avg_over_time_1w{environment="$environment", stage="$stage"}
      )
      /
      gitlab_service_apdex:ratio:stddev_over_time_1w{environment="$environment", stage="$stage"}
  ',
  maxY=0.5,
  minY=-12
  )
  ,
  gridPos=genGridPos(1, 0.5)
)
.addPanel(
  generalGraphPanel(
    "Error Ratios",
    description="Error rates are a measure of unhandled service exceptions within a minute period. Client errors are excluded when possible. Lower is better"
  )
  .addTarget( // Primary metric
    promQuery.target('
      avg(
        max_over_time(
          gitlab_service_errors:ratio{environment="$environment", stage="$stage"}[$__interval]
        )
      ) by (type)
      ',
      legendFormat='{{ type }} service',
      intervalFactor=3,
    )
  )
  .addTarget( // SLO Violations
    promQuery.target('
      avg(
        gitlab_service_errors:ratio{environment="$environment", stage="$stage"}
      ) by (type)
      >= on(type) group_left
      avg(slo:max:gitlab_service_errors:ratio) by (type)
      ',
      legendFormat='{{ type }} SLO violation',
      intervalFactor=3,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    min=0,
    label="% Requests in Error",
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  , gridPos=genGridPos(0, 1.5)
)
.addPanel(
  generateAnomalyPanel(
    'Anomaly detection: Error Ratio',
    '
      (
        gitlab_service_errors:ratio{environment="$environment", stage="$stage"}
        - gitlab_service_errors:ratio:avg_over_time_1w{environment="$environment", stage="$stage"}
      )
      /
      gitlab_service_errors:ratio:stddev_over_time_1w{environment="$environment", stage="$stage"}
  ',
  maxY=12,
  minY=-0.5
  )
  , gridPos=genGridPos(1, 1.5)
)
.addPanel(
  generalGraphPanel(
    "Service Requests per Second",
    description="The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier."
  )
  .addTarget( // Primary metric
    promQuery.target('
      sum(
        gitlab_service_ops:rate{environment="$environment", stage="$stage"}
      ) by (type)
      ',
      legendFormat='{{ type }} service',
      intervalFactor=3,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    label="Operations per Second",
    logBase=10,
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  , gridPos=genGridPos(0, 2.5)
)
.addPanel(
  generateAnomalyPanel(
    'Anomaly detection: Requests per second',
    '
      (
        gitlab_service_ops:rate{environment="$environment", stage="$stage"}
        -
        gitlab_service_ops:rate:prediction{environment="$environment", stage="$stage"}
      )
      /
      gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", stage="$stage"}
  ',
  maxY=6,
  minY=-3,
  errorThreshold=4,
  warningThreshold=3,

  )
  , gridPos=genGridPos(1, 2.5)
)
.addPanel(
  generalGraphPanel(
    "Service Availability",
    description="Availability measures the ratio of component processes in the service that are currently healthy and able to handle requests. The closer to 100% the better."
  )
  .addTarget( // Primary metric
    promQuery.target('
      min(
        min_over_time(
          gitlab_service_availability:ratio{environment="$environment", stage="$stage"}[$__interval]
        )
      ) by (type)
      ',
      legendFormat='{{ type }} service',
      intervalFactor=3,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    max=1,
    label="Availability %",
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  , gridPos=genGridPos(0, 3.5)
)
.addPanel(
  generateAnomalyPanel(
    'Anomaly detection: Availability',
    '
      (
      gitlab_service_availability:ratio{environment="$environment", stage="$stage"}
      -
      gitlab_service_availability:ratio:avg_over_time_1w{environment="$environment", stage="$stage"}
      )
      /
      gitlab_service_availability:ratio:stddev_over_time_1w{environment="$environment", stage="$stage"}
  ',
  maxY=0.5,
  minY=-12
  )
  , gridPos=genGridPos(1, 3.5)
)
