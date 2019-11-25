local recordingRules = import './recording_rules.libsonnet';

local emitQuery(query, aggregationLabels) =
  |||
    sum by (%(aggregationLabels)s) (
      %(query)s
    )
  ||| % {
    aggregationLabels: aggregationLabels,
    query: query,
  };

{
  customQuery(
    query,
  ):: {
    query: query,
    requestRateRecordingRules(aggregationLabels, labels)::
      [
        recordingRules.requestRate(
          labels=labels,
          expr=emitQuery(query, aggregationLabels),
        ),
      ],
    errorRateRecordingRules(aggregationLabels, labels)::
      [
        recordingRules.errorRate(
          labels=labels,
          expr=emitQuery(query, aggregationLabels),
        ),
      ],
  },
}
