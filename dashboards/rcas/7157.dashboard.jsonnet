local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;

local commonAnnotations = import 'common_annotations.libsonnet';
local templates = import 'templates.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local text = grafana.text;

dashboard.new(
  '2019-07-01 Degraded performance on GitLab.com',
  schemaVersion=16,
  tags=['rca', 'redis-cache'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
  time_from='2019-07-01 00:00:00',
  time_to='2019-07-04 00:00:00',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanels(layout.grid([
  text.new(
    title='Web apdex',
    mode='markdown',
    content=|||
      Slowdown in webservices was the first sign of a problem.
    |||
  ),
  keyMetrics.apdexPanel(serviceType='web', serviceStage='main'),

  // ------------------------------------------------------

  text.new(
    title='A slowdown across multiple services in the fleet',
    mode='markdown',
    content=|||
      Single core saturation in the main Redis cache cluster lead to slowdowns across multiple other services.
    |||
  ),
  basic.saturationTimeseries(
    title='Single core saturation on the redis-cache fleet',
    query=|||
      max(1 - rate(node_cpu_seconds_total{environment="$environment", type="redis-cache", mode="idle", fqdn=~"redis-cache-\\d\\d.*"}[$__interval]))
    |||,
    legendFormat='Max Single Core Saturation',
  )
  .addSeriesOverride(seriesOverrides.goldenMetric('Max Single Core Saturation')),

  // ------------------------------------------------------

  text.new(
    title='Redis-cache network traffic',
    mode='markdown',
    content=|||
      Huge volumes of traffic, particularly application settings, was being sent from the cache to the web instances at a very high rate.
    |||
  ),
  basic.networkTrafficGraph(
    title='Single core saturation on the redis-cache fleet',
    sendQuery=|||
      sum(rate(redis_net_output_bytes_total{environment="$environment", type="redis-cache"}[$__interval]))
    |||,
    receiveQuery=|||
      sum(rate(redis_net_input_bytes_total{environment="$environment", type="redis-cache"}[$__interval]))
    |||,
    intervalFactor=2
  ),

  // ------------------------------------------------------

  text.new(
    title='Redis CPU',
    mode='markdown',
    content=''
  ),
  basic.saturationTimeseries(
    title='Redis CPU',
    query=|||
      max(
        (
          rate(redis_cpu_user_seconds_total{environment="gprd", type="redis-cache"}[$__interval]) + rate(redis_cpu_sys_seconds_total{environment="gprd", type="redis-cache"}[$__interval])
        )
        or
        (
          rate(redis_used_cpu_user{environment="gprd", type="redis-cache"}[$__interval]) + rate(redis_used_cpu_sys{environment="gprd", type="redis-cache"}[$__interval])
        )
      )
    |||,
    legendFormat='Redis CPU',
  ),

], cols=2, rowHeight=10, startRow=1))
+ {
  annotations: {
    list+: [
      {
        datasource: 'Pagerduty',
        enable: true,
        hide: false,
        iconColor: '#F2495C',
        limit: 100,
        name: 'GitLab Production Pagerduty',
        serviceId: 'PATDFCE',
        showIn: 0,
        tags: [],
        type: 'tags',
        urgency: 'high',
      },
      {
        datasource: 'Pagerduty',
        enable: true,
        hide: false,
        iconColor: '#C4162A',
        limit: 100,
        name: 'GitLab Production SLO',
        serviceId: 'P7Q44DU',
        showIn: 0,
        tags: [],
        type: 'tags',
        urgency: 'high',
      },
      {
        datasource: 'Simple Annotations',
        enable: true,
        hide: false,
        iconColor: '#5794F2',
        limit: 100,
        name: 'Key Events',
        // To be completed...
        queries: [
        ],
        showIn: 0,
        tags: [],
        type: 'tags',
      },
    ],
  },
}
