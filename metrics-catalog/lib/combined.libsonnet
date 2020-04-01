local aggregations = import './aggregations.libsonnet';
local selectors = import './selectors.libsonnet';

local generateRateQuery(c, selector, rangeInterval) =
  local rateQueries = std.map(function(i) i.rateQuery(selector, rangeInterval), c.metrics);
  std.join('\n  or\n  ', rateQueries);

local generateChangesQuery(c, selector, rangeInterval) =
  local changesQueries = std.map(function(i) i.changesQuery(selector, rangeInterval), c.metrics);
  std.join('\n  or\n  ', changesQueries);

// Call `combinedApdexQuery` on the first of the queries to combine.
// This is arbitrary; we'll get the same result by calling this method
// on any item of `c`.
local generateApdexQuery(c, aggregationLabels, selector, rangeInterval) =
  c.firstMetric().combinedApdexQuery(c.metrics, aggregationLabels, selector, rangeInterval);

local generateApdexWeightQuery(c, aggregationLabels, selector, rangeInterval) =
  local apdexWeightQueries = std.map(function(i) i.apdexWeightQuery(aggregationLabels, selector, rangeInterval), c.metrics);
  std.join('or\n', apdexWeightQueries);

local generateApdexPercentileLatencyQuery(c, percentile, aggregationLabels, selector, rangeInterval) =
  c.firstMetric().combinedPercentileLatencyQuery(c.metrics, percentile, aggregationLabels, selector, rangeInterval);

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

    // This creates a changes query of the form
    // rate(....{<selector>}[<rangeInterval>])
    changesQuery(selector, rangeInterval)::
      generateChangesQuery(self, selector, rangeInterval),

    // This creates an aggregated rate query of the form
    // sum by(<aggregationLabels>) (...)
    aggregatedRateQuery(aggregationLabels, selector, rangeInterval)::
      local query = generateRateQuery(self, selector, rangeInterval);
      aggregations.aggregateOverQuery('sum', aggregationLabels, query),

    // This creates an aggregated changes query of the form
    // sum by(<aggregationLabels>) (...)
    aggregatedChangesQuery(aggregationLabels, selector, rangeInterval)::
      local query = generateChangesQuery(self, selector, rangeInterval);
      aggregations.aggregateOverQuery('sum', aggregationLabels, query),

    apdexQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexQuery(self, aggregationLabels, selector, rangeInterval),

    apdexWeightQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexWeightQuery(self, aggregationLabels, selector, rangeInterval),

    percentileLatencyQuery(percentile, aggregationLabels, selector, rangeInterval)::
      generateApdexPercentileLatencyQuery(self, percentile, aggregationLabels, selector, rangeInterval),

    firstMetric()::
      metrics[0],

    // Forward the below methods and fields to the first metric for
    // apdex scores, which is wrong but hopefully not catastrophic.
    describe()::
      self.firstMetric().describe(),

    toleratedThreshold:
      self.firstMetric().toleratedThreshold,

    satisfiedThreshold:
      self.firstMetric().satisfiedThreshold,

  },
}
