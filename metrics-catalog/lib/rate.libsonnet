local aggregations = import './aggregations.libsonnet';
local selectors = import './selectors.libsonnet';

local generateInstanceFilterQuery(instanceFilter) =
  if instanceFilter == '' then
    ''
  else
    ' and on (instance) ' + instanceFilter;


// Generates a range-vector function using the provided functions
local generateRangeFunctionQuery(rate, rangeFunction, additionalSelectors, rangeInterval) =
  local selector = selectors.join([rate.selector, additionalSelectors]);

  '%(rangeFunction)s(%(counter)s{%(selector)s}[%(rangeInterval)s])%(instanceFilterQuery)s' % {
    rangeFunction: rangeFunction,
    counter: rate.counter,
    selector: selector,
    rangeInterval: rangeInterval,
    instanceFilterQuery: generateInstanceFilterQuery(rate.instanceFilter),
  };

{
  rateMetric(
    counter,
    selector='',
    instanceFilter='',
  ):: {
    counter: counter,
    selector: selector,
    instanceFilter: instanceFilter,

    // This creates a rate query of the form
    // rate(....{<selector>}[<rangeInterval>])
    rateQuery(selector, rangeInterval)::
      generateRangeFunctionQuery(self, 'rate', selector, rangeInterval),

    // This creates a changes query of the form
    // changes(....{<selector>}[<rangeInterval>])
    changesQuery(selector, rangeInterval)::
      generateRangeFunctionQuery(self, 'changes', selector, rangeInterval),

    // This creates an aggregated rate query of the form
    // sum by(<aggregationLabels>) (rate(....{<selector>}[<rangeInterval>]))
    aggregatedRateQuery(aggregationLabels, selector, rangeInterval)::
      local query = generateRangeFunctionQuery(self, 'rate', selector, rangeInterval);
      aggregations.aggregateOverQuery('sum', aggregationLabels, query),

    // This creates an aggregated changes query of the form
    // sum by(<aggregationLabels>) (changes(....{<selector>}[<rangeInterval>]))
    aggregatedChangesQuery(aggregationLabels, selector, rangeInterval)::
      local query = generateRangeFunctionQuery(self, 'changes', selector, rangeInterval);
      aggregations.aggregateOverQuery('sum', aggregationLabels, query),
  },

  // clampMinZero is useful for taking derivatives of poorly-behaved counters
  // that sometimes decrease, such as Elasticsearch indexing rate and Linux
  // iowait.
  // Clamping the deriv to 0 truncates these spurious spikes.
  // We must use deriv rather than rate in these cases to avoid interpreting a
  // small decrease as an increase of almost the absolute value of the counter
  // (i.e. as occurring after a counter reset).
  derivMetric(
    counter,
    selector='',
    instanceFilter='',
    clampMinZero=false,
  ):: {
    counter: counter,
    selector: selector,
    instanceFilter: instanceFilter,
    clampMinZero: clampMinZero,

    // This creates a rate query of the form
    // deriv(....{<selector>}[<rangeInterval>])
    rateQuery(selector, rangeInterval)::
      local query = generateRangeFunctionQuery(self, 'deriv', selector, rangeInterval);
      if self.clampMinZero then
        'clamp_min(%(query)s, 0)' % { query: query }
      else
        query,

    // This creates a changes query of the form
    // changes(....{<selector>}[<rangeInterval>])
    changesQuery(selector, rangeInterval)::
      generateRangeFunctionQuery(self, 'changes', selector, rangeInterval),

    // This creates an aggregated rate query of the form
    // sum by(<aggregationLabels>) (deriv(....{<selector>}[<rangeInterval>]))
    aggregatedRateQuery(aggregationLabels, selector, rangeInterval)::
      local query = generateRangeFunctionQuery(self, 'deriv', selector, rangeInterval);
      local clampedQuery = if self.clampMinZero then
        'clamp_min(%(query)s, 0)' % { query: query }
      else
        query;
      aggregations.aggregateOverQuery('sum', aggregationLabels, clampedQuery),

    // This creates an aggregated changes query of the form
    // sum by(<aggregationLabels>) (changes(....{<selector>}[<rangeInterval>]))
    aggregatedChangesQuery(aggregationLabels, selector, rangeInterval)::
      local query = generateRangeFunctionQuery(self, 'changes', selector, rangeInterval);
      aggregations.aggregateOverQuery('sum', aggregationLabels, query),
  },
}
