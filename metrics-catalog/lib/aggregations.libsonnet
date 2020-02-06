{
  // Wraps a query in an aggregation function, using the provided aggregation labels
  aggregateOverQuery(aggregationFunction, aggregationLabels, query)::
    |||
      %(aggregationFunction)s by (%(aggregationLabels)s) (
        %(query)s
      )
    ||| % {
      aggregationFunction: aggregationFunction,
      aggregationLabels: aggregationLabels,
      query: query,
    },
}
