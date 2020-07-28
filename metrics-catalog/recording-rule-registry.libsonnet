local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local metricsLabelRegistry = import 'metric-label-registry.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';

local standardEnvironmentLabels = std.set(['environment', 'type', 'tier', 'stage', 'shard']);

local burnRates = std.set(['1m', '5m', '30m', '1h', '6h']);

// Collect recordingRuleMetrics for all services
local metricsWithRecordingRules = std.foldl(
  function(memo, service)
    if std.objectHas(service, 'recordingRuleMetrics') then
      std.setUnion(memo, std.set(service.recordingRuleMetrics))
    else
      memo,
  metricsCatalog.services,
  []
);

local supportsDuration(duration) =
  std.setMember(duration, burnRates);

local supportsLabelsAndSelector(metricName, requiredAggregationLabels, selector) =
  if std.setMember(metricName, metricsWithRecordingRules) then
    if std.type(selector) == 'object' then
      local allRequiredLabels = std.set(requiredAggregationLabels + selectors.getLabels(selector));
      local recordingRuleLabels = metricsLabelRegistry.lookupLabelsForMetricName(metricName);

      local allRequiredLabelsMinusStandards = std.setDiff(allRequiredLabels, standardEnvironmentLabels);

      local missingLabels = std.setDiff(allRequiredLabelsMinusStandards, recordingRuleLabels);

      // Check that allRequiredLabels is a subset of recordingRuleLabels
      if missingLabels == [] then
        true
      else
        std.trace('Unable to use recording rule for ' + metricName + '. Missing labels: ' + missingLabels, false)
    else
      std.assertEqual(selector, { __assert__: 'selector should be a selector hash' })
  else
    false;

local splitAggregationString(aggregationLabelsString) =
  if aggregationLabelsString == '' then
    []
  else
    [
      std.stripChars(str, ' \n\t')
      for str in std.split(aggregationLabelsString, ',')
    ];

local resolveRecordingRuleFor(metricName, requiredAggregationLabels, selector, duration) =
  // Recording rules can't handle `$__interval` variable ranges, so always resolve these as 5m
  local durationWithRecordingRule = if duration == '$__interval' then '5m' else duration;

  local requiredAggregationLabelsArray = if std.isArray(requiredAggregationLabels) then
    requiredAggregationLabels
  else
    splitAggregationString(requiredAggregationLabels);

  if supportsDuration(durationWithRecordingRule) && supportsLabelsAndSelector(metricName, requiredAggregationLabelsArray, selector) then
    'sli_aggregations:%(metricName)s_rate%(duration)s{%(selector)s}' % {
      metricName: metricName,
      duration: durationWithRecordingRule,
      selector: selectors.serializeHash(selector),
    }
  else
    null;

{
  // Finds an appropriate recording rule expression
  // or returns null if the labels don't match or the metric doesn't have
  // a recording rule
  resolveRecordingRuleFor(
    aggregationFunction='sum',
    aggregationLabels=[],
    rangeVectorFunction='rate',
    metricName=null,
    rangeInterval='5m',
    selector={},
  )::
    // Currently only support sum/rate recording rules,
    // possibly support other options in future
    if rangeVectorFunction != 'rate' then
      null
    else
      local resolvedRecordingRule = resolveRecordingRuleFor(metricName, aggregationLabels, selector, rangeInterval);

      if resolvedRecordingRule == null then
        null
      else
        if aggregationFunction == 'sum' then
          aggregations.aggregateOverQuery(aggregationFunction, aggregationLabels, resolvedRecordingRule)
        else if aggregationFunction == null then
          resolvedRecordingRule
        else
          null,

  recordingRuleExpressionFor(metricName, rangeInterval)::
    local aggregationLabels = metricsLabelRegistry.lookupLabelsForMetricName(metricName);
    local allRequiredLabelsPlusStandards = std.setUnion(aggregationLabels, standardEnvironmentLabels);
    local query = 'rate(%(metricName)s[%(rangeInterval)s])' % {
      metricName: metricName,
      rangeInterval: rangeInterval,
    };
    aggregations.aggregateOverQuery('sum', allRequiredLabelsPlusStandards, query),

  recordingRuleNameFor(metricName, rangeInterval)::
    'sli_aggregations:%(metricName)s_rate%(rangeInterval)s' % {
      metricName: metricName,
      rangeInterval: rangeInterval,
    },

}
