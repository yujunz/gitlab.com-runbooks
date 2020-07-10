local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local sidekiqHelpers = import './lib/sidekiq-helpers.libsonnet';
local perWorkerRecordingRules = (import './lib/sidekiq-per-worker-recording-rules.libsonnet').perWorkerRecordingRules;
local combined = metricsCatalog.combined;

local highUrgencySelector = { urgency: 'high' };
local lowUrgencySelector = { urgency: 'low' };
local throttledUrgencySelector = { urgency: 'throttled' };
local noUrgencySelector = { urgency: '' };

metricsCatalog.serviceDefinition({
  type: 'sidekiq',
  tier: 'sv',
  deprecatedSingleBurnThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.05,
  },
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.995,
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
  // Use recordingRuleMetrics to specify a set of metrics with known high
  // cardinality. The metrics catalog will generate recording rules with
  // the appropriate aggregations based on this set.
  // Use sparingly, and don't overuse.
  recordingRuleMetrics: [
    'sidekiq_jobs_completion_seconds_bucket',
    'sidekiq_jobs_queue_duration_seconds_bucket',
    'sidekiq_jobs_failed_total',
  ],
  components: {
    ['shard_' + std.strReplace(shard.name, '-', '_')]: {
      local shardSelector = { shard: shard.name },
      apdex: combined(
        (
          if shard.urgency == null || shard.urgency == 'high' then
            [
              histogramApdex(
                histogram='sidekiq_jobs_completion_seconds_bucket',
                selector=highUrgencySelector + shardSelector,
                satisfiedThreshold=sidekiqHelpers.slos.urgent.executionDurationSeconds,
              ),
              histogramApdex(
                histogram='sidekiq_jobs_queue_duration_seconds_bucket',
                selector=highUrgencySelector + shardSelector,
                satisfiedThreshold=sidekiqHelpers.slos.urgent.queueingDurationSeconds,
              ),
            ] else []
        )
        +
        (
          if shard.urgency == null || shard.urgency == 'low' then
            [
              histogramApdex(
                histogram='sidekiq_jobs_completion_seconds_bucket',
                selector=lowUrgencySelector + shardSelector,
                satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,
              ),
              histogramApdex(
                histogram='sidekiq_jobs_queue_duration_seconds_bucket',
                selector=lowUrgencySelector + shardSelector,
                satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.queueingDurationSeconds,
              ),
            ] else []
        )
        +
        (
          if shard.urgency == null || shard.urgency == 'throttled' then
            [
              histogramApdex(
                histogram='sidekiq_jobs_completion_seconds_bucket',
                selector=throttledUrgencySelector + shardSelector,
                satisfiedThreshold=sidekiqHelpers.slos.throttled.executionDurationSeconds,
              ),
            ] else []
        ) +
        (
          if shard.urgency == null then
            [
              // TODO: remove this once all unattribute jobs are removed
              // Treat `urgency=""` as low urgency jobs.
              histogramApdex(
                histogram='sidekiq_jobs_completion_seconds_bucket',
                selector=noUrgencySelector + shardSelector,
                satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.executionDurationSeconds,
              ),
              histogramApdex(
                histogram='sidekiq_jobs_queue_duration_seconds_bucket',
                selector=noUrgencySelector + shardSelector,
                satisfiedThreshold=sidekiqHelpers.slos.lowUrgency.queueingDurationSeconds,
              ),
            ] else []
        )
      ),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector=shardSelector { le: '+Inf' },
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=shardSelector,
      ),

      significantLabels: ['feature_category', 'queue', 'urgency'],
    }
    for shard in sidekiqHelpers.shards.listAll()
  },

  // Special per-worker recording rules
  extraRecordingRulesPerBurnRate: [
    // Adds per-work queuing/execution apdex, plus error rates etc
    // across multiple burn rates
    perWorkerRecordingRules,
  ],
})
