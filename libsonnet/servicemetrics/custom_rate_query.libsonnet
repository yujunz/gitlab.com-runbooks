local aggregations = import 'promql/aggregations.libsonnet';

{
  // A custom rate query allows arbitrary PromQL to be used as a rate query
  // This can be helpful if the metric is exposed as a guage or in another manner
  customRateQuery(
    query,
  ):: {
    query: query,
    aggregatedRateQuery(aggregationLabels, selector, rangeInterval)::
      // Note that we ignore the rangeInterval and selectors for now
      // TODO: handle selector and rangeIntervals better, if we can
      aggregations.aggregateOverQuery('sum', aggregationLabels, query),
  },
}
