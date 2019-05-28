local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local colors = import 'colors.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;

local rowHeight = 10;

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

local generateAnomalyPanel(title, query) =
  graphPanel.new(
    title,
    datasource="$PROMETHEUS_DS",
    linewidth=1,
    fill=0,
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
  .addTarget(
    promQuery.target(
      query,
      legendFormat='{{ type }} service',
    )
  )
  .resetYaxes()
  .addYaxis(
    format='none',
    label="Sigma σ",
  )
  .addYaxis(
    format='none',
    label="Sigma σ",
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
  'Platform Metrics',
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
.addPanel(activeAlertsPanel, gridPos={
    x: 0,
    y: 0 * rowHeight,
    w: 24,
    h: rowHeight,
})
.addPanel(
  generalGraphPanel(
    "Latency: Apdex",
    description="Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.",
  )
  .addTarget( // Primary metric
    promQuery.target('
      avg(
        avg_over_time(
          gitlab_service_apdex:ratio{environment="$environment", stage="$stage"}[$__interval]
        )
      ) by (type)
      ',
      legendFormat='{{ type }} service',
    )
  )
  .addTarget( // SLO Violations
    promQuery.target('
      avg(
        avg_over_time(
          gitlab_service_apdex:ratio{environment="$environment", stage="$stage"}[$__interval]
        )
      ) by (type)
      <= on(type) group_left
      avg(slo:min:gitlab_service_apdex:ratio) by (type)
      ',
      legendFormat='{{ type }} SLO violation',
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
  , gridPos={
    x: 0,
    y: 1 * rowHeight,
    w: 12,
    h: rowHeight,
  }
)
.addPanel(
  generateAnomalyPanel(
    'Anomaly detection: Latency: Apdex Score',
    '
    avg(
        (
          gitlab_service_apdex:ratio{environment="$environment", stage="$stage"}
          - gitlab_service_apdex:ratio:avg_over_time_1w{environment="$environment", stage="$stage"}
        )
        /
        gitlab_service_apdex:ratio:stddev_over_time_1w{environment="$environment", stage="$stage"}
    ) by (type, stage)
  ')
  , gridPos={
    x: 12,
    y: 1 * rowHeight,
    w: 12,
    h: rowHeight,
  }
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
    )
  )
  .addTarget( // SLO Violations
    promQuery.target('
      avg(
        avg_over_time(
          gitlab_service_errors:ratio{environment="$environment", stage="$stage"}[$__interval]
        )
      ) by (type)
      >= on(type) group_left
      avg(slo:max:gitlab_service_errors:ratio) by (type)
      ',
      legendFormat='{{ type }} SLO violation',
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
  , gridPos={
    x: 0,
    y: 2 * rowHeight,
    w: 12,
    h: rowHeight,
  }
)
.addPanel(
  generateAnomalyPanel(
    'Anomaly detection: Error Ratio',
    '
    avg(
        (
          gitlab_service_errors:ratio{environment="$environment", stage="$stage"}
          - gitlab_service_errors:ratio:avg_over_time_1w{environment="$environment", stage="$stage"}
        )
        /
        gitlab_service_errors:ratio:stddev_over_time_1w{environment="$environment", stage="$stage"}
    ) by (type, stage)
  ')
  , gridPos={
    x: 12,
    y: 2 * rowHeight,
    w: 12,
    h: rowHeight,
  }
)
.addPanel(
  generalGraphPanel(
    "Service Operation Rates - per Second",
    description="The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier."
  )
  .addTarget( // Primary metric
    promQuery.target('
      sum(
        avg_over_time(
          gitlab_service_ops:rate{environment="$environment", stage="$stage"}[$__interval]
        )
      ) by (type)
      ',
      legendFormat='{{ type }} service',
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    min=1,
    label="Operations per Second",
    logBase=10,
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  , gridPos={
    x: 0,
    y: 3 * rowHeight,
    w: 12,
    h: rowHeight,
  }
)
.addPanel(
  generateAnomalyPanel(
    'Anomaly detection: Requests per second',
    '
      avg(
        (
          gitlab_service_ops:rate{environment="$environment", stage="$stage"}
          -
          gitlab_service_ops:rate:prediction{environment="$environment", stage="$stage"}
        )
        /
        gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", stage="$stage"}
      ) by (type)
  ')
  , gridPos={
    x: 12,
    y: 3 * rowHeight,
    w: 12,
    h: rowHeight,
  }
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
  , gridPos={
    x: 0,
    y: 4 * rowHeight,
    w: 12,
    h: rowHeight,
  }
)
.addPanel(
  generateAnomalyPanel(
    'Anomaly detection: Availability',
    '
    avg(
      (
      gitlab_service_availability:ratio{environment="$environment", stage="$stage"}
      -
      gitlab_service_availability:ratio:avg_over_time_1w{environment="$environment", stage="$stage"}
      )
      /
      gitlab_service_availability:ratio:stddev_over_time_1w{environment="$environment", stage="$stage"}
    ) by (tier, type)
  ')
  , gridPos={
    x: 12,
    y: 4 * rowHeight,
    w: 12,
    h: rowHeight,
  }
)
