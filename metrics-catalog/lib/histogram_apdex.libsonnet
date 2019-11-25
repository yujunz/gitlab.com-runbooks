local recordingRules = import './recording_rules.libsonnet';
local selectors = import './selectors.libsonnet';

// A single threshold apdex score only has a SATISFACTORY threshold, no TOLERABLE threshold
local generateSingleThresholdApdexScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, duration) =
  local selector = selectors.join([histogramApdex.selector, additionalSelectors]);
  local satisfiedSelector = selectors.join([selector, 'le="%g"' % [histogramApdex.satisfiedThreshold]]);
  local totalSelector = selectors.join([selector, 'le="+Inf"']);
  |||
    (
      sum by (%(aggregationLabels)s) (
        rate(%(histogram)s{%(satisfiedSelector)s}[%(duration)s])
      )
    )
    /
    (
      sum by (%(aggregationLabels)s) (
        rate(%(histogram)s{%(totalSelector)s}[%(duration)s])
      ) > 0
    )
  ||| % {
    aggregationLabels: aggregationLabels,
    histogram: histogramApdex.histogram,
    satisfiedSelector: satisfiedSelector,
    totalSelector: totalSelector,
    duration: duration,
  };

// A double threshold apdex score only has both SATISFACTORY threshold and TOLERABLE thresholds
local generateDoubleThresholdApdexScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, duration) =
  local selector = selectors.join([histogramApdex.selector, additionalSelectors]);
  local satisfiedSelector = selectors.join([selector, 'le="%g"' % [histogramApdex.satisfiedThreshold]]);
  local toleratedThresholdSelector = selectors.join([selector, 'le="%g"' % [histogramApdex.toleratedThreshold]]);
  local totalSelector = selectors.join([selector, 'le="+Inf"']);
  |||
    (
      sum by (%(aggregationLabels)s) (
        rate(%(histogram)s{%(satisfiedSelector)s}[%(duration)s])
      )
      +
      sum by (%(aggregationLabels)s) (
        rate(%(histogram)s{%(toleratedThresholdSelector)s}[%(duration)s])
      )
    )
    /
    2
    /
    (
      sum by (%(aggregationLabels)s) (
        rate(%(histogram)s{%(totalSelector)s}[%(duration)s])
      ) > 0
    )
  ||| % {
    aggregationLabels: aggregationLabels,
    histogram: histogramApdex.histogram,
    satisfiedSelector: satisfiedSelector,
    toleratedThresholdSelector: toleratedThresholdSelector,
    totalSelector: totalSelector,
    duration: duration,
  };


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

local generateApdexWeightScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, duration) =
  local selector = selectors.join([histogramApdex.selector, additionalSelectors]);
  local totalSelector = selectors.join([selector, 'le="+Inf"']);

  |||
    sum by (%(aggregationLabels)s) (
      rate(%(histogram)s{%(totalSelector)s}[%(duration)s])
    )
  ||| % {
    aggregationLabels: aggregationLabels,
    histogram: histogramApdex.histogram,
    totalSelector: totalSelector,
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
    apdexRecordingRules(aggregationLabels, labels)::
      local s = self;
      [
        recordingRules.apdex(
          labels=labels,
          expr=generateApdexScoreQuery(s, aggregationLabels, '', '1m')
        ),
        recordingRules.apdexWeight(
          labels=labels,
          expr=generateApdexWeightScoreQuery(s, aggregationLabels, '', '1m')
        ),
      ],
    apdexQuery(aggregationLabels, selector, rangeInterval)::
      local s = self;
      generateApdexScoreQuery(s, aggregationLabels, selector, rangeInterval),

    percentileLatencyQuery(percentile, aggregationLabels, selector, rangeInterval)::
      local s = self;
      generatePercentileLatencyQuery(s, percentile, aggregationLabels, selector, rangeInterval),
  },
}
