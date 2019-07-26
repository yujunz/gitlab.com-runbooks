local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local colors = import 'colors.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local layout = import 'layout.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

local generalGraphPanel(
  title,
  description=null,
  linewidth=2,
  sort="increasing",
) = graphPanel.new(
    title,
    linewidth=linewidth,
    fill=0,
    datasource="$PROMETHEUS_DS",
    description=description,
    decimals=2,
    sort=sort,
    legend_show=true,
    legend_values=true,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=false,
    legend_avg=true,
    legend_alignAsTable=true,
    legend_hideEmpty=true,
  )
  .addSeriesOverride(seriesOverrides.goldenMetric("/ service/"))
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
  apdexPanel(serviceType, serviceStage):: generalGraphPanel(
      "Latency: Apdex",
      description="Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.",
      sort=0,
    )
    .addTarget( // Primary metric
      promQuery.target('
        min(
          min_over_time(
            gitlab_service_apdex:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval]
          )
        ) by (type)
        ',
        legendFormat='{{ type }} service',
      )
    )
  .addTarget( // Legacy metric - remove 2020-01-01
      promQuery.target('
        min(
          min_over_time(
            gitlab_service_apdex:ratio{environment="$environment", type="'+ serviceType + '", stage=""}[$__interval]
          )
        ) by (type)
        ',
        legendFormat='{{ type }} service (legacy)',
      )
    )
    .addTarget( // Min apdex score SLO for gitlab_service_errors:ratio metric
      promQuery.target('
          avg(slo:min:gitlab_service_apdex:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}) or avg(slo:min:gitlab_service_apdex:ratio{type="'+ serviceType + '"})
        ',
        interval="5m",
        legendFormat='Degradation SLO',
      ),
    )
    .addTarget( // Double apdex SLO is Outage-level SLO
      promQuery.target('
          2 * (avg(slo:min:gitlab_service_apdex:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}) or avg(slo:min:gitlab_service_apdex:ratio{type="'+ serviceType + '"})) - 1
        ',
        interval="5m",
        legendFormat='Outage SLO',
      ),
    )
    .addTarget( // Last week
      promQuery.target('
        min(
          min_over_time(
            gitlab_service_apdex:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval] offset 1w
          )
        ) by (type)
        ',
        legendFormat='last week',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label="Apdex %",
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

componentApdexPanel(serviceType, serviceStage):: generalGraphPanel(
    "Component Latency: Apdex",
    description="Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.",
    linewidth=1,
    sort="increasing",
  )
  .addTarget( // Primary metric
    promQuery.target('
      min(
        min_over_time(
          gitlab_component_apdex:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval]
        )
      ) by (component)
      ',
      legendFormat='{{ component }} component',
    )
  )
  .addTarget( // Min apdex score SLO for gitlab_service_errors:ratio metric
    promQuery.target('
        avg(slo:min:gitlab_service_apdex:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}) or avg(slo:min:gitlab_service_apdex:ratio{type="'+ serviceType + '"})
      ',
      interval="5m",
      legendFormat='SLO',
    ),
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    max=1,
    label="Apdex %",
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  ),

errorRatesPanel(serviceType, serviceStage)::
  generalGraphPanel(
    "Error Ratios",
    description="Error rates are a measure of unhandled service exceptions within a minute period. Client errors are excluded when possible. Lower is better",
    sort=0,
  )
  .addTarget( // Primary metric
    promQuery.target('
      max(
        max_over_time(
          gitlab_service_errors:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval]
        )
      ) by (type)
      ',
      legendFormat='{{ type }} service',
    )
  )
  .addTarget( // Legacy metric - remove 2020-01-01
    promQuery.target('
      max(
        max_over_time(
          gitlab_service_errors:ratio{environment="$environment", type="'+ serviceType + '", stage=""}[$__interval]
        )
      ) by (type)
      ',
      legendFormat='{{ type }} service (legacy)',
    )
  )
  .addTarget( // Maximum error rate SLO for gitlab_service_errors:ratio metric
    promQuery.target('
        avg(slo:max:gitlab_service_errors:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}) or avg(slo:max:gitlab_service_errors:ratio{type="'+ serviceType + '"})
      ',
      interval="5m",
      legendFormat='Degradation SLO',
    ),
  )
  .addTarget( // Outage level SLO
    promQuery.target('
        2 * (avg(slo:max:gitlab_service_errors:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}) or avg(slo:max:gitlab_service_errors:ratio{type="'+ serviceType + '"}))
      ',
      interval="5m",
      legendFormat='Outage SLO',
    ),
  )
  .addTarget( // Last week
    promQuery.target('
      max(
        max_over_time(
          gitlab_service_errors:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval] offset 1w
        )
      ) by (type)
      ',
      legendFormat='last week',
    )
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    min=0,
    label="% Requests in Error",
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  ),

  componentErrorRates(serviceType, serviceStage)::
    generalGraphPanel(
      "Component Error Rates - modified scale: (1 + n) log10",
      description="Error rates are a measure of unhandled service exceptions per second. Client errors are excluded when possible. Lower is better",
      linewidth=1,
      sort="decreasing",
    )
    .addTarget( // Primary metric
      promQuery.target('
        1 +
        (
          60 *
          max(
            max_over_time(
              gitlab_component_errors:rate{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval]
            )
          ) by (component)
        )
        ',
        legendFormat='{{ component }} component',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='short',
      label="Errors per Minute",
      logBase=10,
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  serviceAvailabilityPanel(serviceType, serviceStage)::
    generalGraphPanel(
      "Service Availability",
      description="Availability measures the ratio of component processes in the service that are currently healthy and able to handle requests. The closer to 100% the better.",
      sort=0,
    )
    .addTarget( // Primary metric
      promQuery.target('
        min(
          min_over_time(
            gitlab_service_availability:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval]
          )
        ) by (tier, type)
        ',
        legendFormat='{{ type }} service',
      )
    )
    .addTarget( // Legacy metric
      promQuery.target('
        min(
          min_over_time(
            gitlab_service_availability:ratio{environment="$environment", type="'+ serviceType + '", stage=""}[$__interval]
          )
        ) by (tier, type)
        ',
        legendFormat='{{ type }} service (legacy)',
      )
    )
    .addTarget( // Last week
      promQuery.target('
        min(
          min_over_time(
            gitlab_service_availability:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval] offset 1w
          )
        ) by (tier, type)
        ',
        legendFormat='last week',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label="Availability %",
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  componentAvailabilityPanel(serviceType, serviceStage)::
    generalGraphPanel(
      "Component Availability",
      description="Availability measures the ratio of component processes in the service that are currently healthy and able to handle requests. The closer to 100% the better.",
      linewidth=1,
      sort="decreasing",
    )
    .addTarget( // Primary metric
      promQuery.target('
        min(
          min_over_time(
            gitlab_component_availability:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval]
          )
        ) by (component)
        ',
        legendFormat='{{ component }} component',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label="Availability %",
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  qpsPanel(serviceType, serviceStage)::
    generalGraphPanel(
      "RPS - Service Requests per Second",
      description="The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier.",
      sort=0,
    )
    .addTarget( // Primary metric
      promQuery.target('
        max(
          avg_over_time(
            gitlab_service_ops:rate{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval]
          )
        ) by (type)
        ',
        legendFormat='{{ type }} service',
      )
    )
    .addTarget( // Legacy metric - remove 2020-01-01
      promQuery.target('
        max(
          avg_over_time(
            gitlab_service_ops:rate{environment="$environment", type="'+ serviceType + '", stage=""}[$__interval]
          )
        ) by (type)
        ',
        legendFormat='{{ type }} service (legacy)',
      )
    )
    .addTarget( // Last week
      promQuery.target('
        max(
          avg_over_time(
            gitlab_service_ops:rate{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval] offset 1w
          )
        ) by (type)
        ',
        legendFormat='last week',
      )
    )
    .addTarget(
      promQuery.target('
        gitlab_service_ops:rate:prediction{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"} +
        2 * gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}
        ',
        legendFormat='upper normal',
      ),
    )
    .addTarget(
      promQuery.target('
        avg(
          clamp_min(
            gitlab_service_ops:rate:prediction{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"} -
            2 * gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"},
            0
          )
        )
        ',
        legendFormat='lower normal',
      ),
    )
    .addTarget( // Legacy metric - remove 2020-01-01
      promQuery.target('
        gitlab_service_ops:rate:prediction{environment="$environment", type="'+ serviceType + '", stage=""} +
        2 * gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", type="'+ serviceType + '", stage=""}
        ',
        legendFormat='upper normal (legacy)',
      ),
    )
    .addTarget( // Legacy metric - remove 2020-01-01
      promQuery.target('
        avg(
          clamp_min(
            gitlab_service_ops:rate:prediction{environment="$environment", type="'+ serviceType + '", stage=""} -
            2 * gitlab_service_ops:rate:stddev_over_time_1w{environment="$environment", type="'+ serviceType + '", stage=""},
            0
          )
        )
        ',
        legendFormat='lower normal (legacy)',
      ),
    )
    .resetYaxes()
    .addYaxis(
      format='short',
      min=0,
      label="Operations per Second",
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  componentQpsPanel(serviceType, serviceStage)::
    generalGraphPanel(
      "Component RPS - Requests per Second",
      description="The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier.",
      linewidth=1,
      sort="decreasing",
    )
    .addTarget( // Primary metric
      promQuery.target('
        1 +
        max(
          avg_over_time(
            gitlab_component_ops:rate{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval]
          )
        ) by (component)
        ',
        legendFormat='{{ component }} component',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='reqps',
      label="Requests per Second",
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  saturationPanel(serviceType, serviceStage)::
    generalGraphPanel(
      "Saturation",
      description="Saturation is a measure of the most saturated component of the service. Lower is better.",
      sort=0,
    )
    .addTarget( // Primary metric
      promQuery.target('
        max(
          max_over_time(
            gitlab_service_saturation:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval]
          )
        ) by (type)
        ',
        legendFormat='{{ type }} service',
      )
    )
    .addTarget( // Min apdex score SLO for gitlab_service_errors:ratio metric
      promQuery.target('
          avg(slo:max:gitlab_service_saturation:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}) or avg(slo:max:gitlab_service_saturation:ratio{type="'+ serviceType + '"})
        ',
        interval="5m",
        legendFormat='SLO',
      ),
    )
    .addTarget( // Last week
      promQuery.target('
          max(
            max_over_time(
              gitlab_service_saturation:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval] offset 1w
            )
          ) by (type)
        ',
        legendFormat='last week',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label="Saturation %",
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  componentSaturationPanel(serviceType, serviceStage)::
    generalGraphPanel(
      "Saturation",
      description="Saturation is a measure of what ratio of a finite resource is currently being utilized. Lower is better.",
      sort="decreasing",
    )
    .addTarget( // Primary metric
      promQuery.target('
        max(
          max_over_time(
            gitlab_component_saturation:ratio{environment="$environment", type="'+ serviceType + '", stage="' + serviceStage + '"}[$__interval]
          )
        ) by (component)
        ',
        legendFormat='{{ component }} component',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label="Saturation %",
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  keyServiceMetricsRow(serviceType, serviceStage):: row.new(title="🏅 Key Service Metrics", collapse=true)
    .addPanels(layout.grid([
      self.apdexPanel(serviceType, serviceStage),
      self.errorRatesPanel(serviceType, serviceStage),
      self.serviceAvailabilityPanel(serviceType, serviceStage),
      self.qpsPanel(serviceType, serviceStage),
      self.saturationPanel(serviceType, serviceStage),
    ])),
  keyComponentMetricsRow(serviceType, serviceStage):: row.new(title="🔩 Service Component Metrics", collapse=true)
    .addPanels(layout.grid([
      self.componentApdexPanel(serviceType, serviceStage),
      self.componentErrorRates(serviceType, serviceStage),
      self.componentAvailabilityPanel(serviceType, serviceStage),
      self.componentQpsPanel(serviceType, serviceStage),
      self.componentSaturationPanel(serviceType, serviceStage),
    ]))
}

