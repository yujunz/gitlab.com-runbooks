local aggregations = import './aggregations.libsonnet';
local selectors = import './selectors.libsonnet';
local strings = import 'strings.libsonnet';

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

local generateRateQuery(c, selector, rangeInterval) =
  local rateQueries = std.map(function(metric) metric.rateQuery(selector, rangeInterval), c.metrics);
  orJoin(rateQueries);

local generateIncreaseQuery(c, selector, rangeInterval) =
  local increaseQueries = std.map(function(metric) metric.increaseQuery(selector, rangeInterval), c.metrics);
  orJoin(increaseQueries);

local generateApdexQuery(c, aggregationLabels, selector, rangeInterval) =
  local numeratorQueries = std.map(function(metric) metric.apdexNumerator(selector, rangeInterval), c.metrics);
  local denominatorQueries = std.map(function(metric) metric.apdexDenominator(selector, rangeInterval), c.metrics);

  local aggregatedNumerators = aggregations.aggregateOverQuery('sum', aggregationLabels, orJoin(numeratorQueries));
  local aggregatedDenominators = aggregations.aggregateOverQuery('sum', aggregationLabels, orJoin(denominatorQueries));

  |||
    %(aggregatedNumerators)s
    /
    (
      %(aggregatedDenominators)s > 0
    )
  ||| % {
    aggregatedNumerators: strings.chomp(aggregatedNumerators),
    aggregatedDenominators: strings.indent(strings.chomp(aggregatedDenominators), 2),
  };

local generateApdexWeightQuery(c, aggregationLabels, selector, rangeInterval) =
  local apdexWeightQueries = std.map(function(i) i.apdexDenominator(selector, rangeInterval), c.metrics);
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
  ):: {
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

    apdexQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexQuery(self, aggregationLabels, selector, rangeInterval),

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
