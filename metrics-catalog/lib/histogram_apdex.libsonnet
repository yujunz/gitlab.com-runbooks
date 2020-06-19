local aggregations = import './aggregations.libsonnet';
local selectors = import './selectors.libsonnet';
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

local nullAggregationWrapper = function(f) f;
local sum(aggregationLabels) =
  function(f) aggregations.aggregateOverQuery('sum', aggregationLabels, f);

local generateApdexComponentRateQuery(histogramApdex, additionalSelectors, rangeInterval, leSelector='', aggregationWrapper=null) =
  local selector = selectors.join([strings.chomp(histogramApdex.selector), strings.chomp(additionalSelectors), leSelector]);

  aggregationWrapper('rate(%(histogram)s{%(selector)s}[%(rangeInterval)s])' % {
    histogram: histogramApdex.histogram,
    selector: selector,
    rangeInterval: rangeInterval,
  });

// A double threshold apdex score only has both SATISFACTORY threshold and TOLERABLE thresholds
local generateDoubleThresholdApdexNumeratorQuery(histogramApdex, additionalSelectors, rangeInterval, aggregationWrapper) =
  local satisfiedQuery = generateApdexComponentRateQuery(histogramApdex, additionalSelectors, rangeInterval, 'le="%g"' % [histogramApdex.satisfiedThreshold], aggregationWrapper);
  local toleratedQuery = generateApdexComponentRateQuery(histogramApdex, additionalSelectors, rangeInterval, 'le="%g"' % [histogramApdex.toleratedThreshold], aggregationWrapper);

  |||
    (
      %(satisfied)s
      +
      %(tolerated)s
    )
    /
    2
  ||| % {
    satisfied: strings.indent(satisfiedQuery, 2),
    tolerated: strings.indent(toleratedQuery, 2),
  };

local generateApdexNumeratorQuery(histogramApdex, additionalSelectors, rangeInterval, aggregationWrapper) =
  if histogramApdex.toleratedThreshold == null then
    // A single threshold apdex score only has a SATISFACTORY threshold, no TOLERABLE threshold
    generateApdexComponentRateQuery(histogramApdex, additionalSelectors, rangeInterval, 'le="%g"' % [histogramApdex.satisfiedThreshold], aggregationWrapper)
  else
    generateDoubleThresholdApdexNumeratorQuery(histogramApdex, additionalSelectors, rangeInterval, aggregationWrapper);

local generateApdexScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, rangeInterval, aggregationWrapper) =
  local numeratorQuery = generateApdexNumeratorQuery(histogramApdex, additionalSelectors, rangeInterval, aggregationWrapper);
  local weightQuery = generateApdexComponentRateQuery(histogramApdex, additionalSelectors, rangeInterval, 'le="+Inf"', aggregationWrapper);

  |||
    %(numeratorQuery)s
    /
    (
      %(weightQuery)s > 0
    )
  ||| % {
    numeratorQuery: strings.chomp(numeratorQuery),
    weightQuery: strings.indent(strings.chomp(weightQuery), 2),
  };

local generatePercentileLatencyQuery(histogram, percentile, aggregationLabels, additionalSelectors, rangeInterval) =
  local aggregationLabelsWithLe = selectors.join([aggregationLabels, 'le']);
  local aggregatedRateQuery = generateApdexComponentRateQuery(histogram, additionalSelectors, rangeInterval, aggregationWrapper=sum(aggregationLabelsWithLe));

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

    apdexQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexScoreQuery(self, aggregationLabels, selector, rangeInterval, aggregationWrapper=sum(aggregationLabels)),

    apdexWeightQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexComponentRateQuery(self, selector, rangeInterval, 'le="+Inf"', aggregationWrapper=sum(aggregationLabels)),

    percentileLatencyQuery(percentile, aggregationLabels, selector, rangeInterval)::
      generatePercentileLatencyQuery(self, percentile, aggregationLabels, selector, rangeInterval),

    // This is used to combine multiple apdex scores for a combined percentileLatencyQuery
    aggregatedRateQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexComponentRateQuery(self, selector, rangeInterval, aggregationWrapper=sum(aggregationLabels)),

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
      generateApdexNumeratorQuery(self, selector, rangeInterval, aggregationWrapper=nullAggregationWrapper),

    // The preaggregated denominator expression
    // used for combinations
    apdexDenominator(selector, rangeInterval)::
      generateApdexComponentRateQuery(self, selector, rangeInterval, 'le="+Inf"', aggregationWrapper=nullAggregationWrapper),
  },
}
