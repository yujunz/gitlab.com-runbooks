local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

// Merge two hashes of the form { key: set },
local merge(h1, h2) =
  local folderFunc = function(memo, k)
    if std.objectHas(memo, k) then
      memo {
        [k]: std.setUnion(memo[k], h2[k]),
      }
    else
      memo {
        [k]: h2[k],
      };

  std.foldl(folderFunc, std.objectFields(h2), h1);

local orJoin(queries) =
  std.join('\nor\n', queries);

local wrapForUniqueness(index, query) =
  'label_replace(%(query)s, "_c", "%(index)d", "", "")' % {
    query: query,
    index: index,
  };

local generateRateQuery(c, selector, rangeInterval) =
  local rateQueries = std.mapWithIndex(function(index, metric) wrapForUniqueness(index, metric.rateQuery(selector, rangeInterval)), c.metrics);
  orJoin(rateQueries);

local generateIncreaseQuery(c, selector, rangeInterval) =
  local increaseQueries = std.mapWithIndex(function(index, metric) wrapForUniqueness(index, metric.increaseQuery(selector, rangeInterval)), c.metrics);
  orJoin(increaseQueries);

local groupByClauseFor(substituteWeightWithRecordingRule, aggregationLabels) =
  if substituteWeightWithRecordingRule == null then
    ''
  else
    ' on(%(aggregationLabels)s) group_left()' % {
      aggregationLabels: aggregations.serialize(aggregationLabels),
    };

local generateApdexQuery(c, aggregationLabels, selector, rangeInterval, substituteWeightWithRecordingRule) =
  local numeratorQueries = std.mapWithIndex(function(index, metric) wrapForUniqueness(index, metric.apdexNumerator(selector, rangeInterval)), c.metrics);
  local aggregatedNumerators = aggregations.aggregateOverQuery('sum', aggregationLabels, orJoin(numeratorQueries));

  local aggregatedDenominators = if substituteWeightWithRecordingRule == null then
    local denominatorQueries = std.mapWithIndex(function(index, metric) wrapForUniqueness(index, metric.apdexDenominator(selector, rangeInterval)), c.metrics);
    aggregations.aggregateOverQuery('sum', aggregationLabels, orJoin(denominatorQueries))
  else
    substituteWeightWithRecordingRule;

  |||
    %(aggregatedNumerators)s
    /%(groupByClause)s
    (
      %(aggregatedDenominators)s > 0
    )
  ||| % {
    groupByClause: groupByClauseFor(substituteWeightWithRecordingRule, aggregationLabels),
    aggregatedNumerators: strings.chomp(aggregatedNumerators),
    aggregatedDenominators: strings.indent(strings.chomp(aggregatedDenominators), 2),
  };

local generateApdexWeightQuery(c, aggregationLabels, selector, rangeInterval) =
  local apdexWeightQueries = std.mapWithIndex(function(index, metric) wrapForUniqueness(index, metric.apdexDenominator(selector, rangeInterval)), c.metrics);
  aggregations.aggregateOverQuery('sum', aggregationLabels, orJoin(apdexWeightQueries));

local generateApdexPercentileLatencyQuery(c, percentile, aggregationLabels, selector, rangeInterval) =
  local aggregationLabelsWithLe = aggregations.join([aggregationLabels, 'le']);
  local rateQueries = std.map(function(i) i.apdexNumerator(selector, rangeInterval), c.metrics);
  local aggregatedRateQueries = aggregations.aggregateOverQuery('sum', aggregationLabels, orJoin(rateQueries));

  |||
    histogram_quantile(
      %(percentile)f,
      %(aggregatedRateQuery)s
    )
  ||| % {
    percentile: percentile,
    aggregatedRateQuery: strings.indent(strings.chomp(aggregatedRateQueries), 2),
  };

// "combined" allows two counter metrics to be added together
// to generate a new metric value
{
  combined(
    metrics
  )::
    // If the combiner only includes a single metric, unwind it and just
    // delegate directly to the underlying metric
    if std.length(metrics) == 1 then
      metrics[0]
    else
      {
        metrics: metrics,

        // This creates a rate query of the form
        // rate(....{<selector>}[<rangeInterval>])
        rateQuery(selector, rangeInterval)::
          generateRateQuery(self, selector, rangeInterval),

        // This creates a increase query of the form
        // rate(....{<selector>}[<rangeInterval>])
        increaseQuery(selector, rangeInterval)::
          generateIncreaseQuery(self, selector, rangeInterval),

        // This creates an aggregated rate query of the form
        // sum by(<aggregationLabels>) (...)
        aggregatedRateQuery(aggregationLabels, selector, rangeInterval)::
          local query = generateRateQuery(self, selector, rangeInterval);
          aggregations.aggregateOverQuery('sum', aggregationLabels, query),

        // This creates an aggregated increase query of the form
        // sum by(<aggregationLabels>) (...)
        aggregatedIncreaseQuery(aggregationLabels, selector, rangeInterval)::
          local query = generateIncreaseQuery(self, selector, rangeInterval);
          aggregations.aggregateOverQuery('sum', aggregationLabels, query),

        apdexQuery(aggregationLabels, selector, rangeInterval, substituteWeightWithRecordingRule=null)::
          generateApdexQuery(self, aggregationLabels, selector, rangeInterval, substituteWeightWithRecordingRule),

        apdexWeightQuery(aggregationLabels, selector, rangeInterval)::
          generateApdexWeightQuery(self, aggregationLabels, selector, rangeInterval),

        percentileLatencyQuery(percentile, aggregationLabels, selector, rangeInterval)::
          generateApdexPercentileLatencyQuery(self, percentile, aggregationLabels, selector, rangeInterval),

        // Forward the below methods and fields to the first metric for
        // apdex scores, which is wrong but hopefully not catastrophic.
        describe()::
          metrics[0].describe(),

        toleratedThreshold:
          metrics[0].toleratedThreshold,

        satisfiedThreshold:
          metrics[0].satisfiedThreshold,

        [if std.objectHasAll(metrics[0], 'supportsReflection') then 'supportsReflection']():: {
          // Returns a list of metrics and the labels that they use
          getMetricNamesAndLabels()::
            std.foldl(
              function(memo, metric) merge(memo, metric.supportsReflection().getMetricNamesAndLabels()),
              metrics,
              {}
            ),
        },
      },
}
