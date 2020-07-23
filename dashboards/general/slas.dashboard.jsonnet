local basic = import 'basic.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local row = grafana.row;
local thresholds = import 'thresholds.libsonnet';

// These charts have a very high interval factor, to create a wide trend line
local INTERVAL_FACTOR = 50;
local INTERVAL = '1d';

local overviewDashboardLinks = [
  {
    url: '/d/${__field.label.type}-main/${__field.label.type}-overview?orgId=1',
    title: '${__field.label.type} service: Overview Dashboard',
  },
];

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
  std.objectHas(service.business.SLA, 'overall_sla_weighting') && service.business.SLA.overall_sla_weighting > 0);

local keyServiceRegExp = std.join('|', std.map(function(service) service.name, keyServices));

basic.dashboard(
  'SLAs',
  tags=['general', 'slas', 'service-levels'],
  includeStandardEnvironmentAnnotations=false,
  time_from='now-7d/d',
  time_to='now/d',
)
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
  basic.slaStats(
    title='Weighted Availability Score - GitLab.com',
    // NB: this query takes into account values recorded in Prometheus prior to
    // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
    // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
    query=|||
      avg(
        clamp_max(
          avg_over_time(
            sla:gitlab:ratio{env=~"ops|$environment", environment="$environment", stage="main", monitor=~"global|"}[$__range]
          ),
          1
        )
      )
    |||,
  ),
  gridPos={ x: 0, y: 0, w: 8, h: 8 },
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
  gridPos={ x: 8, y: 0, w: 16, h: 8 },
)
.addPanels(
  layout.grid([
    basic.slaTimeseries(
      title='Overall SLA over time period - gitlab.com',
      description='Rolling average SLO adherence across all primary services. Higher is better.',
      yAxisLabel='SLA',

      // NB: this query takes into account values recorded in Prometheus prior to
      // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
      // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
      query=|||
        avg(
          clamp_max(
            avg_over_time(
              sla:gitlab:ratio{env=~"ops|$environment", environment="$environment", stage="main", monitor=~"global|"}[$__interval]
            ),
            1
          )
        )
      |||,
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
    basic.slaStats(
      title='Primary Services Average Availability for Period',
      // NB: this query takes into account values recorded in Prometheus prior to
      // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
      // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
      query=|||
        avg(
          clamp_max(
            avg_over_time(slo_observation_status{env=~"ops|$environment", environment="$environment", stage="main", type=~"%(keyServiceRegExp)s"}[$__range]),
            1
          )
        ) by (type)
      ||| % { keyServiceRegExp: keyServiceRegExp },
      legendFormat='{{ type }}',
      links=overviewDashboardLinks,
    ),
  ], cols=1, rowHeight=5, startRow=2001)
)
.addPanels(
  layout.grid([
    basic.slaTimeseries(
      title='SLA Trends - Primary Services',
      description='Rolling average SLO adherence for primary services. Higher is better.',
      yAxisLabel='SLA',
      // NB: this query takes into account values recorded in Prometheus prior to
      // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
      // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
      query=|||
        avg(
          avg_over_time(slo_observation_status{env=~"ops|$environment", environment="$environment", stage="main", type=~"%(keyServiceRegExp)s"}[$__interval])
        ) by (type)
      ||| % { keyServiceRegExp: keyServiceRegExp },
      legendFormat='{{ type }}',
      interval=INTERVAL,
      intervalFactor=INTERVAL_FACTOR,
      points=true,
    ) + timeRegions + thresholdsValues +
    {
      options: { dataLinks: overviewDashboardLinks },
    },
  ], cols=1, rowHeight=10, startRow=2101)
)
.trailer()
+ {
  links+: platformLinks.services + platformLinks.triage,
}
