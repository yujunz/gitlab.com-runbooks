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

      significantLabels: ['priority'],
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

      significantLabels: ['priority'],
    },

    non_high_urgency_job_execution: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_completion_seconds_bucket',
        selector='urgency!="high"',
        satisfiedThreshold=sidekiqHelpers.slos.nonUrgent.executionDurationSeconds,
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector='urgency!="high",le="+Inf"'
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector='urgency!="high"'
      ),

      significantLabels: ['priority'],
    },

    non_urgency_job_queueing: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_queue_duration_seconds_bucket',
        selector='urgency!="high"',
        satisfiedThreshold=sidekiqHelpers.slos.nonUrgent.queueingDurationSeconds,
      ),

      requestRate: rateMetric(
        counter='sidekiq_enqueued_jobs_total',
        selector='urgency!="high"'
      ),

      significantLabels: ['priority'],
    },
  },

  saturationTypes: [
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'sidekiq_workers',
    'single_node_cpu',
    'single_node_unicorn_workers',
    'workers',
  ],
}
