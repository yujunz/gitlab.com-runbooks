local colors = import 'grafana/colors.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local annotation = grafana.annotation;
local basic = import 'grafana/basic.libsonnet';

local generalGraphPanel(
  title,
  description=null,
  stableId=null,
      ) =
  basic.graphPanel(
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
    stableId=stableId,
  )
  .addSeriesOverride(seriesOverrides.slo);

local apdexPanel() =
  generalGraphPanel(
    'Latency: Apdex',
    description='Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.',
    stableId='apdex-ratio',
  )
  .addSeriesOverride(seriesOverrides.mainStage)
  .addSeriesOverride(seriesOverrides.cnyStage)
  .addTarget(  // Primary metric
    promQuery.target(
      |||
        min(
          min_over_time(
            gitlab_service_apdex:ratio_5m{environment="$environment", type="$type", stage!=""}[$__interval]
          )
        ) by (stage)
      |||,
      intervalFactor=5,
      legendFormat='{{ stage }} stage',
    )
  )
  .addTarget(  // Min apdex score SLO for gitlab_service_errors:ratio metric
    promQuery.target(
      |||
        avg(slo:min:gitlab_service_apdex:ratio{environment="$environment", type="$type"}) or avg(slo:min:gitlab_service_apdex:ratio{type="$type"})
      |||,
      interval='5m',
      legendFormat='SLO',
    ),
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    max=1,
    label='Apdex %',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  );

local errorRatesPanel() =
  generalGraphPanel(
    'Error Ratios',
    description='Error rates are a measure of unhandled service exceptions within a minute period. Client errors are excluded when possible. Lower is better',
    stableId='error-ratio',
  )
  .addSeriesOverride(seriesOverrides.mainStage)
  .addSeriesOverride(seriesOverrides.cnyStage)
  .addTarget(  // Primary metric
    promQuery.target(
      |||
        max(
          max_over_time(
            gitlab_service_errors:ratio_5m{environment="$environment", type="$type", stage!=""}[$__interval]
          )
        ) by (stage)
      |||,
      intervalFactor=5,
      legendFormat='{{ stage }} stage',
    )
  )
  .addTarget(  // Maximum error rate SLO for gitlab_service_errors:ratio metric
    promQuery.target(
      |||
        avg(slo:max:gitlab_service_errors:ratio{environment="$environment", type="$type"}) or avg(slo:max:gitlab_service_errors:ratio{type="$type"})
      |||,
      interval='5m',
      legendFormat='SLO',
    ),
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    min=0,
    label='% Requests in Error',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  );

local qpsPanel() =
  generalGraphPanel(
    'RPS - Service Requests per Second',
    description='The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier.',
    stableId='request-rate',
  )
  .addSeriesOverride(seriesOverrides.mainStage)
  .addSeriesOverride(seriesOverrides.cnyStage)
  .addTarget(  // Primary metric
    promQuery.target(
      |||
        max(
          avg_over_time(
            gitlab_service_ops:rate{environment="$environment", type="$type", stage!=""}[$__interval]
          )
        ) by (stage)
      |||,
      intervalFactor=5,
      legendFormat='{{ stage }} stage',
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    min=0,
    label='Operations per Second',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  );

basic.dashboard(
  'Service Platform Metrics - Stages',
  tags=['general'],
)
.addTemplate(templates.type)
.addPanel(
  apdexPanel(),
  gridPos={
    x: 0,
    y: 10,
    w: 12,
    h: 10,
  }
)
.addPanel(
  errorRatesPanel(),
  gridPos={
    x: 12,
    y: 10,
    w: 12,
    h: 10,
  }
)
.addPanel(
  qpsPanel(),
  gridPos={
    x: 12,
    y: 20,
    w: 12,
    h: 10,
  }
)
