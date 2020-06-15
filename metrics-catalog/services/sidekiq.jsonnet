local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local sidekiqHelpers = import './lib/sidekiq-helpers.libsonnet';

{
  type: 'sidekiq',
  tier: 'sv',
  monitoringThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.05,
  },
  serviceDependencies: {
    gitaly: true,
    'redis-sidekiq': true,
    'redis-cache': true,
    redis: true,
    patroni: true,
    pgbouncer: true,
    nfs: true,
    praefect: true,
  },
  provisioning: {
    kubernetes: true,
    vms: true,
  },
  components: {
    high_urgency_job_execution: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_completion_seconds_bucket',
        selector='urgency="high"',
        satisfiedThreshold=sidekiqHelpers.slos.urgent.executionDurationSeconds,
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector='urgency="high",le="+Inf"'
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector='urgency="high"'
      ),

      significantLabels: ['shard'],
    },

    high_urgency_job_queueing: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_queue_duration_seconds_bucket',
        selector='urgency="high"',
        satisfiedThreshold=sidekiqHelpers.slos.urgent.queueingDurationSeconds,
      ),

      requestRate: rateMetric(
        counter='sidekiq_enqueued_jobs_total',
        selector='urgency="high"'
      ),

      significantLabels: ['shard'],
    },

    low_urgency_job_execution: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_completion_seconds_bucket',
        selector='urgency="low"',
        satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector='urgency="low",le="+Inf"'
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector='urgency="low"'
      ),

      significantLabels: ['shard'],
    },

    low_urgency_job_queueing: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_queue_duration_seconds_bucket',
        selector='urgency="low"',
        satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.queueingDurationSeconds,
      ),

      requestRate: rateMetric(
        counter='sidekiq_enqueued_jobs_total',
        selector='urgency="low"'
      ),

      significantLabels: ['shard'],
    },

    throttled_job_execution: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_completion_seconds_bucket',
        selector='urgency="throttled"',
        satisfiedThreshold=sidekiqHelpers.slos.throttled.executionDurationSeconds,
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector='urgency="throttled",le="+Inf"'
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector='urgency="throttled"'
      ),

      significantLabels: ['shard'],
    },

    throttled_job_queueing: {
      requestRate: rateMetric(
        counter='sidekiq_enqueued_jobs_total',
        selector='urgency="throttled"'
      ),

      significantLabels: ['shard'],
    },
  },
}
