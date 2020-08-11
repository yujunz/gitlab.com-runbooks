local multiburn_factors = import './multiburn_factors.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local errorRateTerm(
  metric,
  metricSelectorHash,
  comparator,
  burnrate,
  sloMetric,
  sloMetricSelectorHash,
  sloMetricAggregationLabels,
) =
  |||
    %(metric)s{%(metricSelector)s}
    %(comparator)s on(%(sloMetricAggregationLabels)s) group_left()
    (
      %(burnrate)g * (
        avg by (%(sloMetricAggregationLabels)s) (%(sloMetric)s{%(sloSelector)s})
      )
    )
  ||| % {
    metric: metric,
    burnrate: burnrate,
    metricSelector: selectors.serializeHash(metricSelectorHash),
    sloMetric: sloMetric,
    sloSelector: selectors.serializeHash(sloMetricSelectorHash),
    sloMetricAggregationLabels: aggregations.serialize(sloMetricAggregationLabels),
    comparator: comparator,
  };

local apdexRateTerm(
  metric,
  metricSelectorHash,
  comparator,
  burnrate,
  sloMetric,
  sloMetricSelectorHash,
  sloMetricAggregationLabels,
) =
  |||
    %(metric)s{%(metricSelector)s}
    %(comparator)s on(%(sloMetricAggregationLabels)s) group_left()
    (
      1 -
      (
        %(burnrate)g * (1 - avg by (%(sloMetricAggregationLabels)s) (%(sloMetric)s{%(sloSelector)s}))
      )
    )
  ||| % {
    metric: metric,
    burnrate: burnrate,
    metricSelector: selectors.serializeHash(metricSelectorHash),
    sloMetric: sloMetric,
    sloSelector: selectors.serializeHash(sloMetricSelectorHash),
    sloMetricAggregationLabels: aggregations.serialize(sloMetricAggregationLabels),
    comparator: comparator,
  };

local operationRateFilter(
  expression,
  operationRateMetric,
  operationRateAggregationLabels,
  operationRateSelectorHash,
  minimumOperationRateForMonitoring
) =
  if operationRateMetric == null then
    expression
  else
    if operationRateAggregationLabels == null then
      |||
        (
          %(expression)s
        )
        and
        (
          %(operationRateMetric)s{%(operationRateSelector)s} >= %(minimumOperationRateForMonitoring)g
        )
      ||| % {
        expression: strings.indent(expression, 2),
        operationRateMetric: operationRateMetric,
        minimumOperationRateForMonitoring: minimumOperationRateForMonitoring,
        operationRateSelector: selectors.serializeHash(operationRateSelectorHash),
      }
    else
      |||
        (
          %(expression)s
        )
        and on(%(operationRateAggregationLabels)s)
        (
          sum by(%(operationRateAggregationLabels)s) (%(operationRateMetric)s{%(operationRateSelector)s}) >= %(minimumOperationRateForMonitoring)g
        )
      ||| % {
        expression: strings.indent(expression, 2),
        operationRateMetric: operationRateMetric,
        minimumOperationRateForMonitoring: minimumOperationRateForMonitoring,
        operationRateSelector: selectors.serializeHash(operationRateSelectorHash),
        operationRateAggregationLabels: aggregations.serialize(operationRateAggregationLabels),
      };

{
  // Generates a multi-window, multi-burn-rate error expression
  multiburnRateErrorExpression(
    metric1h,  // 1h burn rate metric
    metric5m,  // 5m burn rate metric
    metric30m,  // 30m burn rate metric
    metric6h,  // 6h burn rate metric
    metricSelectorHash,  // Selectors for the error rate metrics
    sloMetric,  // SLO metric name
    sloMetricSelectorHash,  // Selectors for the slo metric
    sloMetricAggregationLabels,  // Labels to join the SLO metric to the error rate metrics with
    operationRateMetric=null,  // Optional: operation rate metric for minimum operation rate clause
    operationRateAggregationLabels=null, // Labels to aggregate the operation rate on, if any
    operationRateSelectorHash=null, // Selector for the operation rate metric
    minimumOperationRateForMonitoring=null,  // minium operation rate vaue (in request-per-second)
  )::
    local term(metric, burnrate) =
      errorRateTerm(
        metric=metric,
        metricSelectorHash=metricSelectorHash,
        comparator=">",
        burnrate=burnrate,
        sloMetric=sloMetric,
        sloMetricSelectorHash=sloMetricSelectorHash,
        sloMetricAggregationLabels=sloMetricAggregationLabels,
      );

    local term_1h = term(metric1h, multiburn_factors.burnrate_1h);
    local term_5m = term(metric5m, multiburn_factors.burnrate_1h);
    local term_6h = term(metric6h, multiburn_factors.burnrate_6h);
    local term_30m = term(metric30m, multiburn_factors.burnrate_6h);

    local preOperationRateExpr = |||
      (
        %(term_1h)s
      )
      and
      (
        %(term_5m)s
      )
      or
      (
        %(term_6h)s
      )
      and
      (
        %(term_30m)s
      )
    ||| % {
      term_1h: strings.indent(term_1h, 2),
      term_5m: strings.indent(term_5m, 2),
      term_6h: strings.indent(term_6h, 2),
      term_30m: strings.indent(term_30m, 2)
    };

    operationRateFilter(
      preOperationRateExpr,
      operationRateMetric,
      operationRateAggregationLabels,
      operationRateSelectorHash,
      minimumOperationRateForMonitoring
    ),

  // Generates a multi-window, multi-burn-rate apdex score expression
  multiburnRateApdexExpression(
    metric1h,  // 1h burn rate metric
    metric5m,  // 5m burn rate metric
    metric30m,  // 30m burn rate metric
    metric6h,  // 6h burn rate metric
    metricSelectorHash,  // Selectors for the error rate metrics
    sloMetric,  // SLO metric name
    sloMetricSelectorHash,  // Selectors for the slo metric
    sloMetricAggregationLabels,  // Labels to join the SLO metric to the error rate metrics with
    operationRateMetric=null,  // Optional: operation rate metric for minimum operation rate clause
    operationRateAggregationLabels=null, // Labels to aggregate the operation rate on, if any
    operationRateSelectorHash=null, // Selector for the operation rate metric
    minimumOperationRateForMonitoring=null,  // minium operation rate vaue (in request-per-second)
  )::
    local term(metric, burnrate) =
      apdexRateTerm(
        metric=metric,
        metricSelectorHash=metricSelectorHash,
        comparator="<",
        burnrate=burnrate,
        sloMetric=sloMetric,
        sloMetricSelectorHash=sloMetricSelectorHash,
        sloMetricAggregationLabels=sloMetricAggregationLabels,
      );

    local term_1h = term(metric1h, multiburn_factors.burnrate_1h);
    local term_5m = term(metric5m, multiburn_factors.burnrate_1h);
    local term_6h = term(metric6h, multiburn_factors.burnrate_6h);
    local term_30m = term(metric30m, multiburn_factors.burnrate_6h);

    local preOperationRateExpr = |||
      (
        %(term_1h)s
      )
      and
      (
        %(term_5m)s
      )
      or
      (
        %(term_6h)s
      )
      and
      (
        %(term_30m)s
      )
    ||| % {
      term_1h: strings.indent(term_1h, 2),
      term_5m: strings.indent(term_5m, 2),
      term_6h: strings.indent(term_6h, 2),
      term_30m: strings.indent(term_30m, 2)
    };

    operationRateFilter(
      preOperationRateExpr,
      operationRateMetric,
      operationRateAggregationLabels,
      operationRateSelectorHash,
      minimumOperationRateForMonitoring
    ),

}
