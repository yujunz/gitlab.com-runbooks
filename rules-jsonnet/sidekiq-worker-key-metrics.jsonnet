local metricsCatalog = import './lib/metrics.libsonnet';
local sidekiqMetricsCatalog = import './services/sidekiq.jsonnet';

local aggregationLabels = 'environment, tier, type, stage, shard, priority, queue, feature_category, urgency';
local burnRateRangeIntervals = ['5m', '30m', '1h', '6h'];

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
    for rangeInterval in burnRateRangeIntervals
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
  } for rangeInterval in burnRateRangeIntervals];

// TODO: add alerting
local generateAlerts() =
  [];

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
