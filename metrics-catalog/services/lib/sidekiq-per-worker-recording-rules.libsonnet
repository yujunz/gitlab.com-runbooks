local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local sidekiqHelpers = import './sidekiq-helpers.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;
local aggregationLabels = [
  'environment',
  'tier',
  'type',
  'stage',
  'shard',
  'queue',
  'feature_category',
  'urgency',
];

// This is used to calculate the queue apdex across all queues
local combinedQueueApdex = combined([
  histogramApdex(
    histogram='sidekiq_jobs_queue_duration_seconds_bucket',
    selector={ urgency: 'high' },
    satisfiedThreshold=sidekiqHelpers.slos.urgent.queueingDurationSeconds,
  ),
  histogramApdex(
    histogram='sidekiq_jobs_queue_duration_seconds_bucket',
    selector={ urgency: 'low' },
    satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.queueingDurationSeconds,
  ),
]);

local combinedExecutionApdex = combined([
  histogramApdex(
    histogram='sidekiq_jobs_completion_seconds_bucket',
    selector={ urgency: 'high' },
    satisfiedThreshold=sidekiqHelpers.slos.urgent.executionDurationSeconds,
  ),
  histogramApdex(
    histogram='sidekiq_jobs_completion_seconds_bucket',
    selector={ urgency: 'low' },
    satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,
  ),
  histogramApdex(
    histogram='sidekiq_jobs_completion_seconds_bucket',
    selector={ urgency: 'throttled' },
    satisfiedThreshold=sidekiqHelpers.slos.throttled.executionDurationSeconds,
  ),
]);

local queueRate = rateMetric(
  counter='sidekiq_enqueued_jobs_total',
  selector={},
);

local requestRate = rateMetric(
  counter='sidekiq_jobs_completion_seconds_bucket',
  selector={ le: '+Inf' },
);

local errorRate = rateMetric(
  counter='sidekiq_jobs_failed_total',
  selector={},
);

{
  // Record queue apdex, execution apdex, error rates, QPS metrics
  // for each worker, similar to how we record these for each
  // service
  perWorkerRecordingRules(rangeInterval)::
    [
      {  // Key metric: Queueing apdex (ratio)
        record: 'gitlab_background_jobs:queue:apdex:ratio_%s' % [rangeInterval],
        expr: combinedQueueApdex.apdexQuery(aggregationLabels, {}, rangeInterval),
      },
      {  // Key metric: Queueing apdex (weight score)
        record: 'gitlab_background_jobs:queue:apdex:weight:score_%s' % [rangeInterval],
        expr: combinedQueueApdex.apdexWeightQuery(aggregationLabels, {}, rangeInterval),
      },
      {  // Key metric: Queueing operations/second
        record: 'gitlab_background_jobs:queue:ops:rate_%s' % [rangeInterval],
        expr: queueRate.aggregatedRateQuery(aggregationLabels, {}, rangeInterval),
      },
      {  // Key metric: Execution apdex (ratio)
        record: 'gitlab_background_jobs:execution:apdex:ratio_%s' % [rangeInterval],
        expr: combinedExecutionApdex.apdexQuery(aggregationLabels, {}, rangeInterval),
      },
      {  // Key metric: Execution apdex (weight score)
        record: 'gitlab_background_jobs:execution:apdex:weight:score_%s' % [rangeInterval],
        expr: combinedExecutionApdex.apdexWeightQuery(aggregationLabels, {}, rangeInterval),
      },
      {  // Key metric: QPS
        record: 'gitlab_background_jobs:execution:ops:rate_%s' % [rangeInterval],
        expr: requestRate.aggregatedRateQuery(aggregationLabels, {}, rangeInterval),
      },
      {  // Key metric: Errors per Second
        record: 'gitlab_background_jobs:execution:error:rate_%s' % [rangeInterval],
        expr: errorRate.aggregatedRateQuery(aggregationLabels, {}, rangeInterval),
      },
      {
        record: 'gitlab_background_jobs:execution:error:ratio_%s' % [rangeInterval],
        expr: |||
          gitlab_background_jobs:execution:error:rate_%(rangeInterval)s
          /
          gitlab_background_jobs:execution:ops:rate_%(rangeInterval)s
        ||| % { rangeInterval: rangeInterval },
      },
    ],
}
