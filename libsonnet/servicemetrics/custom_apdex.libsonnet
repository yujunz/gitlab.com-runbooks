local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';

local generateQuery(rateQueryTemplate, selector, rangeInterval) =
  local s = if selector == '' then '__name__!=""' else selector;

  rateQueryTemplate % {
    selector: selectors.serializeHash(s),
    rangeInterval: rangeInterval,
  };

local groupByClauseFor(substituteWeightWithRecordingRule, aggregationLabels) =
  if substituteWeightWithRecordingRule == null then
    ''
  else
    ' on(%(aggregationLabels)s) group_left()' % {
      aggregationLabels: aggregations.serialize(aggregationLabels),
    };

// A single threshold apdex score only has a SATISFACTORY threshold, no TOLERABLE threshold
local generateSingleThresholdApdexScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration, substituteWeightWithRecordingRule) =
  local selector = selectors.merge(customApdex.selector, additionalSelectors);
  local satisfiedSelector = selectors.merge(selector, { le: customApdex.satisfiedThreshold });
  local satisfiedRateQuery = generateQuery(customApdex.rateQueryTemplate, satisfiedSelector, duration);

  local denominatorAggregation = if substituteWeightWithRecordingRule == null then
    local totalSelector = selectors.merge(selector, { le: '+Inf' });
    local totalRateQuery = generateQuery(customApdex.rateQueryTemplate, totalSelector, duration);
    aggregations.aggregateOverQuery('sum', aggregationLabels, totalRateQuery)
  else
    substituteWeightWithRecordingRule;

  |||
    (
      %(satisfactoryAggregation)s
    )
    /%(groupByClause)s
    (
      %(denominatorAggregation)s > 0
    )
  ||| % {
    groupByClause: groupByClauseFor(substituteWeightWithRecordingRule, aggregationLabels),
    satisfactoryAggregation: strings.indent(aggregations.aggregateOverQuery('sum', aggregationLabels, satisfiedRateQuery), 2),
    denominatorAggregation: strings.indent(denominatorAggregation, 2),
  };

// A double threshold apdex score only has both SATISFACTORY threshold and TOLERABLE thresholds
local generateDoubleThresholdApdexScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration, substituteWeightWithRecordingRule) =
  local selector = selectors.merge(customApdex.selector, additionalSelectors);
  local satisfiedSelector = selectors.merge(selector, { le: customApdex.satisfiedThreshold });
  local toleratedSelector = selectors.merge(selector, { le: customApdex.toleratedThreshold });
  local satisfiedRateQuery = generateQuery(customApdex.rateQueryTemplate, satisfiedSelector, duration);
  local toleratedRateQuery = generateQuery(customApdex.rateQueryTemplate, toleratedSelector, duration);

  local denominatorAggregation = if substituteWeightWithRecordingRule == null then
    local totalSelector = selectors.merge(selector, { le: '+Inf' });
    local totalRateQuery = generateQuery(customApdex.rateQueryTemplate, totalSelector, duration);
    aggregations.aggregateOverQuery('sum', aggregationLabels, totalRateQuery)
  else
    substituteWeightWithRecordingRule;

  |||
    (
      %(satisfactoryAggregation)s
      +
      %(toleratedAggregation)s
    )
    /
    2
    /%(groupByClause)s
    (
      %(denominatorAggregation)s > 0
    )
  ||| % {
    groupByClause: groupByClauseFor(substituteWeightWithRecordingRule, aggregationLabels),
    satisfactoryAggregation: strings.indent(aggregations.aggregateOverQuery('sum', aggregationLabels, satisfiedRateQuery), 2),
    toleratedAggregation: strings.indent(aggregations.aggregateOverQuery('sum', aggregationLabels, toleratedRateQuery), 2),
    denominatorAggregation: strings.indent(denominatorAggregation, 2),
  };


local generateApdexScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration, substituteWeightWithRecordingRule) =
  if customApdex.toleratedThreshold == null then
    generateSingleThresholdApdexScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration, substituteWeightWithRecordingRule)
  else
    generateDoubleThresholdApdexScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration, substituteWeightWithRecordingRule);

local generatePercentileLatencyQuery(customApdex, percentile, aggregationLabels, additionalSelectors, duration) =
  local aggregationLabelsWithLe = aggregationLabels + ['le'];
  local rateQuery = generateQuery(customApdex.rateQueryTemplate, additionalSelectors, duration);

  |||
    histogram_quantile(
      %(percentile)f,
      %(aggregatedRateQuery)s
    )
  ||| % {
    percentile: percentile,
    aggregatedRateQuery: strings.indent(aggregations.aggregateOverQuery('sum', aggregationLabelsWithLe, rateQuery), 2),
  };

local generateApdexWeightScoreQuery(customApdex, aggregationLabels, additionalSelectors, duration) =
  local selectorsWithAdditional = selectors.merge(customApdex.selector, additionalSelectors);
  local selectorsWithAdditionalAndLe = selectors.merge(selectorsWithAdditional, { le: '+Inf' });
  local totalRateQuery = generateQuery(customApdex.rateQueryTemplate, selectorsWithAdditionalAndLe, duration);

  aggregations.aggregateOverQuery('sum', aggregationLabels, totalRateQuery);

{
  customApdex(
    rateQueryTemplate,
    selector,
    satisfiedThreshold,
    toleratedThreshold=null
  ):: {
    rateQueryTemplate: rateQueryTemplate,
    selector: selector,
    satisfiedThreshold: satisfiedThreshold,
    toleratedThreshold: toleratedThreshold,

    apdexQuery(aggregationLabels, selector, rangeInterval, substituteWeightWithRecordingRule=null)::
      local s = self;
      generateApdexScoreQuery(s, aggregationLabels, selector, rangeInterval, substituteWeightWithRecordingRule=substituteWeightWithRecordingRule),

    apdexWeightQuery(aggregationLabels, selector, rangeInterval)::
      local s = self;
      generateApdexWeightScoreQuery(s, aggregationLabels, selector, rangeInterval),

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
