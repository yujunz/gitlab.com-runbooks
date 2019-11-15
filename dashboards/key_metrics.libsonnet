local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

local generalGraphPanel(title, description=null, linewidth=2, sort='increasing', legend_show=true) =
  graphPanel.new(
    title,
    linewidth=linewidth,
    fill=0,
    datasource='$PROMETHEUS_DS',
    description=description,
    decimals=2,
    sort=sort,
    legend_show=legend_show,
    legend_values=true,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=false,
    legend_avg=true,
    legend_alignAsTable=true,
    legend_hideEmpty=true,
  )
  .addSeriesOverride(seriesOverrides.goldenMetric('/ service/'))
  .addSeriesOverride(seriesOverrides.upper)
  .addSeriesOverride(seriesOverrides.lower)
  .addSeriesOverride(seriesOverrides.upperLegacy)
  .addSeriesOverride(seriesOverrides.lowerLegacy)
  .addSeriesOverride(seriesOverrides.lastWeek)
  .addSeriesOverride(seriesOverrides.alertFiring)
  .addSeriesOverride(seriesOverrides.alertPending)
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)
  .addSeriesOverride(seriesOverrides.slo);


{
  apdexPanel(serviceType, serviceStage, compact=false)::
    local formatConfig = { serviceType: serviceType, serviceStage: serviceStage };
    generalGraphPanel(
      'Latency: Apdex',
      description='Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.',
      sort=0,
      legend_show=!compact,
      linewidth=if compact then 1 else 2,
    )
    .addTarget(  // Primary metric
      promQuery.target(
        |||
          min(
            min_over_time(
              gitlab_service_apdex:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]
            )
          ) by (type)
        ||| % formatConfig,
        legendFormat='{{ type }} service',
      )
    )
    .addTarget(  // Legacy metric - remove 2020-01-01
      promQuery.target(
        |||
          min(
            min_over_time(
              gitlab_service_apdex:ratio{environment="$environment", type="%(serviceType)s", stage=""}[$__interval]
            )
          ) by (type)
        ||| % formatConfig,
        legendFormat='{{ type }} service (legacy)',
      )
    )
    .addTarget(  // Min apdex score SLO for gitlab_service_errors:ratio metric
      promQuery.target(
        |||
          avg(slo:min:gitlab_service_apdex:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}) or avg(slo:min:gitlab_service_apdex:ratio{type="%(serviceType)s"})
        ||| % formatConfig,
        interval='5m',
        legendFormat='Degradation SLO',
      ),
    )
    .addTarget(  // Double apdex SLO is Outage-level SLO
      promQuery.target(
        |||
          2 * (avg(slo:min:gitlab_service_apdex:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}) or avg(slo:min:gitlab_service_apdex:ratio{type="%(serviceType)s"})) - 1
        ||| % formatConfig,
        interval='5m',
        legendFormat='Outage SLO',
      ),
    )
    .addTarget(  // Last week
      promQuery.target(
        |||
          min(
            min_over_time(
              gitlab_service_apdex:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval] offset 1w
            )
          ) by (type)
        ||| % formatConfig,
        legendFormat='last week',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label=if compact then '' else 'Apdex %',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  componentApdexPanel(serviceType, serviceStage)::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
    };
    generalGraphPanel(
      'Component Latency: Apdex',
      description='Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.',
      linewidth=1,
      sort='increasing',
    )
    .addTarget(  // Primary metric
      promQuery.target(
        |||
          min(
            min_over_time(
              gitlab_component_apdex:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]
            )
          ) by (component)
        ||| % formatConfig,
        legendFormat='{{ component }} component',
      )
    )
    .addTarget(  // Min apdex score SLO for gitlab_service_errors:ratio metric
      promQuery.target(
        |||
          avg(slo:min:gitlab_service_apdex:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}) or avg(slo:min:gitlab_service_apdex:ratio{type="%(serviceType)s"})
        ||| % formatConfig,
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
    ),

  errorRatesPanel(serviceType, serviceStage, compact=false, includeLastWeek=true)::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
    };
    generalGraphPanel(
      'Error Ratios',
      description='Error rates are a measure of unhandled service exceptions within a minute period. Client errors are excluded when possible. Lower is better',
      sort=0,
      legend_show=!compact,
      linewidth=if compact then 1 else 2,
    )
    .addTarget(  // Primary metric
      promQuery.target(
        |||
          max(
            max_over_time(
              gitlab_service_errors:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]
            )
          ) by (type)
        ||| % formatConfig,
        legendFormat='{{ type }} service',
      )
    )
    .addTarget(  // Legacy metric - remove 2020-01-01
      promQuery.target(
        |||
          max(
            max_over_time(
              gitlab_service_errors:ratio{environment="$environment", type="%(serviceType)s", stage=""}[$__interval]
            )
          ) by (type)
        ||| % formatConfig,
        legendFormat='{{ type }} service (legacy)',
      )
    )
    .addTarget(  // Maximum error rate SLO for gitlab_service_errors:ratio metric
      promQuery.target(
        |||
          avg(slo:max:gitlab_service_errors:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}) or avg(slo:max:gitlab_service_errors:ratio{type="%(serviceType)s"})
        ||| % formatConfig,
        interval='5m',
        legendFormat='Degradation SLO',
      ),
    )
    .addTarget(  // Outage level SLO
      promQuery.target(
        |||
          2 * (avg(slo:max:gitlab_service_errors:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}) or avg(slo:max:gitlab_service_errors:ratio{type="%(serviceType)s"}))
        ||| % formatConfig,
        interval='5m',
        legendFormat='Outage SLO',
      ),
    )
    .addTarget(  // Last week
      promQuery.target(
        |||
          max(
            max_over_time(
              gitlab_service_errors:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval] offset 1w
            )
          ) by (type)
        ||| % formatConfig,
        legendFormat='last week',
      ) + {
        [if !includeLastWeek then 'hide']: true,
      }
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      min=0,
      label=if compact then '' else '% Requests in Error',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  componentErrorRates(serviceType, serviceStage)::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
    };
    generalGraphPanel(
      'Component Error Rates - modified scale: (1 + n) log10',
      description='Error rates are a measure of unhandled service exceptions per second. Client errors are excluded when possible. Lower is better',
      linewidth=1,
      sort='decreasing',
    )
    .addTarget(  // Primary metric
      promQuery.target(
        |||
          1 +
          (
            60 *
            max(
              max_over_time(
                gitlab_component_errors:rate{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]
              )
            ) by (component)
          )
        ||| % formatConfig,
        legendFormat='{{ component }} component',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='short',
      label='Errors per Minute',
      logBase=10,
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  serviceAvailabilityPanel(serviceType, serviceStage):: self.componentAvailabilityPanel(serviceType, serviceStage),

  componentAvailabilityPanel(serviceType, serviceStage)::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
    };
    generalGraphPanel(
      'Component Availability',
      description='Availability measures the ratio of component processes in the service that are currently healthy and able to handle requests. The closer to 100% the better.',
      linewidth=1,
      sort='decreasing',
    )
    .addTarget(  // Primary metric
      promQuery.target(
        |||
          min(
            min_over_time(
              gitlab_component_availability:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]
            )
          ) by (component)
        ||| % formatConfig,
        legendFormat='{{ component }} component',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label='Availability %',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  qpsPanel(serviceType, serviceStage, compact=false)::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
    };
    generalGraphPanel(
      'RPS - Service Requests per Second',
      description='The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier.',
      sort=0,
      legend_show=!compact,
      linewidth=if compact then 1 else 2,
    )
    .addTarget(  // Primary metric
      promQuery.target(
        |||
          max(
            avg_over_time(
              gitlab_service_ops:rate{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]
            )
          ) by (type)
        ||| % formatConfig,
        legendFormat='{{ type }} service',
      )
    )
    .addTarget(  // Legacy metric - remove 2020-01-01
      promQuery.target(
        |||
          max(
            avg_over_time(
              gitlab_service_ops:rate{environment="$environment", type="%(serviceType)s", stage=""}[$__interval]
            )
          ) by (type)
        ||| % formatConfig,
        legendFormat='{{ type }} service (legacy)',
      )
    )
    .addTarget(  // Last week
      promQuery.target(
        |||
          max(
            avg_over_time(
              gitlab_service_ops:rate{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval] offset 1w
            )
          ) by (type)
        ||| % formatConfig,
        legendFormat='last week',
      )
    )
    .addTarget(
      promQuery.target(
        |||
          gitlab_service_ops:rate:prediction{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"} +
          2 * gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
        ||| % formatConfig,
        legendFormat='upper normal',
      ),
    )
    .addTarget(
      promQuery.target(
        |||
          avg(
            clamp_min(
              gitlab_service_ops:rate:prediction{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"} -
              2 * gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"},
              0
            )
          )
        ||| % formatConfig,
        legendFormat='lower normal',
      ),
    )
    .addTarget(  // Legacy metric - remove 2020-01-01
      promQuery.target(
        |||
          gitlab_service_ops:rate:prediction{environment="$environment", type="%(serviceType)s", stage=""} +
          2 * gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", type="%(serviceType)s", stage=""}
        ||| % formatConfig,
        legendFormat='upper normal (legacy)',
      ),
    )
    .addTarget(  // Legacy metric - remove 2020-01-01
      promQuery.target(
        |||
          avg(
            clamp_min(
              gitlab_service_ops:rate:prediction{environment="$environment", type="%(serviceType)s", stage=""} -
              2 * gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", type="%(serviceType)s", stage=""},
              0
            )
          )
        ||| % formatConfig,
        legendFormat='lower normal (legacy)',
      ),
    )
    .resetYaxes()
    .addYaxis(
      format='short',
      min=0,
      label=if compact then '' else 'Operations per Second',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  componentQpsPanel(serviceType, serviceStage)::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
    };
    generalGraphPanel(
      'Component RPS - Requests per Second',
      description='The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier.',
      linewidth=1,
      sort='decreasing',
    )
    .addTarget(  // Primary metric
      promQuery.target(
        |||
          1 +
          max(
            avg_over_time(
              gitlab_component_ops:rate{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]
            )
          ) by (component)
        ||| % formatConfig,
        legendFormat='{{ component }} component',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='reqps',
      label='Requests per Second',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  saturationPanel(serviceType, serviceStage, compact=false):: self.componentSaturationPanel(serviceType, serviceStage, compact),

  componentSaturationPanel(serviceType, serviceStage, compact=false)::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
    };
    generalGraphPanel(
      'Saturation',
      description='Saturation is a measure of what ratio of a finite resource is currently being utilized. Lower is better.',
      sort='decreasing',
      legend_show=!compact,
      linewidth=if compact then 1 else 2,
    )
    .addTarget(  // Primary metric
      promQuery.target(
        |||
          max(
            max_over_time(
              gitlab_component_saturation:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]
            )
          ) by (component)
        ||| % formatConfig,
        legendFormat='{{ component }} component',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label=if compact then '' else 'Saturation %',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),
  headlineMetricsRow(serviceType, serviceStage, startRow)::
    layout.grid([
      row.new(title='🗞️ Headline Metrics - 𝘦𝘹𝘱𝘢𝘯𝘥 𝘬𝘦𝘺 𝘴𝘦𝘳𝘷𝘪𝘤𝘦 𝘮𝘦𝘵𝘳𝘪𝘤𝘴 𝘳𝘰𝘸 𝘧𝘰𝘳 𝘥𝘦𝘵𝘢𝘪𝘭𝘴', collapse=false),
    ], cols=1, rowHeight=1, startRow=startRow)
    +
    layout.grid([
      self.apdexPanel(serviceType, serviceStage, compact=true),
      self.errorRatesPanel(serviceType, serviceStage, compact=true),
      self.qpsPanel(serviceType, serviceStage, compact=true),
      self.saturationPanel(serviceType, serviceStage, compact=true),
    ], cols=4, rowHeight=5, startRow=startRow + 1),

  keyServiceMetricsRow(serviceType, serviceStage):: row.new(title='🏅 Key Service Metrics', collapse=true)
                                                    .addPanels(layout.grid([
    self.apdexPanel(serviceType, serviceStage),
    self.errorRatesPanel(serviceType, serviceStage),
    self.serviceAvailabilityPanel(serviceType, serviceStage),
    self.qpsPanel(serviceType, serviceStage),
    self.saturationPanel(serviceType, serviceStage),
  ])),
  keyComponentMetricsRow(serviceType, serviceStage):: row.new(title='🔩 Service Component Metrics', collapse=true)
                                                      .addPanels(layout.grid([
    self.componentApdexPanel(serviceType, serviceStage),
    self.componentErrorRates(serviceType, serviceStage),
    self.componentAvailabilityPanel(serviceType, serviceStage),
    self.componentQpsPanel(serviceType, serviceStage),
    self.componentSaturationPanel(serviceType, serviceStage),
  ])),
}
