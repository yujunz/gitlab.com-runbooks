local recordingRules = import './recording_rules.libsonnet';
local selectors = import './selectors.libsonnet';

local generateQuery(rateQueryTemplate, selector, rangeInterval) =
  local s = if selector == '' then '__name__!=""' else selector;

  rateQueryTemplate % {
    selector: s,
    rangeInterval: rangeInterval,
  };

// A single threshold apdex score only has a SATISFACTORY threshold, no TOLERABLE threshold
local generateSingleThresholdApdexScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration) =
  local selector = selectors.join([customApdex.selector, additionalSelectors]);
  local satisfiedSelector = selectors.join([selector, 'le="%g"' % [customApdex.satisfiedThreshold]]);
  local totalSelector = selectors.join([selector, 'le="+Inf"']);
  local satisfiedRateQuery = generateQuery(customApdex.rateQueryTemplate, satisfiedSelector, duration);
  local totalRateQuery = generateQuery(customApdex.rateQueryTemplate, totalSelector, duration);
  |||
    (
      sum by (%(aggregationLabels)s) (
        %(satisfiedRateQuery)s
      )
    )
    /
    (
      sum by (%(aggregationLabels)s) (
        %(totalRateQuery)s
      ) > 0
    )
  ||| % {
    aggregationLabels: aggregationLabels,
    satisfiedRateQuery: satisfiedRateQuery,
    totalRateQuery: totalRateQuery,
  };

// A double threshold apdex score only has both SATISFACTORY threshold and TOLERABLE thresholds
local generateDoubleThresholdApdexScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration) =
  local selector = selectors.join([customApdex.selector, additionalSelectors]);
  local satisfiedSelector = selectors.join([selector, 'le="%g"' % [customApdex.satisfiedThreshold]]);
  local toleratedSelector = selectors.join([selector, 'le="%g"' % [customApdex.toleratedThreshold]]);
  local totalSelector = selectors.join([selector, 'le="+Inf"']);
  local satisfiedRateQuery = generateQuery(customApdex.rateQueryTemplate, satisfiedSelector, duration);
  local toleratedRateQuery = generateQuery(customApdex.rateQueryTemplate, toleratedSelector, duration);
  local totalRateQuery = generateQuery(customApdex.rateQueryTemplate, totalSelector, duration);
  |||
    (
      sum by (%(aggregationLabels)s) (
         %(satisfiedRateQuery)s
      )
      +
      sum by (%(aggregationLabels)s) (
        %(toleratedRateQuery)s
      )
    )
    /
    2
    /
    (
      sum by (%(aggregationLabels)s) (
        %(totalRateQuery)s
      ) > 0
    )
  ||| % {
    aggregationLabels: aggregationLabels,
    satisfiedRateQuery: satisfiedRateQuery,
    toleratedRateQuery: toleratedRateQuery,
    totalRateQuery: totalRateQuery,
  };


local generateApdexScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration) =
  if customApdex.toleratedThreshold == null then
    generateSingleThresholdApdexScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration)
  else
    generateDoubleThresholdApdexScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration);

local generatePercentileLatencyQuery(customApdex, percentile, aggregationLabels, additionalSelectors, duration) =
  local aggregationLabelsWithLe = selectors.join([aggregationLabels, 'le']);
  local rateQuery = generateQuery(customApdex.rateQueryTemplate, additionalSelectors, duration);

  |||
    histogram_quantile(
      %(percentile)f,
      sum by (%(aggregationLabelsWithLe)s) (
        %(rateQuery)s
      )
    )
  ||| % {
    percentile: percentile,
    aggregationLabelsWithLe: aggregationLabelsWithLe,
    rateQuery: rateQuery,
  };

local generateApdexWeightScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration) =
  local totalSelector = selectors.join([additionalSelectors, 'le="+Inf"']);
  local totalRateQuery = generateQuery(customApdex.rateQueryTemplate, totalSelector, duration);

  |||
    sum by (%(aggregationLabels)s) (
        %(totalRateQuery)s
    )
  ||| % {
    aggregationLabels: aggregationLabels,
    totalRateQuery: totalRateQuery,
  };

{
  customApdex(
    rateQueryTemplate,
    satisfiedThreshold,
    toleratedThreshold=null
  ):: {
    rateQueryTemplate: rateQueryTemplate,
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
