local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

{
  type: 'sidekiq',
  tier: 'sv',
  slos: {
    apdexRatio: 0.95,
    errorRatio: 0.05,
  },
  components: {
    latency_sensitive_job_execution: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_completion_seconds_bucket',
        selector='latency_sensitive="yes"',
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector='latency_sensitive="yes",le="+Inf"'
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector='latency_sensitive="yes"'
      ),

      significantLabels: ['priority'],
    },

    latency_sensitive_job_queueing: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_queue_duration_seconds_bucket',
        selector='latency_sensitive="yes"',
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='sidekiq_enqueued_jobs_total',
        selector='latency_sensitive="yes"'
      ),

      significantLabels: ['priority'],
    },

    non_latency_sensitive_job_execution: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_completion_seconds_bucket',
        selector='latency_sensitive="no"',
        satisfiedThreshold=300,  // 5 minutes
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector='latency_sensitive="no",le="+Inf"'
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector='latency_sensitive="no"'
      ),

      significantLabels: ['priority'],
    },

    non_latency_sensitive_job_queueing: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_queue_duration_seconds_bucket',
        selector='latency_sensitive="no"',
        satisfiedThreshold=60,
      ),

      requestRate: rateMetric(
        counter='sidekiq_enqueued_jobs_total',
        selector='latency_sensitive="no"'
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
