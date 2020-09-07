local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local colors = import 'grafana/colors.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local sliPromQL = import 'sli_promql.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local selectors = import 'promql/selectors.libsonnet';
local statusDescription = import 'status_description.libsonnet';

local defaultEnvironmentSelector = { environment: '$environment' };

local generalGraphPanel(
  title,
  description=null,
  linewidth=2,
  sort='increasing',
  legend_show=true,
  stableId=null
      ) =
  basic.graphPanel(
    title,
    linewidth=linewidth,
    description=description,
    sort=sort,
    legend_show=legend_show,
    stableId=stableId,
  )
  .addSeriesOverride(seriesOverrides.upper)
  .addSeriesOverride(seriesOverrides.lower)
  .addSeriesOverride(seriesOverrides.lastWeek)
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)
  .addSeriesOverride(seriesOverrides.slo);

local genericApdexPanel(
  title,
  description='Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.',
  compact=false,
  stableId=null,
  primaryQueryExpr,
  legendFormat,
  linewidth=null,
  environmentSelectorHash,
  serviceType,
  sort='increasing',
  legend_show=null,
      ) =
  generalGraphPanel(
    title,
    description=description,
    sort=sort,
    legend_show=if legend_show == null then !compact else legend_show,
    linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
    stableId=stableId,
  )
  .addTarget(  // Primary metric (worst case)
    promQuery.target(
      primaryQueryExpr,
      legendFormat=legendFormat,
    )
  )
  .addTarget(  // Min apdex score SLO for gitlab_service_errors:ratio metric
    promQuery.target(
      sliPromQL.apdex.serviceApdexDegradationSLOQuery(environmentSelectorHash, serviceType),
      interval='5m',
      legendFormat='6h Degradation SLO',
    ),
  )
  .addTarget(  // Double apdex SLO is Outage-level SLO
    promQuery.target(
      sliPromQL.apdex.serviceApdexOutageSLOQuery(environmentSelectorHash, serviceType),
      interval='5m',
      legendFormat='1h Outage SLO',
    ),
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
  );

local genericErrorPanel(
  title,
  description='Error rates are a measure of unhandled service exceptions per second. Client errors are excluded when possible. Lower is better',
  compact=false,
  stableId=null,
  primaryQueryExpr,
  legendFormat,
  linewidth=null,
  environmentSelectorHash,
  serviceType,
  sort='decreasing',
  legend_show=null,
      ) =
  generalGraphPanel(
    title,
    description=description,
    sort=sort,
    legend_show=if legend_show == null then !compact else legend_show,
    linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
    stableId=stableId,
  )
  .addTarget(
    promQuery.target(
      primaryQueryExpr,
      legendFormat=legendFormat,
    )
  )
  .addTarget(  // Maximum error rate SLO for gitlab_service_errors:ratio metric
    promQuery.target(
      sliPromQL.errorRate.serviceErrorRateDegradationSLOQuery(environmentSelectorHash, serviceType),
      interval='5m',
      legendFormat='6h Degradation SLO',
    ),
  )
  .addTarget(  // Outage level SLO
    promQuery.target(
      sliPromQL.errorRate.serviceErrorRateOutageSLOQuery(environmentSelectorHash, serviceType),
      interval='5m',
      legendFormat='1h Outage SLO',
    ),
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
  );

local genericQPSPanel(
  title,
  description='The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier.',
  compact=false,
  stableId=null,
  primaryQueryExpr,
  legendFormat,
  linewidth=null,
  environmentSelectorHash,
  serviceType,
  sort='decreasing',
  legend_show=null,
      ) =
  generalGraphPanel(
    title,
    description=description,
    sort=sort,
    legend_show=if legend_show == null then !compact else legend_show,
    linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
    stableId=stableId,
  )
  .addTarget(  // Primary metric
    promQuery.target(
      primaryQueryExpr,
      legendFormat=legendFormat,
    )
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
  );

{
  apdexPanel(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
    compact=false,
    description='Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.',
    stableId=null,
    sort='increasing',

  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    genericApdexPanel(
      'Latency: Apdex',
      description=description,
      compact=compact,
      stableId=stableId,
      primaryQueryExpr=sliPromQL.apdex.serviceApdexQuery(selectorHash, '$__interval', worstCase=true),
      legendFormat='{{ type }} service',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    )
    .addTarget(  // Primary metric (avg case)
      promQuery.target(
        sliPromQL.apdex.serviceApdexQuery(selectorHash, '$__interval', worstCase=false),
        legendFormat='{{ type }} service (avg)',
      )
    )
    .addTarget(  // Last week
      promQuery.target(
        sliPromQL.apdex.serviceApdexQueryWithOffset(selectorHash, '1w'),
        legendFormat='last week',
      )
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/ service$/'))
    .addSeriesOverride(seriesOverrides.averageCaseSeries('/ service \\(avg\\)$/', { fillBelowTo: serviceType + ' service' }))
    .addDataLink({
      url: '/d/alerts-service_multiburn_apdex?${__url_time_range}&${__all_variables}&var-type=%(type)s' % { type: serviceType },
      title: 'Service Apdex Multi-Burn Analysis',
      targetBlank: true,
    }),

  singleComponentApdexPanel(
    serviceType,
    serviceStage,
    component,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      component: component,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: component };

    genericApdexPanel(
      '%(component)s Apdex' % formatConfig,
      primaryQueryExpr=sliPromQL.apdex.componentApdexQuery(selectorHash, '$__interval'),
      legendFormat='{{ component }} apdex',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* apdex$/'))
    .addDataLink({
      url: '/d/alerts-component_multiburn_apdex?${__url_time_range}&${__all_variables}&var-type=%(type)s&var-component=%(component)s' % {
        type: serviceType,
        component: component,
      },
      title: 'Component Apdex Multi-Burn Analysis',
      targetBlank: true,
    }),

  singleComponentNodeApdexPanel(
    serviceType,
    component,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      component: component,
    };

    genericApdexPanel(
      '🖥 Per-Node %(component)s Apdex' % formatConfig,
      primaryQueryExpr=sliPromQL.apdex.componentNodeApdexQuery(selectorHash, '$__interval'),
      legendFormat='{{ fqdn }} {{ component }} apdex',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
      sort='increasing',
      legend_show=false,
      linewidth=1,
    )
    .addDataLink({
      url: '/d/alerts-component_node_multiburn_apdex?${__url_time_range}&${__all_variables}&var-type=%(type)s&var-fqdn=${__series.labels.fqdn}' % { type: serviceType },
      title: 'Component/Node Apdex Multi-Burn Analysis',
      targetBlank: true,
    }),

  componentApdexPanel(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    genericApdexPanel(
      'Component Latency: Apdex',
      linewidth=1,
      primaryQueryExpr=sliPromQL.apdex.componentApdexQuery(selectorHash, '$__interval'),
      legendFormat='{{ component }} component',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    ),

  /**
   * Returns a graph for a node-level aggregated apdex score
   */
  serviceNodeApdexPanel(
    serviceType,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    genericApdexPanel(
      'Node Latency: Apdex',
      primaryQueryExpr=sliPromQL.apdex.serviceNodeApdexQuery(selectorHash, '$__interval'),
      legendFormat='{{ fqdn }}',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    ),

  errorRatesPanel(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
    compact=false,
    includeLastWeek=true,
    stableId=null,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    genericErrorPanel(
      'Error Ratios',
      compact=compact,
      stableId=stableId,
      primaryQueryExpr=sliPromQL.errorRate.serviceErrorRateQuery(selectorHash, '$__interval', worstCase=true),
      legendFormat='{{ type }} service',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    )
    .addTarget(  // Primary metric (avg)
      promQuery.target(
        sliPromQL.errorRate.serviceErrorRateQuery(selectorHash, '$__interval', worstCase=false),
        legendFormat='{{ type }} service (avg)',
      )
    )
    .addTarget(  // Last week
      promQuery.target(
        sliPromQL.errorRate.serviceErrorRateQueryWithOffset(selectorHash, '1w'),
        legendFormat='last week',
      ) + {
        [if !includeLastWeek then 'hide']: true,
      }
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/ service$/', { fillBelowTo: serviceType + ' service (avg)' }))
    .addSeriesOverride(seriesOverrides.averageCaseSeries('/ service \\(avg\\)$/', { fillGradient: 10 }))
    .addDataLink({
      url: '/d/alerts-service_multiburn_error?${__url_time_range}&${__all_variables}&var-type=%(type)s' % { type: serviceType },
      title: 'Service Error-Rate Multi-Burn Analysis',
      targetBlank: true,
    }),

  singleComponentErrorRates(
    serviceType,
    serviceStage,
    componentName,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      component: componentName,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: componentName };

    genericErrorPanel(
      '%(component)s Component Error Rates' % formatConfig,
      linewidth=1,
      primaryQueryExpr=sliPromQL.errorRate.componentErrorRateQuery(selectorHash),
      legendFormat='{{ component }} error rate',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* error rate$/'))
    .addDataLink({
      url: '/d/alerts-component_multiburn_error?${__url_time_range}&${__all_variables}&var-type=%(type)s&var-component=%(component)s' % {
        type: serviceType,
        component: componentName,
      },
      title: 'Component Error-Rate Multi-Burn Analysis',
      targetBlank: true,
    }),

  singleComponentNodeErrorRates(
    serviceType,
    componentName,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      component: componentName,
    };

    genericErrorPanel(
      '🖥 Per-Node %(component)s Component Error Rates' % formatConfig,
      linewidth=1,
      legend_show=false,
      primaryQueryExpr=sliPromQL.errorRate.componentNodeErrorRateQuery(selectorHash),
      legendFormat='{{ fqdn }} {{ component }} error rate',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    )
    .addDataLink({
      url: '/d/alerts-component_node_multiburn_error?${__url_time_range}&${__all_variables}&var-type=%(type)s&var-fqdn=${__series.labels.fqdn}' % { type: serviceType },
      title: 'Component/Node Error Multi-Burn Analysis',
      targetBlank: true,
    }),

  componentErrorRates(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
      selector: selectors.serializeHash(environmentSelectorHash { type: serviceType, stage: serviceStage }),
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
                gitlab_component_errors:rate{%(selector)s}[$__interval]
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

  /**
   * Returns a graph for a node-level error ratios
   */
  serviceNodeErrorRatePanel(
    serviceType,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    genericErrorPanel(
      'Node Error Ratio',
      primaryQueryExpr=sliPromQL.errorRate.serviceNodeErrorRateQuery(selectorHash),
      legendFormat='{{ fqdn }} error rate',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    ),


  qpsPanel(
    serviceType,
    serviceStage,
    compact=false,
    environmentSelectorHash=defaultEnvironmentSelector,
    stableId=null,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    genericQPSPanel(
      'RPS - Service Requests per Second',
      compact=compact,
      stableId=stableId,
      primaryQueryExpr=sliPromQL.opsRate.serviceOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ type }} service',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    )
    .addTarget(  // Last week
      promQuery.target(
        sliPromQL.opsRate.serviceOpsRateQueryWithOffset(selectorHash, '1w'),
        legendFormat='last week',
      )
    )
    .addTarget(
      promQuery.target(
        sliPromQL.opsRate.serviceOpsRatePrediction(selectorHash, 2),
        legendFormat='upper normal',
      ),
    )
    .addTarget(
      promQuery.target(
        sliPromQL.opsRate.serviceOpsRatePrediction(selectorHash, -2),
        legendFormat='lower normal',
      ),
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/ service$/')),

  singleComponentQPSPanel(
    serviceType,
    serviceStage,
    componentName,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      component: componentName,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: componentName };

    genericQPSPanel(
      '%(component)s Component RPS - Requests per Second' % formatConfig,
      primaryQueryExpr=sliPromQL.opsRate.componentOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ component }} RPS',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
      linewidth=1
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* RPS$/')),

  singleComponentNodeQPSPanel(
    serviceType,
    componentName,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      component: componentName,
    };

    genericQPSPanel(
      '🖥 Per-Node %(component)s Component RPS - Requests per Second' % formatConfig,
      primaryQueryExpr=sliPromQL.opsRate.componentNodeOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ fqdn }} {{ component }} RPS',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
      linewidth=1,
    ),

  componentQpsPanel(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    genericQPSPanel(
      'Component RPS - Requests per Second',
      primaryQueryExpr=sliPromQL.opsRate.componentOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ component }} component',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
      linewidth=1,
    ),

  serviceNodeQpsPanel(
    serviceType,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    genericQPSPanel(
      'Node RPS - Requests per Second',
      primaryQueryExpr=sliPromQL.opsRate.serviceNodeOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ fqdn }}',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    ),

  saturationPanel(
    serviceType,
    serviceStage,
    compact=false,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    self.componentSaturationPanel(serviceType, serviceStage, compact, environmentSelectorHash=environmentSelectorHash),

  componentSaturationPanel(
    serviceType,
    serviceStage,
    compact=false,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::

    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
      selector: selectors.serializeHash(selectorHash),
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
              gitlab_component_saturation:ratio{%(selector)s}[$__interval]
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

  headlineMetricsRow(
    serviceType,
    serviceStage,
    startRow,
    rowTitle='🌡️ Service Level Indicators (𝙎𝙇𝙄𝙨)',
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    layout.grid([
      row.new(title=rowTitle, collapse=false),
    ], cols=1, rowHeight=1, startRow=startRow)
    +
    layout.splitColumnGrid([
      [
        self.apdexPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
        statusDescription.serviceApdexStatusDescriptionPanel(environmentSelectorHash { type: serviceType, stage: serviceStage }),
      ],
      [
        self.errorRatesPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
        statusDescription.serviceErrorStatusDescriptionPanel(environmentSelectorHash { type: serviceType, stage: serviceStage }),
      ],
      [
        self.qpsPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
      ],
      [
        self.saturationPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
      ],
    ], [4, 1], startRow=startRow + 1),

  keyServiceMetricsRow(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    row.new(title='🏅 Key Service Metrics', collapse=true)
    .addPanels(layout.grid([
      self.apdexPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.errorRatesPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.qpsPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.saturationPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
    ])),

  keyComponentMetricsRow(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    row.new(title='🔩 Service Component Metrics', collapse=true)
    .addPanels(layout.grid([
      self.componentApdexPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.componentErrorRates(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.componentQpsPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.componentSaturationPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
    ])),
}
