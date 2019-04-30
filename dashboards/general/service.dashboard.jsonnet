local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local colors = import 'colors.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;

local generalGraphPanel(
  title,
  description=null
) = graphPanel.new(
    title,
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
    legend_rightSide=true,
    legend_hideEmpty=true,
  )
  .addSeriesOverride(seriesOverrides.upper)
  .addSeriesOverride(seriesOverrides.lower)
  .addSeriesOverride(seriesOverrides.lastWeek)
  .addSeriesOverride(seriesOverrides.alertFiring)
  .addSeriesOverride(seriesOverrides.alertPending)
  .addSeriesOverride(seriesOverrides.slo);

local activeAlertsPanel = grafana.tablePanel.new(
    'Active Alerts',
    styles=[{
      "type": "hidden",
      "pattern": "Time",
      "alias": "Time",
    }, {
      "unit": "short",
      "type": "string",
      "alias": "Alert",
      "decimals": 2,
      "pattern": "alertname",
      "mappingType": 2,
      "link": true,
      "linkUrl": "https://alerts.${environment}.gitlab.net/#/alerts?filter=%7Balertname%3D%22${__cell}%22%2C%20env%3D%22${environment}%22%2C%20type%3D%22${type}%22%7D",
      "linkTooltip": "Open alertmanager",
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
        "2",
        "3"
      ],
      "mappingType": 1
    }
  ],
  )
  .addTarget( // Alert scoring
    promQuery.target('
      sort(
        max(
        ALERTS{environment="$environment", type="$type", severity="critical", alertstate="firing"} * 3
        or
        ALERTS{environment="$environment", type="$type", severity="error", alertstate="firing"} * 2
        or
        ALERTS{environment="$environment", type="$type", severity="warn", alertstate="firing"}
        ) by (alertname, severity)
      )
      ',
      format="table",
      instant=true
    )
  );

dashboard.new(
  'Service Platform Metrics',
  schemaVersion=16,
  tags=['general'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.type)
.addTemplate(templates.sigma)
.addPanel(activeAlertsPanel, gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 10,
})
.addPanel(
  generalGraphPanel(
    "Latency: Apdex",
    description="Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.",
  )
  .addSeriesOverride(seriesOverrides.goldenMetric("/ service$/"))
  .addTarget( // Primary metric
    promQuery.target('
      min(
        avg_over_time(
          gitlab_service_apdex:ratio{environment="$environment", type="$type"}[$__interval]
        )
      ) by (type)
      ',
      legendFormat='{{ type }} service',
    )
  )
  .addTarget( // Min apdex score SLO for gitlab_service_errors:ratio metric
    promQuery.target('
        avg(slo:min:gitlab_service_apdex:ratio{environment="$environment", type="$type"}) or avg(slo:min:gitlab_service_apdex:ratio{type="$type"})
      ',
      interval="5m",
      legendFormat='SLO',
    ),
  )
  .addTarget( // Last week
    promQuery.target('
      min(
        avg_over_time(
          gitlab_service_apdex:ratio{environment="$environment", type="$type"}[$__interval] offset 1w
        )
      ) by (type)
      ',
      legendFormat='last week',
    )
  )
  .addTarget(
    promQuery.target('
      avg(
        clamp_max(
          gitlab_service_apdex:ratio:avg_over_time_1w{environment="$environment", type="$type"} +
          $sigma * gitlab_service_apdex:ratio:stddev_over_time_1w{environment="$environment", type="$type"},
          1
        )
      )
      ',
      legendFormat='upper normal',
    ),
  )
  .addTarget(
    promQuery.target('
      avg(
        clamp_min(
          gitlab_service_apdex:ratio:avg_over_time_1w{environment="$environment", type="$type"} -
          2 * gitlab_service_apdex:ratio:stddev_over_time_1w{environment="$environment", type="$type"},
          0
        )
      )
      ',
      legendFormat='lower normal',
    ),
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
    y: 0,
    w: 24,
    h: 10,
  }
)
.addPanel(
  generalGraphPanel(
    "Error Ratios",
    description="Error rates are a measure of unhandled service exceptions within a minute period. Client errors are excluded when possible. Lower is better"
  )
  .addSeriesOverride(seriesOverrides.goldenMetric("/ service$/"))
  .addTarget( // Primary metric
    promQuery.target('
      min(
        max_over_time(
          gitlab_service_errors:ratio{component="", service="", environment="$environment", type="$type"}[$__interval]
        )
      ) by (type)
      ',
      legendFormat='{{ type }} service',
    )
  )
  .addTarget( // Maximum error rate SLO for gitlab_service_errors:ratio metric
    promQuery.target('
        avg(slo:max:gitlab_service_errors:ratio{environment="$environment", type="$type"}) or avg(slo:max:gitlab_service_errors:ratio{type="$type"})
      ',
      interval="5m",
      legendFormat='SLO',
    ),
  )
  .addTarget( // Last week
    promQuery.target('
      min(
        max_over_time(
          gitlab_service_errors:ratio{component="", service="", environment="$environment", type="$type"}[$__interval] offset 1w
        )
      ) by (type)
      ',
      legendFormat='last week',
    )
  )
  .addTarget(
    promQuery.target('
      avg(
        (
          gitlab_service_errors:ratio:avg_over_time_1w{component="", service="", environment="$environment", type="$type"} +
          $sigma * gitlab_service_errors:ratio:stddev_over_time_1w{component="", service="", environment="$environment", type="$type"}
        )
      )
      ',
      legendFormat='upper normal',
    ),
  )
  .addTarget(
    promQuery.target('
      avg(
        clamp_min(
          gitlab_service_errors:ratio:avg_over_time_1w{component="", service="", environment="$environment", type="$type"} -
          $sigma * gitlab_service_errors:ratio:stddev_over_time_1w{environment="$environment", type="$type"},
          0
        )
      )
      ',
      legendFormat='lower normal',
    ),
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
    y: 0,
    w: 24,
    h: 10,
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
          gitlab_service_availability:ratio{environment="$environment", type="$type"}[$__interval]
        )
      ) by (tier, type)
      ',
      legendFormat='{{ type }} service',
    )
  )
  .addTarget( // Last week
    promQuery.target('
      min(
        min_over_time(
          gitlab_service_availability:ratio{environment="$environment", type="$type"}[$__interval] offset 1w
        )
      ) by (tier, type)
      ',
      legendFormat='last week',
    )
  )

  .addTarget( // Upper sigma bound
    promQuery.target('
      avg(
        clamp_max(
          gitlab_service_availability:ratio:avg_over_time_1w{environment="$environment", type="$type"} +
          $sigma * gitlab_service_availability:ratio:stddev_over_time_1w{environment="$environment", type="$type"},
        1)
      )
      ',
      legendFormat='upper normal',
    ),
  )
  .addTarget( // Lower sigma bound
    promQuery.target('
      avg(
        clamp_min(
          gitlab_service_availability:ratio:avg_over_time_1w{environment="$environment", type="$type"} -
          $sigma * gitlab_service_availability:ratio:stddev_over_time_1w{environment="$environment", type="$type"},
          0
        )
      )
      ',
      legendFormat='lower normal',
    ),
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
    y: 0,
    w: 24,
    h: 10,
  }
)
.addPanel(
  generalGraphPanel(
    "Service Operation Rates - per Second",
    description="The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier."
  )
  .addTarget( // Primary metric
    promQuery.target('
      max(
        avg_over_time(
          gitlab_service_ops:rate{environment="$environment", type="$type"}[$__interval]
        )
      ) by (type)
      ',
      legendFormat='{{ type }} service',
    )
  )
  .addTarget( // Last week
    promQuery.target('
      max(
        avg_over_time(
          gitlab_service_ops:rate{environment="$environment", type="$type"}[$__interval] offset 1w
        )
      ) by (type)
      ',
      legendFormat='last week',
    )
  )
  .addTarget(
    promQuery.target('
      gitlab_service_ops:rate:prediction{environment="$environment", type="$type"} +
      ($sigma / 2) * gitlab_service_ops:rate:stddev_over_time_1w{component="", environment="$environment", type="$type"}
      ',
      legendFormat='upper normal',
    ),
  )
  .addTarget(
    promQuery.target('
      avg(
        clamp_min(
          gitlab_service_ops:rate:prediction{environment="$environment", type="$type"} -
          ($sigma / 2) * gitlab_service_ops:rate:stddev_over_time_1w{component="", environment="$environment", type="$type"},
          0
        )
      )
      ',
      legendFormat='lower normal',
    ),
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    min=0,
    label="Operations per Second",
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )

  , gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 10,
  }
)
