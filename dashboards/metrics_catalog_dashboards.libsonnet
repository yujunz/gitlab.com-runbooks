local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local thresholds = import 'thresholds.libsonnet';
local row = grafana.row;

local getLatencyPercentileForService(service) =
  if std.objectHas(service, 'slos') && std.objectHas(service.slos, 'apdexRatio') then
    service.slos.apdexRatio
  else
    0.95;

local componentOverviewMatrixRow(serviceType, serviceStage, componentName, component, startRow) =
  layout.grid(
    std.prune([
      // Component apdex
      if std.objectHas(component, 'apdex') then
        keyMetrics.singleComponentApdexPanel(serviceType, serviceStage, componentName)
      else
        null,

      // Error rate
      if std.objectHas(component, 'errorRate') then
        keyMetrics.singleComponentErrorRates(serviceType, serviceStage, componentName)
      else
        null,

      // Component request rate
      if std.objectHas(component, 'requestRate') && std.objectHasAll(component.requestRate, 'aggregatedRateQuery') then
        keyMetrics.singleComponentQPSPanel(serviceType, serviceStage, componentName)
      else
        null,
    ]),
    cols=3,
    startRow=startRow,
    rowHeight=7
  );

{
  componentLatencyPanel(
    title=null,
    serviceType,
    componentName,
    selector,
    aggregationLabels='',
    logBase=10,
    legendFormat='%(percentile_humanized)s %(componentName)s',
    min=0.01,
    intervalFactor=2,
  )::
    local service = metricsCatalog.getService(serviceType);
    local component = service.components[componentName];
    local percentile = getLatencyPercentileForService(service);
    local formatConfig = { percentile_humanized: 'p' + (percentile * 100), componentName: componentName };

    basic.latencyTimeseries(
      title=(if title == null then 'Estimated %(percentile_humanized)s latency for %(componentName)s' + componentName else title) % formatConfig,
      query=component.apdex.percentileLatencyQuery(
        percentile=percentile,
        aggregationLabels=aggregationLabels,
        selector=selector,
        rangeInterval='$__interval',
      ),
      logBase=logBase,
      legendFormat=legendFormat % formatConfig,
      min=min,
      intervalFactor=intervalFactor,
    ) + {
      thresholds: [
        thresholds.errorLevel('gt', component.apdex.toleratedThreshold),
        thresholds.warningLevel('gt', component.apdex.satisfiedThreshold),
      ],
    },

  componentRPSPanel(
    title=null,
    serviceType,
    componentName,
    selector,
    aggregationLabels='',
    legendFormat='%(componentName)s errors',
    intervalFactor=2,
  )::
    local service = metricsCatalog.getService(serviceType);
    local component = service.components[componentName];

    basic.timeseries(
      title=if title == null then 'RPS for ' + componentName else title,
      query=component.requestRate.aggregatedRateQuery(
        aggregationLabels=aggregationLabels,
        selector=selector,
        rangeInterval='$__interval',
      ),
      legendFormat=legendFormat % { componentName: componentName },
      intervalFactor=intervalFactor,
      yAxisLabel='Requests per Second'
    ),


  componentErrorsPanel(
    title=null,
    serviceType,
    componentName,
    selector,
    aggregationLabels='',
    legendFormat='%(componentName)s errors',
    intervalFactor=2,
  )::
    local service = metricsCatalog.getService(serviceType);
    local component = service.components[componentName];

    basic.timeseries(
      title=if title == null then 'Errors for ' + componentName else title,
      query=component.errorRate.aggregatedChangesQuery(
        aggregationLabels=aggregationLabels,
        selector=selector,
        rangeInterval='$__interval',
      ),
      legendFormat=legendFormat % { componentName: componentName },
      intervalFactor=intervalFactor,
      yAxisLabel='Errors'
    ),

  componentOverviewMatrix(serviceType, serviceStage, startRow)::
    local service = metricsCatalog.getService(serviceType);
    [
      row.new(title='🔬 Component Level Indicators', collapse=false) { gridPos: { x: 0, y: startRow, w: 24, h: 1 } },
    ] +
    std.prune(
      std.flattenArrays(
        std.mapWithIndex(function(i, c) componentOverviewMatrixRow(serviceType, serviceStage, c, service.components[c], startRow=startRow + 1 + i), std.objectFields(service.components))
      )
    ),

  componentDetailMatrix(serviceType, componentName, selector, aggregationSets, minLatency=0.01)::
    local service = metricsCatalog.getService(serviceType);
    local component = service.components[componentName];
    local colCount =
      (if std.objectHas(component, 'apdex') then 1 else 0) +
      (if std.objectHas(component, 'requestRate') && std.objectHasAll(component.requestRate, 'aggregatedRateQuery') then 1 else 0) +
      (if std.objectHas(component, 'errorRate') then 1 else 0);


    row.new(title='🔬 %(componentName)s Component Detail' % { componentName: componentName }, collapse=true)
    .addPanels(
      layout.grid(
        std.prune(
          std.flattenArrays(
            std.map(
              function(aggregationSet)
                [
                  if std.objectHas(component, 'apdex') then
                    self.componentLatencyPanel(
                      title='Estimated %(percentile_humanized)s ' + componentName + ' Latency - ' + aggregationSet.title,
                      serviceType=serviceType,
                      componentName=componentName,
                      selector=selector,
                      legendFormat='%(percentile_humanized)s ' + aggregationSet.legendFormat,
                      aggregationLabels=aggregationSet.aggregationLabels,
                      min=minLatency,
                    )
                  else
                    null,

                  if std.objectHas(component, 'errorRate') then
                    self.componentErrorsPanel(
                      title=componentName + ' Errors - ' + aggregationSet.title,
                      serviceType=serviceType,
                      componentName=componentName,
                      legendFormat=aggregationSet.legendFormat,
                      aggregationLabels=aggregationSet.aggregationLabels,
                      selector=selector,
                    )
                  else
                    null,

                  if std.objectHas(component, 'requestRate') && std.objectHasAll(component.requestRate, 'aggregatedRateQuery') then
                    self.componentRPSPanel(
                      title=componentName + ' RPS - ' + aggregationSet.title,
                      serviceType=serviceType,
                      componentName=componentName,
                      selector=selector,
                      legendFormat=aggregationSet.legendFormat,
                      aggregationLabels=aggregationSet.aggregationLabels
                    )
                  else
                    null,
                ],
              aggregationSets
            )
          )
        ), cols=if colCount == 1 then 2 else colCount
      )
    ),

  autoDetailRows(serviceType, selector, startRow)::
    local s = self;
    local service = metricsCatalog.getService(serviceType);

    layout.grid(
      std.mapWithIndex(function(i, componentName)
                         local component = service.components[componentName];
                         local aggregationSets = [
                                                   { title: 'Overall', aggregationLabels: '', legendFormat: 'overall' },
                                                 ] +
                                                 std.map(function(c) { title: 'per ' + c, aggregationLabels: c, legendFormat: '{{' + c + '}}' }, component.significantLabels);

                         s.componentDetailMatrix(serviceType, componentName, selector, aggregationSets),
                       std.objectFields(service.components))
      , cols=1, startRow=startRow
    ),
}
