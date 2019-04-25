local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
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
  .addSeriesOverride(seriesOverrides.alertPending);

dashboard.new(
  'TEST General Service Metrics',
  schemaVersion=16,
  tags=['general'],
  timezone='UTC',
)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.type)
.addTemplate(templates.sigma)
.addPanel(
  generalGraphPanel(
    "Latency: Apdex",
    description="Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.",
  )
  .addSeriesOverride(seriesOverrides.goldenMetric("/ service$/"))
  .addTarget( // Primary metric
    prometheus.target('
      avg(
        avg_over_time(
          gitlab_service_apdex:ratio{environment="$environment", type="$type"}[$__interval]
        )
      ) by (type)
      ',
      interval="1m",
      legendFormat='{{ type }} service',
    )
  )
  .addTarget( // Last week
    prometheus.target('
      avg(
        avg_over_time(
          gitlab_service_apdex:ratio{environment="$environment", type="$type"}[$__interval] offset 1w
        )
      ) by (type)
      ',
      interval="1m",
      legendFormat='last week',
    )
  )
  .addTarget(
    prometheus.target('
      avg(
        clamp_max(
          gitlab_service_apdex:ratio:avg_over_time_1w{environment="$environment", type="$type"} +
          $sigma * gitlab_service_apdex:ratio:stddev_over_time_1w{environment="$environment", type="$type"},
          1
        )
      )
      ',
      interval="1m",
      legendFormat='upper normal',
    ),
  )
  .addTarget(
    prometheus.target('
      avg(
        clamp_min(
          gitlab_service_apdex:ratio:avg_over_time_1w{environment="$environment", type="$type"} -
          2 * gitlab_service_apdex:ratio:stddev_over_time_1w{environment="$environment", type="$type"},
          0
        )
      )
      ',
      interval="1m",
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
    prometheus.target('
      sum(
        avg_over_time(
          gitlab_service_errors:ratio{component="", service="", environment="$environment", type="$type"}[$__interval]
        )
      ) by (type)
      ',
      interval="1m",
      legendFormat='{{ type }} service',
    )
  )
  .addTarget( // Last week
    prometheus.target('
      sum(
        avg_over_time(
          gitlab_service_errors:ratio{component="", service="", environment="$environment", type="$type"}[$__interval] offset 1w
        )
      ) by (type)
      ',
      interval="1m",
      legendFormat='last week',
    )
  )
  .addTarget(
    prometheus.target('
      sum(
        (
          gitlab_service_errors:ratio:avg_over_time_1w{component="", service="", environment="$environment", type="$type"} +
          $sigma * gitlab_service_errors:ratio:stddev_over_time_1w{component="", service="", environment="$environment", type="$type"}
        )
      )
      ',
      interval="1m",
      legendFormat='upper normal',
    ),
  )
  .addTarget(
    prometheus.target('
      sum(
        clamp_min(
          gitlab_service_errors:ratio:avg_over_time_1w{component="", service="", environment="$environment", type="$type"} -
          $sigma * gitlab_service_errors:ratio:stddev_over_time_1w{environment="$environment", type="$type"},
          0
        )
      )
      ',
      interval="1m",
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
    prometheus.target('
      min(
        min_over_time(
          gitlab_service_availability:ratio{environment="$environment", type="$type"}[$__interval]
        )
      ) by (tier, type)
      ',
      interval="1m",
      legendFormat='{{ type }} service',
    )
  )
  .addTarget( // Last week
    prometheus.target('
      min(
        min_over_time(
          gitlab_service_availability:ratio{environment="$environment", type="$type"}[$__interval] offset 1w
        )
      ) by (tier, type)
      ',
      interval="1m",
      legendFormat='last week',
    )
  )

  .addTarget( // Upper sigma bound
    prometheus.target('
      min(
        clamp_max(
          gitlab_service_availability:ratio:avg_over_time_1w{environment="$environment", type="$type"} +
          $sigma * gitlab_service_availability:ratio:stddev_over_time_1w{environment="$environment", type="$type"},
        1)
      )
      ',
      interval="1m",
      legendFormat='upper normal',
    ),
  )
  .addTarget( // Lower sigma bound
    prometheus.target('
      min(
        clamp_min(
          gitlab_service_availability:ratio:avg_over_time_1w{environment="$environment", type="$type"} -
          $sigma * gitlab_service_availability:ratio:stddev_over_time_1w{environment="$environment", type="$type"},
          0
        )
      )
      ',
      interval="1m",
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
    prometheus.target('
      sum(
        avg_over_time(
          gitlab_service_ops:rate{environment="$environment", type="$type"}[$__interval]
        )
      ) by (type)
      ',
      interval="1m",
      legendFormat='{{ type }} service',
    )
  )
  .addTarget( // Last week
    prometheus.target('
      sum(
        avg_over_time(
          gitlab_service_ops:rate{environment="$environment", type="$type"}[$__interval] offset 1w
        )
      ) by (type)
      ',
      interval="1m",
      legendFormat='last week',
    )
  )
  .addTarget(
    prometheus.target('
      gitlab_service_ops:rate:prediction{environment="$environment", type="$type"} +
      ($sigma / 2) * gitlab_service_ops:rate:stddev_over_time_1w{component="", environment="$environment", type="$type"}
      ',
      interval="1m",
      legendFormat='upper normal',
    ),
  )
  .addTarget(
    prometheus.target('
      sum(
        clamp_min(
          gitlab_service_ops:rate:prediction{environment="$environment", type="$type"} -
          ($sigma / 2) * gitlab_service_ops:rate:stddev_over_time_1w{component="", environment="$environment", type="$type"},
          0
        )
      )
      ',
      interval="1m",
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
