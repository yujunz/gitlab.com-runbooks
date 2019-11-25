local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customQuery = metricsCatalog.customQuery;

{
  type: 'ci-runners',
  tier: 'runners',
  slos: {
    apdexRatio: 0.50,
    errorRatio: 0.01,
  },
  components: {
    polling: {
      requestRate: rateMetric(
        counter='gitlab_workhorse_builds_register_handler_requests',
        selector=''
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_builds_register_handler_requests',
        selector='status=~"body-parse-error|body-read-error|missing-values|watch-error"'
      ),
    },

    shared_runner_queues: {
      // CI runners don't expose correct labels at present
      // https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/8456
      staticLabels: {
        environment: 'gprd',
        stage: 'main',
      },

      apdex: histogramApdex(
        histogram='job_queue_duration_seconds_bucket',
        selector='shared_runner="true", jobs_running_for_project=~"^(0|1|2|3|4)$"',
        satisfiedThreshold=60,
      ),

      requestRate: rateMetric(
        counter='gitlab_runner_jobs_total',
        selector='job="shared-runners"'
      ),

      errorRate: rateMetric(
        counter='gitlab_runner_failed_jobs_total',
        selector='job="shared-runners", failure_reason="runner_system_failure"'
      ),
    },
  },
}
