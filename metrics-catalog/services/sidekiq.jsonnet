local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customQuery = metricsCatalog.customQuery;

{
  type: 'sidekiq',
  tier: 'sv',
  autogenerateRecordingRules: false,  // TODO: enable autogeneration of recording rules for this service
  slos: {
    apdexRatio: 0.95,
    errorRatio: 0.05,
  },
  components: {
    latency_sensitive_job_execution: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_completion_seconds_bucket',
        selector='job="gitlab-sidekiq",latency_sensitive="yes"',
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector='job="gitlab-sidekiq",latency_sensitive="yes",le="+Inf"'
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector='job="gitlab-sidekiq",latency_sensitive="yes"'
      ),
    },

    latency_sensitive_job_queueing: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_queue_duration_seconds_bucket',
        selector='job="gitlab-sidekiq",latency_sensitive="yes"',
        satisfiedThreshold=2.5,
      ),

      // TODO: monitor enqueing rates, once we have the appropriate instrumentation
    },

    non_latency_sensitive_job_execution: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_completion_seconds_bucket',
        selector='job="gitlab-sidekiq",latency_sensitive="no"',
        satisfiedThreshold=300,  // 5 minutes
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector='job="gitlab-sidekiq",latency_sensitive="no",le="+Inf"'
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector='job="gitlab-sidekiq",latency_sensitive="no"'
      ),
    },

    non_latency_sensitive_job_queueing: {
      apdex: histogramApdex(
        histogram='sidekiq_jobs_queue_duration_seconds_bucket',
        selector='job="gitlab-sidekiq",latency_sensitive="no"',
        satisfiedThreshold=60,
      ),

      // TODO: monitor enqueing rates, once we have the appropriate instrumentation
    },

  },
}