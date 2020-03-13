local selectors = import './selectors.libsonnet';

local chomp(str) = std.rstripChars(str, '\n');
local removeBlankLines(str) = std.strReplace(str, '\n\n', '\n');

local indent(str, spaces) =
  std.strReplace(removeBlankLines(chomp(str)), '\n', '\n' + std.repeat(' ', spaces));

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
//
local generateApdexQuery(satisfactionQuery, weightScoreQuery, denominator=null) =
  local denominatorString = if std.isNumber(denominator) then
    '/\n%s' % [denominator]
  else
    '';

  local query = |||
    (
      %(satisfactionQuery)s
    )
    %(denominatorString)s
    /
    (
      %(weightScoreQuery)s > 0
    )
  ||| % {
    satisfactionQuery: indent(satisfactionQuery, 2),
    denominatorString: denominatorString,
    weightScoreQuery: indent(weightScoreQuery, 2),
  };

  removeBlankLines(query);

// A single threshold apdex score only has a SATISFACTORY threshold, no TOLERABLE threshold
local generateSingleThresholdApdexScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, duration) =
  generateApdexQuery(
    histogramApdex.apdexComponentQuery(aggregationLabels, additionalSelectors, duration, 'le="%g"' % [histogramApdex.satisfiedThreshold]),
    histogramApdex.apdexComponentQuery(aggregationLabels, additionalSelectors, duration, 'le="+Inf"'),
  );

// A double threshold apdex score only has both SATISFACTORY threshold and TOLERABLE thresholds
local generateDoubleThresholdApdexScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, duration) =
  local satisfactionQuery = |||
    %(satisfied)s
    +
    %(tolerated)s
  ||| % {
    satisfied: histogramApdex.apdexComponentQuery(aggregationLabels, additionalSelectors, duration, 'le="%g"' % [histogramApdex.satisfiedThreshold]),
    tolerated: histogramApdex.apdexComponentQuery(aggregationLabels, additionalSelectors, duration, 'le="%g"' % [histogramApdex.toleratedThreshold]),
  };

  generateApdexQuery(
    satisfactionQuery,
    histogramApdex.apdexComponentQuery(aggregationLabels, additionalSelectors, duration, 'le="+Inf"'),
    denominator=2,
  );

local generateApdexScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, duration) =
  if histogramApdex.toleratedThreshold == null then
    generateSingleThresholdApdexScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, duration)
  else
    generateDoubleThresholdApdexScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, duration);

local generatePercentileLatencyQuery(histogramApdex, percentile, aggregationLabels, additionalSelectors, duration) =
  local selector = selectors.join([histogramApdex.selector, additionalSelectors]);
  local aggregationLabelsWithLe = selectors.join([aggregationLabels, 'le']);

  |||
    histogram_quantile(
      %(percentile)f,
      sum by (%(aggregationLabelsWithLe)s) (
        rate(%(histogram)s{%(selector)s}[%(duration)s])
      )
    )
  ||| % {
    percentile: percentile,
    aggregationLabelsWithLe: aggregationLabelsWithLe,
    histogram: histogramApdex.histogram,
    selector: selector,
    duration: duration,
  };

local generateApdexComponentQuery(histogramApdex, aggregationLabels, additionalSelectors, duration, leSelector) =
  local selector = selectors.join([histogramApdex.selector, additionalSelectors]);

  |||
    sum by (%(aggregationLabels)s) (
      rate(%(histogram)s{%(selector)s}[%(duration)s])
    )
  ||| % {
    aggregationLabels: aggregationLabels,
    histogram: histogramApdex.histogram,
    selector: std.strReplace(selectors.join([selector, leSelector]), '\n', ''),
    duration: duration,
  };

{
  histogramApdex(
    histogram,
    selector='',
    satisfiedThreshold,
    toleratedThreshold=null
  ):: {
    histogram: histogram,
    selector: selector,
    satisfiedThreshold: satisfiedThreshold,
    toleratedThreshold: toleratedThreshold,
    apdexQuery(aggregationLabels, selector, rangeInterval)::
      local s = self;
      generateApdexScoreQuery(s, aggregationLabels, selector, rangeInterval),

    apdexWeightQuery(aggregationLabels, selector, rangeInterval)::
      local s = self;
      generateApdexComponentQuery(s, aggregationLabels, selector, rangeInterval, 'le="+Inf"'),

    apdexComponentQuery(aggregationLabels, selector, rangeInterval, leSelector)::
      local s = self;
      generateApdexComponentQuery(s, aggregationLabels, selector, rangeInterval, leSelector),

    percentileLatencyQuery(percentile, aggregationLabels, selector, rangeInterval)::
      local s = self;
      generatePercentileLatencyQuery(s, percentile, aggregationLabels, selector, rangeInterval),

    describe()::
      local s = self;
      // TODO: don't assume the metric is in seconds!
      if s.toleratedThreshold == null then
        '%gs' % [s.satisfiedThreshold]
      else
        '%gs/%gs' % [s.satisfiedThreshold, s.toleratedThreshold],
  },
}
