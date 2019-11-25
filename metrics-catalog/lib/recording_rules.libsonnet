{
  apdex(labels, expr):: {
    record: 'gitlab_component_apdex:ratio',
    labels: labels,
    expr: expr,
  },

  apdexWeight(labels, expr)::
    {
      record: 'gitlab_component_apdex:weight:score',
      labels: labels,
      expr: expr,
    },

  requestRate(labels, expr)::
    {
      record: 'gitlab_component_ops:rate',
      labels: labels,
      expr: expr,
    },

  errorRate(labels, expr)::
    {
      record: 'gitlab_component_errors:rate',
      labels: labels,
      expr: expr,
    },

  minApdexSLO(labels, expr)::
    {
      record: 'slo:min:gitlab_service_apdex:ratio',
      labels: labels,
      expr: expr,
    },

  maxErrorsSLO(labels, expr)::
    {
      record: 'slo:max:gitlab_service_errors:ratio',
      labels: labels,
      expr: expr,
    },
}
