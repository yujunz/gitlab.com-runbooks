local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local colors = import 'colors.libsonnet';
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
    datasource="$PROMETHEUS_DS",
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

local requestsPanel() = generalGraphPanel(
    "Requests",
    description="Requests per second",
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camoproxy_requests_total{environment="$environment"}[1m]))',
      interval="30s",
      intervalFactor=3,
      legendFormat="Requests/s",
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    min=0,
    label="Requests/s",
  )
  .addYaxis(
    format='short',
    show=false,
  );

local trafficPanel() = generalGraphPanel(
    "Traffic",
    description="Traffic, in bytes per second",
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camoproxy_bytes_total{environment="$environment"}[1m]))',
      interval="30s",
      intervalFactor=3,
      legendFormat="Bytes/s",
    )
  )
  .resetYaxes()
  .addYaxis(
    format='Bps',
    min=0,
    label="Bytes/s",
  )
  .addYaxis(
    format='short',
    show=false,
  );

local eventPanel() = generalGraphPanel(
    "Log Events",
    description="Events detected from logs",
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camoproxy_content_length_exceeded_count{environment="$environment"}[1m]))',
      interval="30s",
      intervalFactor=3,
      legendFormat="Content Length Exceeded -  --max-size exceeded",
    )
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camoproxy_could_not_connect_count{environment="$environment"}[1m]))',
      interval="30s",
      intervalFactor=3,
      legendFormat="Could not connect - maybe --timeout exceeded",
    )
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camoproxy_timeout_expired_count{environment="$environment"}[1m]))',
      interval="30s",
      intervalFactor=3,
      legendFormat="Timeout Expired - --timeout exceeded",
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    min=0,
    label="Events/s",
  )
  .addYaxis(
    format='short',
    show=false,
  );

local envTemplate = template.new(
  "environment",
  "$PROMETHEUS_DS",
  "label_values(camoproxy_bytes_total, environment)",
  current="gprd",
  refresh='load',
  sort=1,
);

dashboard.new(
  'Camoproxy',
  schemaVersion=16,
  tags=['general'],
  timezone='UTC',
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
    w: 24,
    h: 10,
  }
)
.addPanel(
  trafficPanel(),
  gridPos={
    x: 0,
    y: 20,
    w: 24,
    h: 10,
  }
)
.addPanel(
  eventPanel(),
  gridPos={
    x: 0,
    y: 30,
    w: 24,
    h: 10,
  }
)
