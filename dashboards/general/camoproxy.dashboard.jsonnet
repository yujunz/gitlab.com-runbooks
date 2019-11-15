local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

local generalGraphPanel(
  title,
  description=null
      ) = graphPanel.new(
  title,
  linewidth=1,
  fill=0,
  datasource='$PROMETHEUS_DS',
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
  legend_hideEmpty=true,
);

local requestsPanel() =
  generalGraphPanel(
    'Requests',
    description='Requests per second',
  )
  .addTarget(
    promQuery.target(
      'sum by (code) (rate(camo_responses_total{environment="$environment"}[$__interval]))',
      interval='30s',
      intervalFactor=1,
      legendFormat='{{code}}',
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    min=0,
    label='Requests/s',
  )
  .addYaxis(
    format='short',
    show=false,
  );

local trafficPanel() =
  generalGraphPanel(
    'Traffic',
    description='Traffic, in bytes per second',
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camo_response_size_bytes_sum{environment="$environment"}[$__interval]))',
      interval='30s',
      legendFormat='Bytes/s',
    )
  )
  .resetYaxes()
  .addYaxis(
    format='Bps',
    min=0,
    label='Bytes/s',
  )
  .addYaxis(
    format='short',
    show=false,
  );

local eventPanel() =
  generalGraphPanel(
    'Request Failures',
    description='Failed requests',
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camo_proxy_reponses_failed_total{environment="$environment"}[$__interval]))',
      interval='30s',
      legendFormat='Failed Responses',
    )
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camo_proxy_content_length_exceeded_total{environment="$environment"}[$__interval]))',
      interval='30s',
      legendFormat='Content Length Exceeded - --max-size exceeded',
    )
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camo_proxy_reponses_truncated_total{environment="$environment"}[$__interval]))',
      interval='30s',
      legendFormat='Response Truncated - --max-size exceeded',
    )
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camo_responses_total{environment="$environment",code="504"}[$__interval]))',
      interval='30s',
      legendFormat='504 - Gateway Timeout - maybe --timeout exceeded',
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    min=0,
    label='Events/s',
  )
  .addYaxis(
    format='short',
    show=false,
  );

local envTemplate = template.new(
  'environment',
  '$PROMETHEUS_DS',
  'label_values(up{job="camoproxy"}, environment)',
  current='gprd',
  refresh='time',
  sort=1,
);

dashboard.new(
  'Camoproxy',
  schemaVersion=16,
  tags=['general'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(envTemplate)
.addPanel(
  requestsPanel(),
  gridPos={
    x: 0,
    y: 10,
    w: 12,
    h: 10,
  }
)
.addPanel(
  trafficPanel(),
  gridPos={
    x: 12,
    y: 10,
    w: 12,
    h: 10,
  }
)
.addPanel(
  eventPanel(),
  gridPos={
    x: 0,
    y: 20,
    w: 24,
    h: 10,
  }
)
