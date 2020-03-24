local metricsCatalog = import './lib/metrics.libsonnet';
local sidekiqMetricsCatalog = import './services/sidekiq.jsonnet';
local IGNORED_GPRD_QUEUES = import './temp-ignored-gprd-queue-list.libsonnet';
local multiburnFactors = import 'lib/multiburn_factors.libsonnet';
local aggregationLabels = 'environment, tier, type, stage, shard, priority, queue, feature_category, urgency';

// For the first iteration, all sidekiq workers will have the samne
// error budget. In future, we may introduce a criticality attribute to
// allow jobs to have different error budgets based on criticality
local monthlyErrorBudget = (1 - 0.99);  // 99% of sidekiq executions should succeed

// For now, only include jobs that run 0.6 times per second, or 4 times a minute
// in the monitoring. This is to avoid low-volume, noisy alerts
local minimumOperationRateForMonitoring = 4 / 60;

// Uses the component definitions from the metrics catalog to compose new
// recording rules with alternative aggregations
local generateRulesForComponentForBurnRate(queueComponent, executionComponent, rangeInterval) =
  [{  // Key metric: Queueing apdex
    record: 'gitlab_background_jobs:queue:apdex:ratio_%s' % [rangeInterval],
    expr: queueComponent.apdex.apdexQuery(aggregationLabels, '', rangeInterval),
  }, {  // Key metric: Execution apdex
    record: 'gitlab_background_jobs:execution:apdex:ratio_%s' % [rangeInterval],
    expr: executionComponent.apdex.apdexQuery(aggregationLabels, '', rangeInterval),
  }, {  // Key metric: QPS
    record: 'gitlab_background_jobs:execution:ops:rate_%s' % [rangeInterval],
    expr: executionComponent.requestRate.aggregatedRateQuery(aggregationLabels, '', rangeInterval),
  }, {  // Key metric: Errors per Second
    record: 'gitlab_background_jobs:execution:error:rate_%s' % [rangeInterval],
    expr: executionComponent.errorRate.aggregatedRateQuery(aggregationLabels, '', rangeInterval),
  }];

// Generates four key metrics for each urgency, for a single burn rate
local generateRulesForBurnRate(rangeInterval) =
  generateRulesForComponentForBurnRate(
    sidekiqMetricsCatalog.components.high_urgency_job_queueing,
    sidekiqMetricsCatalog.components.high_urgency_job_execution,
    rangeInterval
  ) +
  generateRulesForComponentForBurnRate(
    sidekiqMetricsCatalog.components.non_urgency_job_queueing,
    sidekiqMetricsCatalog.components.non_high_urgency_job_execution,
    rangeInterval
  );

// Generates four key metrics for each urgency, for each burn rate
local generateKeyMetricRules() =
  std.flattenArrays([
    generateRulesForBurnRate(rangeInterval)
    for rangeInterval in multiburnFactors.allWindowIntervals
  ]);

// Recording rules for error ratios at different burn rates
local generateRatioRules() =
  [{
    record: 'gitlab_background_jobs:execution:error:ratio_%s' % [rangeInterval],
    expr: |||
      gitlab_background_jobs:execution:error:rate_%(rangeInterval)s
      /
      gitlab_background_jobs:execution:ops:rate_%(rangeInterval)s
    ||| % { rangeInterval: rangeInterval },
  } for rangeInterval in multiburnFactors.allWindowIntervals];

local sidekiqSLOAlert(alertname, expr, grafanaPanelId, metricName, alertDescription) =
  {
    alert: alertname,
    expr: expr,
    'for': '2m',
    labels: {
      alert_type: 'symptom',
      rules_domain: 'general',
      metric: metricName,
      severity: 's4',
      slo_alert: 'yes',
      experimental: 'yes',
      period: '2m',
    },
    annotations: {
      title: 'The `{{ $labels.queue }}` queue, `{{ $labels.stage }}` stage, has %s' % [alertDescription],
      description: |||
        The `{{ $labels.queue }}` queue, `{{ $labels.stage }}` stage, has %s.

        Currently the metric value is {{ $value | humanizePercentage }}.
      ||| % [alertDescription],
      runbook: 'docs/sidekiq/service-sidekiq.md',
      grafana_dashboard_id: 'sidekiq-queue-detail/sidekiq-queue-detail',
      grafana_panel_id: std.toString(grafanaPanelId),
      grafana_variables: 'environment,stage,queue',
      grafana_min_zoom_hours: '6',
      promql_template_1: '%s{environment="$environment", type="$type", stage="$stage", component="$component"}' % [metricName],
    },
  };

// generateAlerts configures the alerting rules for sidekiq jobs
// For the first iteration, things are fairly basic:
// 1. fixed error rates - 1% error budget
// 2. fixed operation rates - jobs need to run on average 4 times an hour to be
//    included in these alerts
local generateAlerts() =
  local formatConfig = multiburnFactors {
    monthlyErrorBudget: monthlyErrorBudget,
    minimumOperationRateForMonitoring: minimumOperationRateForMonitoring,
  };

  [
    sidekiqSLOAlert(
      alertname='sidekiq_background_job_error_ratio_burn_rate_slo_out_of_bounds',
      expr=|||
        (
          (
            gitlab_background_jobs:execution:error:ratio_1h > (%(burnrate_1h)g * %(monthlyErrorBudget)g)
          and
            gitlab_background_jobs:execution:error:ratio_5m > (%(burnrate_1h)g * %(monthlyErrorBudget)g)
          )
          or
          (
            gitlab_background_jobs:execution:error:ratio_6h > (%(burnrate_6h)g * %(monthlyErrorBudget)g)
          and
            gitlab_background_jobs:execution:error:ratio_30m > (%(burnrate_6h)g * %(monthlyErrorBudget)g)
          )
        )
        and
        (
          gitlab_background_jobs:execution:ops:rate_6h > %(minimumOperationRateForMonitoring)g
        )
      ||| % formatConfig,
      grafanaPanelId=13,
      metricName='gitlab_background_jobs:execution:error:ratio_1h',
      alertDescription='an error rate outside of SLO'
    ),
    sidekiqSLOAlert(
      alertname='sidekiq_background_job_execution_apdex_ratio_burn_rate_slo_out_of_bounds',
      expr=|||
        (
          (
            (1 - gitlab_background_jobs:execution:apdex:ratio_1h) > (%(burnrate_1h)g * %(monthlyErrorBudget)g)
            and
            (1 - gitlab_background_jobs:execution:apdex:ratio_5m) > (%(burnrate_1h)g * %(monthlyErrorBudget)g)
          )
          or
          (
            (1 - gitlab_background_jobs:execution:apdex:ratio_6h) > (%(burnrate_6h)g * %(monthlyErrorBudget)g)
            and
            (1 - gitlab_background_jobs:execution:apdex:ratio_30m) > (%(burnrate_6h)g * %(monthlyErrorBudget)g)
          )
        )
        and
        (
          gitlab_background_jobs:execution:ops:rate_6h > %(minimumOperationRateForMonitoring)g
        )
      ||| % formatConfig,
      grafanaPanelId=11,
      metricName='gitlab_background_jobs:execution:apdex:ratio_1h',
      alertDescription='a execution latency outside of SLO'
    ),
    sidekiqSLOAlert(
      alertname='sidekiq_background_job_queue_apdex_ratio_burn_rate_slo_out_of_bounds',
      expr=|||
        (
          (
            (1 - gitlab_background_jobs:queue:apdex:ratio_1h) > (%(burnrate_1h)g * %(monthlyErrorBudget)g)
            and
            (1 - gitlab_background_jobs:queue:apdex:ratio_5m) > (%(burnrate_1h)g * %(monthlyErrorBudget)g)
          )
          or
          (
            (1 - gitlab_background_jobs:queue:apdex:ratio_6h) > (%(burnrate_6h)g * %(monthlyErrorBudget)g)
            and
            (1 - gitlab_background_jobs:queue:apdex:ratio_30m) > (%(burnrate_6h)g * %(monthlyErrorBudget)g)
          )
        )
        and
        (
          gitlab_background_jobs:execution:ops:rate_6h > %(minimumOperationRateForMonitoring)g
        )
      ||| % formatConfig,
      grafanaPanelId=10,
      metricName='gitlab_background_jobs:queue:apdex:ratio_1h',
      alertDescription='a queue latency outside of SLO'
    ),
    {
      alert: 'sidekiq_throttled_jobs_enqueued_without_dequeuing',
      expr: |||
        (
          sum by (environment, queue, feature_category) (rate(sidekiq_enqueued_jobs_total{urgency="throttled"}[10m] offset 10m)) > 0
        )
        unless
        (
          sum by (environment, queue, feature_category) (rate(sidekiq_jobs_completion_seconds_count{urgency="throttled"}[20m])) > 0
          or
          sum by (environment, queue, feature_category) (rate(sidekiq_jobs_failed_total{urgency="throttled"}[20m])) > 0
          or
          sum by (environment, queue, feature_category) (rate(sidekiq_jobs_retried_total{urgency="throttled"}[20m])) > 0
          or
          sum by (environment, queue, feature_category) (avg_over_time(sidekiq_running_jobs{urgency="throttled"}[20m])) > 0
        )
      |||,
      'for': '2m',
      labels: {
        type: 'sidekiq',  // Hardcoded because `sidekiq_enqueued_jobs_total` `type` label depends on the sidekiq client `type`
        tier: 'sv',  // Hardcoded becayse `sidekiq_enqueued_jobs_total` `tier` label depends on the sidekiq client `tier`
        stage: 'main',
        alert_type: 'cause',
        rules_domain: 'general',
        metric: 'sidekiq_enqueued_jobs_total',
        severity: 's4',
        period: '2m',
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
        grafana_panel_id: '15',
        grafana_variables: 'environment,stage,queue',
        grafana_min_zoom_hours: '6',
        promql_template_1: 'sidekiq_enqueued_jobs_total{environment="$environment", type="$type", stage="$stage", component="$component"}',
      },
    },
    {
      alert: 'ignored_sidekiq_queues_receiving_work',
      expr: |||
        sum by (environment, queue, feature_category) (rate(sidekiq_enqueued_jobs_total{environment="gprd", queue=~"%s"}[5m])) > 0
      ||| % [std.join('|', IGNORED_GPRD_QUEUES)],
      'for': '2m',
      labels: {
        type: 'sidekiq',  // Hardcoded because `sidekiq_enqueued_jobs_total` `type` label depends on the sidekiq client `type`
        tier: 'sv',  // Hardcoded becayse `sidekiq_enqueued_jobs_total` `tier` label depends on the sidekiq client `tier`
        stage: 'main',
        alert_type: 'cause',
        rules_domain: 'general',
        metric: 'sidekiq_enqueued_jobs_total',
        severity: 's1',
        pager: 'pagerduty',
        period: '2m',
      },
      annotations: {
        title: 'Sidekiq jobs are being enqueued to an ignored queue that will never be dequeued',
        description: |||
          The `{{ $labels.queue }}` queue is receiving work, but this queue has been
          explicitly ignored in the `gprd` environment, to help reduce load on
          our redis-sidekiq cluster.

          This is a temporary measure.

          It appears that the `{{ $labels.queue }}` queue is receiving work.
          Since no sidekiq workers are listening to the queue, this work will be
          ignored.

          Recommended course of action: Communicate with the team responsible for
          the {{ $labels.feature_category }} feature category, and find out whether
          the work to the queue is intentional. If it is, update the ignore list on
          https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/tools/sidekiq-config/sidekiq-queue-configurations.libsonnet
          and the corresponding list used for this alert, in
          https://gitlab.com/gitlab-com/runbooks/blob/master/rules-jsonnet/temp-ignored-gprd-queue-list.libsonnet
          removing the ignored queue from both.

          Also, review https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/merge_requests/2948
        |||,
        runbook: 'docs/sidekiq/service-sidekiq.md',
        grafana_dashboard_id: 'sidekiq-queue-detail/sidekiq-queue-detail',
        grafana_panel_id: '15',
        grafana_variables: 'environment,stage,queue',
        grafana_min_zoom_hours: '6',
        promql_template_1: 'sidekiq_enqueued_jobs_total{environment="$environment", queue="$queue"}',
      },
    },
  ];

local rules = {
  groups: [{
    name: 'Sidekiq Queue Key Indicators',
    interval: '1m',
    rules:
      generateKeyMetricRules() +
      generateRatioRules() +
      generateAlerts(),
  }],
};

{
  'sidekiq-worker-key-metrics.yml': std.manifestYamlDoc(rules),
}
