local aggregations = import './aggregations.libsonnet';
local selectors = import './selectors.libsonnet';

local generateRateQuery(c, selector, rangeInterval) =
  local rateQueries = std.map(function(i) i.rateQuery(selector, rangeInterval), c.metrics);
  std.join('\n  or\n  ', rateQueries);

local generateChangesQuery(c, selector, rangeInterval) =
  local changesQueries = std.map(function(i) i.changesQuery(selector, rangeInterval), c.metrics);
  std.join('\n  or\n  ', changesQueries);

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
  },
}
