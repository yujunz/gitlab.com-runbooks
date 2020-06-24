local strings = import 'strings.libsonnet';

local serialize(labels) =
  if std.isString(labels) then
    strings.chomp(labels)
  else
    std.join(',', labels);

{
  // Given an array of aggregation labels, formats as a string
  serialize(labels)::
    serialize(labels),

  // Wraps a query in an aggregation function, using the provided aggregation labels
  aggregateOverQuery(aggregationFunction, aggregationLabels, query)::
    |||
      %(aggregationFunction)s by (%(aggregationLabels)s) (
        %(query)s
      )
    ||| % {
      aggregationFunction: aggregationFunction,
      aggregationLabels: serialize(aggregationLabels),
      query: strings.indent(strings.chomp(query), 2),
    },
}
