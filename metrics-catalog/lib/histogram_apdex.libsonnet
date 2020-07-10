local aggregations = import './aggregations.libsonnet';
local selectors = import './selectors.libsonnet';
local recordingRuleRegistry = import 'recording-rule-registry.libsonnet';
local strings = import 'strings.libsonnet';

// A general apdex query is:
//
// 1. Some kind of satisfaction query (with a single threshold, a
//    double threshold, or even a combination of thresholds or-ed
//    together)
// 2. Divided by an optional denominator (when it's a double threshold
//    query; see
//    https://prometheus.io/docs/practices/histograms/#apdex-score)
// 3. Divided by some kind of weight score (either a single weight, or a
//    combination of weights or-ed together).
//
// The other functions here all use this to generate the final apdex
// query.

local generateApdexComponentRateQuery(histogramApdex, additionalSelectors, rangeInterval, leSelector={}, aggregationFunction=null, aggregationLabels=[]) =
  local selector = selectors.merge(histogramApdex.selector, additionalSelectors);
  local selectorWithLe = selectors.merge(selector, leSelector);

  local resolvedRecordingRule = recordingRuleRegistry.resolveRecordingRuleFor(
    aggregationFunction=aggregationFunction,
    aggregationLabels=aggregationLabels,
    rangeVectorFunction='rate',
    metricName=histogramApdex.histogram,
    rangeInterval=rangeInterval,
    selector=selectorWithLe,
  );

  if resolvedRecordingRule == null then
    local query = 'rate(%(histogram)s{%(selector)s}[%(rangeInterval)s])' % {
      histogram: histogramApdex.histogram,
      selector: selectors.serializeHash(selectorWithLe),
      rangeInterval: rangeInterval,
    };

    if aggregationFunction == null then
      query
    else
      aggregations.aggregateOverQuery(aggregationFunction, aggregationLabels, query)
  else
    resolvedRecordingRule;

// A double threshold apdex score only has both SATISFACTORY threshold and TOLERABLE thresholds
local generateDoubleThresholdApdexNumeratorQuery(histogramApdex, additionalSelectors, rangeInterval, aggregationFunction=null, aggregationLabels=[], ignoreLe=false) =
  local satisfiedQuery = generateApdexComponentRateQuery(histogramApdex, additionalSelectors, rangeInterval, { le: histogramApdex.satisfiedThreshold }, aggregationFunction=aggregationFunction, aggregationLabels=aggregationLabels);
  local toleratedQuery = generateApdexComponentRateQuery(histogramApdex, additionalSelectors, rangeInterval, { le: histogramApdex.toleratedThreshold }, aggregationFunction=aggregationFunction, aggregationLabels=aggregationLabels);

  |||
    (
      %(satisfied)s
      +%(ignoreLe)s
      %(tolerated)s
    )
    /
    2
  ||| % {
    satisfied: strings.indent(satisfiedQuery, 2),
    tolerated: strings.indent(toleratedQuery, 2),
    ignoreLe: if ignoreLe then ' ignoring(le)' else '',
  };

local generateApdexNumeratorQuery(histogramApdex, additionalSelectors, rangeInterval, aggregationFunction=null, aggregationLabels=[], ignoreLe=false) =
  if histogramApdex.toleratedThreshold == null then
    // A single threshold apdex score only has a SATISFACTORY threshold, no TOLERABLE threshold
    generateApdexComponentRateQuery(histogramApdex, additionalSelectors, rangeInterval, { le: histogramApdex.satisfiedThreshold }, aggregationFunction=aggregationFunction, aggregationLabels=aggregationLabels)
  else
    generateDoubleThresholdApdexNumeratorQuery(histogramApdex, additionalSelectors, rangeInterval, aggregationFunction=aggregationFunction, aggregationLabels=aggregationLabels, ignoreLe=ignoreLe);

local groupByClauseFor(substituteWeightWithRecordingRule, aggregationLabels) =
  if substituteWeightWithRecordingRule == null then
    ''
  else
    ' on(%(aggregationLabels)s) group_left()' % {
      aggregationLabels: aggregations.serialize(aggregationLabels),
    };

local generateApdexScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, rangeInterval, aggregationFunction=null, substituteWeightWithRecordingRule=null) =
  local numeratorQuery = generateApdexNumeratorQuery(histogramApdex, additionalSelectors, rangeInterval, aggregationFunction=aggregationFunction, aggregationLabels=aggregationLabels, ignoreLe=false);
  local weightQuery = if substituteWeightWithRecordingRule == null then
    generateApdexComponentRateQuery(histogramApdex, additionalSelectors, rangeInterval, { le: '+Inf' }, aggregationFunction=aggregationFunction, aggregationLabels=aggregationLabels)
  else
    substituteWeightWithRecordingRule;

  |||
    %(numeratorQuery)s
    /%(groupByClause)s
    (
      %(weightQuery)s > 0
    )
  ||| % {
    groupByClause: groupByClauseFor(substituteWeightWithRecordingRule, aggregationLabels),
    numeratorQuery: strings.chomp(numeratorQuery),
    weightQuery: strings.indent(strings.chomp(weightQuery), 2),
  };

local generatePercentileLatencyQuery(histogram, percentile, aggregationLabels, additionalSelectors, rangeInterval) =
  local aggregationLabelsWithLe = aggregations.join([aggregationLabels, 'le']);
  local aggregatedRateQuery = generateApdexComponentRateQuery(histogram, additionalSelectors, rangeInterval, aggregationFunction='sum', aggregationLabels=aggregationLabelsWithLe);

  |||
    histogram_quantile(
      %(percentile)f,
      %(aggregatedRateQuery)s
    )
  ||| % {
    percentile: percentile,
    aggregatedRateQuery: strings.indent(strings.chomp(aggregatedRateQuery), 2),
  };

{
  histogramApdex(
    histogram,
    selector='',
    satisfiedThreshold=null,
    toleratedThreshold=null
  ):: {
    histogram: histogram,
    selector: selector,
    satisfiedThreshold: satisfiedThreshold,
    toleratedThreshold: toleratedThreshold,

    apdexQuery(aggregationLabels, selector, rangeInterval, substituteWeightWithRecordingRule=null)::
      generateApdexScoreQuery(
        self,
        aggregationLabels,
        selector,
        rangeInterval,
        aggregationFunction='sum',
        substituteWeightWithRecordingRule=substituteWeightWithRecordingRule
      ),

    apdexWeightQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexComponentRateQuery(self, selector, rangeInterval, { le: '+Inf' }, aggregationFunction='sum', aggregationLabels=aggregationLabels),

    percentileLatencyQuery(percentile, aggregationLabels, selector, rangeInterval)::
      generatePercentileLatencyQuery(self, percentile, aggregationLabels, selector, rangeInterval),

    // This is used to combine multiple apdex scores for a combined percentileLatencyQuery
    aggregatedRateQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexComponentRateQuery(self, selector, rangeInterval, aggregationFunction='sum', aggregationLabels=aggregationLabels),

    describe()::
      local s = self;
      // TODO: don't assume the metric is in seconds!
      if s.toleratedThreshold == null then
        '%gs' % [s.satisfiedThreshold]
      else
        '%gs/%gs' % [s.satisfiedThreshold, s.toleratedThreshold],

    // The preaggregated numerator expression
    // used for combinations
    apdexNumerator(selector, rangeInterval)::
      generateApdexNumeratorQuery(self, selector, rangeInterval, aggregationFunction=null, aggregationLabels=[], ignoreLe=true),

    // The preaggregated denominator expression
    // used for combinations
    apdexDenominator(selector, rangeInterval)::
      generateApdexComponentRateQuery(self, selector, rangeInterval, { le: '+Inf' }, aggregationFunction=null, aggregationLabels=[]),

    // Only support reflection on hash selectors
    [if std.isObject(selector) then 'supportsReflection']():: {
      // Returns a list of metrics and the labels that they use
      getMetricNamesAndLabels()::
        {
          [histogram]: std.set(std.objectFields(selector) + ['le']),
        },
    },
  },
}
