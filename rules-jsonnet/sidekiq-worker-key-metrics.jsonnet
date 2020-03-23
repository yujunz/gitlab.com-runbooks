local metricsCatalog = import './lib/metrics.libsonnet';
local sidekiqMetricsCatalog = import './services/sidekiq.jsonnet';
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
      runbook: 'troubleshooting/service-{{ $labels.type }}.md',
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
