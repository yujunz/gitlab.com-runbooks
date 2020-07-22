local alerts = import 'lib/alerts.libsonnet';
local stableIds = import 'lib/stable-ids.libsonnet';

local sidekiqThanosAlerts = [
  /**
     * Throttled queues don’t alert on queues SLAs.
     * This means that we will allow jobs to queue up for any amount of time without alerting.
     * One downside is, and especially as we move over the k8s, we could be not listening to a throttled
     * queue, due to a misconfiguration.
     *
     * Since we don't have an SLA for this we can't use SLA alert to tell us about this problem.
     * This alert is a safety mechanism. We don’t monitor queueing times, but if there were any
     * queuing jobs
     */
    {
      alert: 'sidekiq_throttled_jobs_enqueued_without_dequeuing',
      expr: |||
        (
          sum by (environment, queue, feature_category) (
            gitlab_background_jobs:queue:ops:rate_1h{urgency="throttled"}
          ) > 0
        )
        unless
        (
          sum by (environment, queue, feature_category) (
            gitlab_background_jobs:execution:ops:rate_1h{urgency="throttled"}
          ) > 0
        )
      |||,
      'for': '30m',
      labels: {
        type: 'sidekiq',  // Hardcoded because `gitlab_background_jobs:queue:ops:rate_1h` `type` label depends on the sidekiq client `type`
        tier: 'sv', // Hardcoded because `gitlab_background_jobs:queue:ops:rate_1h` `type` label depends on the sidekiq client `type`
        stage: 'main',
        alert_type: 'cause',
        rules_domain: 'general',
        severity: 's4',
        period: '30m',
      },
      annotations: {
        title: 'Sidekiq jobs are being enqueued without being dequeued',
        description: |||
          The `{{ $labels.queue }}` queue appears to have jobs being enqueued without
          those jobs being executed.

          This could be the result of a Sidekiq server configuration issue, where
          no Sidekiq servers are configured to dequeue the specific queue.
        |||,
        runbook: 'docs/sidekiq/service-sidekiq.md',
        grafana_dashboard_id: 'sidekiq-queue-detail/sidekiq-queue-detail',
        grafana_panel_id: stableIds.hashStableId('queue-length'),
        grafana_variables: 'environment,stage,queue',
        grafana_min_zoom_hours: '6',
        promql_template_1: 'sidekiq_enqueued_jobs_total{environment="$environment", type="$type", stage="$stage", component="$component"}',
      },
    },
];


local rules = {
  groups: [{
    name: 'Sidekiq Aggregated Thanos Alerts',
    partial_response_strategy: 'warn',
    interval: '1m',
    rules:
      std.map(alerts.processAlertRule, sidekiqThanosAlerts)
  }],
};

{
  'sidekiq-alerts.yml': std.manifestYamlDoc(rules),
}
