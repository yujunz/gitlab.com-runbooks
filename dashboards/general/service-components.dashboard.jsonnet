local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;

dashboard.new(
  'General Service Component Metrics',
  schemaVersion=16,
  tags=['general'],
  timezone='UTC',
)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.type)
.addTemplate(templates.sigma)
.addPanel(
  graphPanel.new(
    "Service Component Availability",
    linewidth=1,
    fill=0,
  )
  .addTarget( // Primary metric
    prometheus.target('
      min(
        min_over_time(
          gitlab_component_availability:ratio{environment="$environment", type="$type"}[$__interval]
        )
      ) by (tier, type, component)
      ',
      interval="1m",
      legendFormat='{{ component }} component',
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
    y: 0,
    w: 24,
    h: 10,
  }
)
.addPanel(
  graphPanel.new(
    "Service Component Operation Rates",
    linewidth=1,
    fill=0,
  )
  .addTarget( // Primary metric
    prometheus.target('
      sum(
        avg_over_time(
          gitlab_component_ops:rate{environment="$environment", type="$type"}[$__interval]
        )
      ) by (component)
      ',
      interval="1m",
      legendFormat='{{ component }} component',
    )
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
.addPanel(
  graphPanel.new(
    "Service Component Apdex",
    linewidth=1,
    fill=0,
  )
  .addTarget( // Primary metric
    prometheus.target('
      avg(
        avg_over_time(
          gitlab_component_apdex:ratio{environment="$environment", type="$type"}[$__interval]
        )
      ) by (component)
      ',
      interval="1m",
      legendFormat='{{ component }} component',
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
    y: 0,
    w: 24,
    h: 10,
  }
)
.addPanel(
  graphPanel.new(
    "Service Component Error Rates",
    linewidth=1,
    fill=0,
  )
  .addTarget( // Primary metric
    prometheus.target('
      sum(
        avg_over_time(
          gitlab_component_errors:rate{component="", service="", environment="$environment", type="$type"}[$__interval]
        )
      ) by (component) * 60
      ',
      interval="1m",
      legendFormat='{{ component }} component',
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    min=0,
    label="Errors per Minute",
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
