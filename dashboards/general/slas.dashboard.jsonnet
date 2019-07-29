local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local colors = import 'colors.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

local slaBarGauge(
  title,
  query,
  legendFormat
  ) = {
      options: {
        displayMode: "gradient",
        fieldOptions: {
          calcs: [
            "last"
          ],
          defaults: {
            decimals: 1,
            max: 1,
            min: 0,
            unit: "percentunit"
          },
          mappings: [],
          override: {},
          thresholds: [{
            color: "green",
            index: 0,
            value: null
          }],
          values: false
        },
        orientation: "horizontal"
      },
      targets: [
        {
          expr: query,
          format: "time_series",
          instant: true,
          interval: "",
          intervalFactor: 1,
          legendFormat: legendFormat,
          refId: "A"
        }
      ],
      timeFrom: null,
      timeShift: null,
      title: title,
      type: "bargauge"
    };

dashboard.new(
  'SLAs',
  schemaVersion=16,
  tags=['overview'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
  time_from='now-30d',
  time_to='now',
  timepicker={
    refresh_intervals: [],
    time_options: [
      '7d',
      '14d',
      '30d',
      '45d',
      '60d',
      '90d',
      '120d',
      '180d',
    ]
  },
)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanel(row.new(title="Headline"),
  gridPos={
      x: 0,
      y: 0,
      w: 24,
      h: 1,
  }
)
.addPanels(layout.grid([
    grafana.singlestat.new(
      'SLA Status',
      datasource="$PROMETHEUS_DS",
      format='percentunit',
    )
    .addTarget(
      promQuery.target('sort(
          avg(
            avg_over_time(slo_observation_status{environment="$environment", stage=~"main|", type=~"web|api|git|ci-runners|pages|sidekiq"}[$__range])
          )
        )',
        instant=true
      )
    ),
  ], cols=6,rowHeight=5, startRow=1)
)
.addPanels(layout.grid([
    basic.slaTimeseries(
      title='SLA Trends - Aggregated',
      description="1w rolling average SLO adherence across all primary services. Higher is better.",
      yAxisLabel='SLA',
      query='
        avg(avg_over_time(slo_observation_status{environment="gprd", stage=~"main|", type=~"pages|web|api|git|sidekiq|registry"}[7d]))
      ',
      legendFormat='gitlab.com SLA',
      intervalFactor=5,
    ),
  ], cols=1,rowHeight=10, startRow=1001)
)

.addPanel(row.new(title="Primary Services"),
  gridPos={
      x: 0,
      y: 2000,
      w: 24,
      h: 1,
  }
)
.addPanels(layout.grid([
    slaBarGauge(
      title="Primary Services Average Availability for Period",
      query='
        sort(avg(avg_over_time(slo_observation_status{environment="$environment", stage=~"main|", type=~"web|api|git|ci-runners|pages|sidekiq"}[$__range])) by (type))
      ',
      legendFormat='{{ type }}'
    ),
    basic.slaTimeseries(
      title='SLA Trends - Primary Services',
      description="1w rolling average SLO adherence for primary services. Higher is better.",
      yAxisLabel='SLA',
      query='
        avg(avg_over_time(slo_observation_status{environment="gprd", stage=~"main|", type=~"pages|web|api|git|sidekiq|registry"}[7d])) by (type)
      ',
      legendFormat='{{ type }}',
      intervalFactor=5,
    ),
  ], cols=1,rowHeight=10, startRow=2001)
)
+ {
  links+: platformLinks.services + platformLinks.triage
}


