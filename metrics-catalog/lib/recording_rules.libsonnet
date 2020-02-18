{
  apdex(name, labels, expr):: {
    record: name,
    labels: labels,
    expr: expr,
  },

  apdexWeight(name, labels, expr)::
    {
      record: name,
      labels: labels,
      expr: expr,
    },

  requestRate(name, labels, expr)::
    {
      record: name,
      labels: labels,
      expr: expr,
    },

  errorRate(name, labels, expr)::
    {
      record: name,
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

  maxErrorsEventRateSLO(labels, expr)::
    {
      record: 'slo:max:events:gitlab_service_errors:ratio',
      labels: labels,
      expr: expr,
    },
}
