local basic = import 'basic.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

local keyServices = serviceCatalog.findServices(function(service)
  std.objectHas(service.business.SLA, 'primary_sla_service') &&
  service.business.SLA.primary_sla_service);

local keyServiceRegExp = std.join('|', std.map(function(service) service.name, keyServices));

local slaBarGauge(title, query, legendFormat) = {
  options: {
    displayMode: 'gradient',
    fieldOptions: {
      calcs: [
        'last',
      ],
      defaults: {
        decimals: 1,
        max: 1,
        min: 0,
        unit: 'percentunit',
      },
      mappings: [],
      override: {},
      thresholds: [{
        color: 'green',
        index: 0,
        value: null,
      }],
      values: false,
    },
    orientation: 'horizontal',
  },
  targets: [
    {
      expr: query,
      format: 'time_series',
      instant: true,
      interval: '',
      intervalFactor: 1,
      legendFormat: legendFormat,
      refId: 'A',
    },
  ],
  timeFrom: null,
  timeShift: null,
  title: title,
  type: 'bargauge',
};

dashboard.new(
  'SLAs',
  schemaVersion=16,
  tags=['overview'],
  timezone='utc',
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
    ],
  },
)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanel(
  row.new(title='Headline'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    grafana.singlestat.new(
      'SLA Status',
      datasource='$PROMETHEUS_DS',
      format='percentunit',
    )
    .addTarget(
      promQuery.target(
        |||
          sort(
            avg(
              avg_over_time(slo_observation_status{environment="$environment", stage=~"main|", type=~"%(keyServiceRegExp)s"}[$__range])
            )
          )
        ||| % { keyServiceRegExp: keyServiceRegExp },
        instant=true
      )
    ),
  ], cols=6, rowHeight=5, startRow=1)
)
.addPanels(
  layout.grid([
    basic.slaTimeseries(
      title='SLA Trends - Aggregated',
      description='1w rolling average SLO adherence across all primary services. Higher is better.',
      yAxisLabel='SLA',
      query=|||
        avg(avg_over_time(slo_observation_status{environment="gprd", stage=~"main|", type=~"%(keyServiceRegExp)s"}[7d]))
      ||| % { keyServiceRegExp: keyServiceRegExp },
      legendFormat='gitlab.com SLA',
      intervalFactor=5,
    ),
  ], cols=1, rowHeight=10, startRow=1001)
)
.addPanel(
  row.new(title='Primary Services'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    slaBarGauge(
      title='Primary Services Average Availability for Period',
      query=|||
        sort(avg(avg_over_time(slo_observation_status{environment="$environment", stage=~"main|", type=~"%(keyServiceRegExp)s"}[$__range])) by (type))
      ||| % { keyServiceRegExp: keyServiceRegExp },
      legendFormat='{{ type }}'
    ),
    basic.slaTimeseries(
      title='SLA Trends - Primary Services',
      description='1w rolling average SLO adherence for primary services. Higher is better.',
      yAxisLabel='SLA',
      query=|||
        avg(avg_over_time(slo_observation_status{environment="gprd", stage=~"main|", type=~"%(keyServiceRegExp)s"}[7d])) by (type)
      ||| % { keyServiceRegExp: keyServiceRegExp },
      legendFormat='{{ type }}',
      intervalFactor=5,
    ),
  ], cols=1, rowHeight=10, startRow=2001)
)
+ {
  links+: platformLinks.services + platformLinks.triage,
}
