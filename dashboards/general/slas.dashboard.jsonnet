local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local row = grafana.row;
local thresholds = import 'thresholds.libsonnet';
local grafanaCalHeatmap = import 'grafana-cal-heatmap-panel/panel.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

// These charts have a very high interval factor, to create a wide trend line
local INTERVAL_FACTOR = 50;
local INTERVAL = '1d';

// Preferred ordering of rows on the SLA dashboard
local serviceOrdering = [
  'web',
  'git',
  'api',
  'ci-runners',
  'registry',
  'web-pages',
];

local overviewDashboardLinks(type) =
  local formatConfig = { type: type };
  [
    {
      url: '/d/%(type)s-main/%(type)s-overview?orgId=1&${__url_time_range}' % formatConfig,
      title: '%(type)s service: Overview Dashboard' % formatConfig,
    },
  ];

local thresholdsValues = {
  thresholds: [
    thresholds.errorLevel('lt', 0.995),
  ],
};

// Note, by having a overall_sla_weighting value, even if it is zero, the service will
// be included on the SLA dashboard. To remove it, delete the key
local keyServices = serviceCatalog.findServices(function(service)
  std.objectHas(service.business.SLA, 'overall_sla_weighting') && service.business.SLA.overall_sla_weighting >= 0);

local keyServiceRegExp = std.join('|', std.map(function(service) service.name, keyServices));

local keyServiceSorter(service) =
  local l = std.find(service.name, serviceOrdering);
  if l == [] then
    100
  else
    l[0];

// NB: this query takes into account values recorded in Prometheus prior to
// https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
// Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
// This is encoded in the `defaultSelector`
local serviceAvailabilityQuery(selectorHash, metricName, rangeInterval) =
  local defaultSelector = {
    env: { re: 'ops|$environment' },
    environment: '$environment',
    stage: 'main',
    monitor: { re: 'global|' },
  };

  |||
    avg(
      clamp_max(
        avg_over_time(%(metricName)s{%(selector)s}[%(rangeInterval)s]),
        1
      )
    )
  ||| % {
    selector: selectors.serializeHash(defaultSelector + selectorHash),
    metricName: metricName,
    rangeInterval: rangeInterval,
  };

local serviceRow(service) =
  local links = overviewDashboardLinks(service.name);
  [
    basic.slaStats(
      title='',
      query=serviceAvailabilityQuery({ type: service.name }, 'slo_observation_status', '$__range'),
      legendFormat='{{ type }}',
      displayName=service.friendly_name,
      links=links,
    ),
    grafanaCalHeatmap.heatmapCalendarPanel(
      '',
      query=serviceAvailabilityQuery({ type: service.name }, 'slo_observation_status', '1d'),
      legendFormat='',
      datasource='$PROMETHEUS_DS',
    ),
    basic.slaTimeseries(
      title='%s: SLA Trends ' % [service.friendly_name],
      description='Rolling average SLO adherence for primary services. Higher is better.',
      yAxisLabel='SLA',
      query=serviceAvailabilityQuery({ type: service.name }, 'slo_observation_status', '1d'),
      legendFormat='{{ type }}',
      interval=INTERVAL,
      points=true,
      legend_show=false
    )
    .addDataLink(links) + thresholdsValues +
    {
      options: { dataLinks: links },
    },
  ];

local primaryServiceRows = std.map(serviceRow, std.sort(keyServices, keyServiceSorter));

basic.dashboard(
  'SLAs',
  tags=['general', 'slas', 'service-levels'],
  includeStandardEnvironmentAnnotations=false,
  time_from='now-1M/M',
  time_to='now-1d/d',
)
.addPanel(
  row.new(title='Overall System Availability'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.columnGrid([[
    basic.slaStats(
      title='GitLab.com Availability',
      query=serviceAvailabilityQuery({ }, 'sla:gitlab:ratio', '$__range'),
    ),
    grafanaCalHeatmap.heatmapCalendarPanel(
      'Calendar',
      query=serviceAvailabilityQuery({ }, 'sla:gitlab:ratio', '1d'),
      legendFormat='',
      datasource='$PROMETHEUS_DS',
    ),
    basic.slaTimeseries(
      title='Overall SLA over time period - gitlab.com',
      description='Rolling average SLO adherence across all primary services. Higher is better.',
      yAxisLabel='SLA',
      query=serviceAvailabilityQuery({ }, 'sla:gitlab:ratio', '1d'),
      legendFormat='gitlab.com SLA',
      interval=INTERVAL,
      points=true,
      legend_show=false
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('gitlab.com SLA'))
    + thresholdsValues,
  ]], [4, 4, 16], rowHeight=5, startRow=1)
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
  layout.columnGrid(primaryServiceRows, [4, 4, 16], rowHeight=5, startRow=2101)
)
.addPanels(
  layout.grid([
    grafana.text.new(
      title='GitLab SLA Dashboard Explainer',
      mode='markdown',
      content=|||
        This dashboard shows the SLA trends for each of the _primary_ services in the GitLab fleet ("primary" services are those which are directly user-facing).

        Read more details on our [SLA policy is defined in the handbook](https://about.gitlab.com/handbook/engineering/monitoring/).

        * For each service we measure two key metrics/SLIs (Service Level Indicators): error-rate and apdex score
        * For each service, for each SLI, we have an SLO target
          * For error-rate, the SLI should remain _below_ the SLO
          * For apdex score, the SLI should remain _above_ the SLO
        * The SLA for each service is the percentage of time that the _both_ SLOs are being met
        * The SLA for GitLab.com is the average SLO across each primary service

        _To see instanteous SLI values for these services, visit the [`general-public-splashscreen`](d/general-public-splashscreen) dashboard._
      |||
    ),
  ], cols=1, rowHeight=10, startRow=3001)
)
.trailer()
+ {
  links+: platformLinks.services + platformLinks.triage,
}
