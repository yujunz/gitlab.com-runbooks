local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;

local commonAnnotations = import 'common_annotations.libsonnet';
local templates = import 'templates.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local text = grafana.text;
local rcaLayout = import 'rcas/rca.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';

dashboard.new(
  '2019-11-14',
  schemaVersion=16,
  tags=['rca'],
  timezone='utc',
  graphTooltip='shared_crosshair',
  time_from='2019-11-11T00:00:00.000Z',
  time_to='now',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanels(rcaLayout.rcaLayout([
  {
    description: |||
      # Workhorse 502s and 503s

      The rate at which we're experiencing 502 and 503 errors is elevated.
      This could be due to timeouts.

      But what is causing the timeouts?

      Lower is better.
    |||,
    query: |||
      sum(rate(gitlab_workhorse_http_requests_total{code=~"503|502", environment="gprd", env="gprd"}[2h]))
    |||,
  },
  {
    description: |||
      # Web Apdex

      What percentage of web requests complete within the cutoff threshold?

      We can see that latency spikes lead to the 502/503 errors we see in Workhorse, in the top panel

      Higher is better.
    |||,
    panel: keyMetrics.apdexPanel('web', 'main'),
  },
  {
    description: |||
      # Web Errors

      What percentage of web requests fail?

      Lower is better.
    |||,
    panel: keyMetrics.errorRatesPanel('web', 'main', includeLastWeek=false),
  },
  // {
  //   description: |||
  //     # API Apdex

  //     What percentage of API requests complete within the cutoff threshold?

  //     Higher is better.
  //   |||,
  //   panel: keyMetrics.apdexPanel('api', 'main'),
  // },
  {
    description: |||
      # pgbouncer Sync (web/api) pool Saturation
    |||,
    panel: saturationDetail.componentSaturationPanel('pgbouncer_sync_pool', 'environment="$environment", type="pgbouncer", stage="main"'),
  },
  {
    description: |||
      ### Is this being caused by more database traffic?

      # Patroni QPS

      It doesn't appear to be. Patroni QPS seems to be stable over the long term.
    |||,
    panel: keyMetrics.qpsPanel('patroni', 'main'),
  },
]))
