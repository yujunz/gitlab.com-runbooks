local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local sidekiqHelpers = import './lib/sidekiq-helpers.libsonnet';
local perWorkerRecordingRules = (import './lib/sidekiq-per-worker-recording-rules.libsonnet').perWorkerRecordingRules;
local combined = metricsCatalog.combined;

local highUrgencySelector = {
  urgency: 'high',
};

local lowUrgencySelector = {
  urgency: 'low',
};

local throttledUrgencySelector = {
  urgency: 'throttled',
};

local noUrgencySelector = {
  urgency: '',
};

{
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
  components: {
    ['shard_' + std.strReplace(k, '-', '_')]: {
      local shardSelector = { shard: k },
      apdex: combined([
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
        histogramApdex(
          histogram='sidekiq_jobs_completion_seconds_bucket',
          selector=throttledUrgencySelector + shardSelector,
          satisfiedThreshold=sidekiqHelpers.slos.throttled.executionDurationSeconds,
        ),
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
      ]),

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_bucket',
        selector=shardSelector { le: '+Inf' },
      ),

      errorRate: rateMetric(
        counter='sidekiq_jobs_failed_total',
        selector=shardSelector,
      ),

      significantLabels: ['fqdn'],
    }
    for k in sidekiqHelpers.shards.listAll()
  },

  // Special per-worker recording rules
  extraRecordingRulesPerBurnRate: [
    // Adds per-work queuing/execution apdex, plus error rates etc
    // across multiple burn rates
    perWorkerRecordingRules,
  ],
}
