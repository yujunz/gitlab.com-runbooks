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
local thresholds = import 'thresholds.libsonnet';

// These charts have a very high interval factor, to create a wide trend line
local INTERVAL_FACTOR = 50;
local INTERVAL = '1d';

local timeRegions = {
  timeRegions: [
    {
      op: 'time',
      from: '00:00',
      to: '00:00',
      colorMode: 'gray',
      fill: false,
      line: true,
      lineColor: 'rgba(237, 46, 24, 0.10)',
    },
    {
      op: 'time',
      fromDayOfWeek: 1,
      from: '00:00',
      toDayOfWeek: 1,
      to: '23:59',
      colorMode: 'gray',
      fill: true,
      line: false,
      // lineColor: "rgba(237, 46, 24, 0.80)"
      fillColor: 'rgba(237, 46, 24, 0.80)',
    },
  ],
};

local thresholdsValues = {
  thresholds: [
    thresholds.errorLevel('lt', 0.995),
  ],
};

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

.addPanel(
  grafana.singlestat.new(
    'SLA - GitLab.com',
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
  gridPos={ x: 0, y: 0, w: 4, h: 4 },
)
.addPanel(
  grafana.text.new(
    title='GitLab SLA Dashboard Explainer',
    mode='markdown',
    content=|||
      This dashboard shows the SLA trends for each of the _primary_ services in the GitLab fleet ("primary" services are those which are directly user-facing).

      * For each service we measure two key metrics/SLIs (Service Level Indicators): error-rate and apdex score
      * For each service, for each SLI, we have an SLO target
        * For error-rate, the SLI should remain _below_ the SLO
        * For apdex score, the SLI should remain _above_ the SLO
      * The SLA for each service is the percentage of time that the _both_ SLOs are being met
      * The SLA for GitLab.com is the average SLO across each primary service

      _To see instanteous SLI values for these services, visit the [`general-public-splashscreen`](d/general-public-splashscreen) dashboard._
    |||
  ),
  gridPos={ x: 4, y: 0, w: 20, h: 6 },
)
.addPanels(
  layout.grid([
    basic.slaTimeseries(
      title='Overall SLA over time period - gitlab.com',
      description='Rolling average SLO adherence across all primary services. Higher is better.',
      yAxisLabel='SLA',
      query=|||
        avg(avg_over_time(slo_observation_status{environment="gprd", stage=~"main|", type=~"%(keyServiceRegExp)s"}[$__interval]))
      ||| % { keyServiceRegExp: keyServiceRegExp },
      legendFormat='gitlab.com SLA',
      interval=INTERVAL,
      intervalFactor=INTERVAL_FACTOR,
      points=true,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('gitlab.com SLA'))
    + timeRegions + thresholdsValues,
  ], cols=1, rowHeight=10, startRow=1001)
)
.addPanel(
  row.new(title='SLA Trends - Per Primary Service'),
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
      description='Rolling average SLO adherence for primary services. Higher is better.',
      yAxisLabel='SLA',
      query=|||
        avg(avg_over_time(slo_observation_status{environment="gprd", stage=~"main|", type=~"%(keyServiceRegExp)s"}[$__interval])) by (type)
      ||| % { keyServiceRegExp: keyServiceRegExp },
      legendFormat='{{ type }}',
      interval=INTERVAL,
      intervalFactor=INTERVAL_FACTOR,
      points=true,
    ) + timeRegions + thresholdsValues,
  ], cols=1, rowHeight=10, startRow=2001)
)
+ {
  links+: platformLinks.services + platformLinks.triage,
}
