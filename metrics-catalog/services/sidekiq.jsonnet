local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local sidekiqHelpers = import './lib/sidekiq-helpers.libsonnet';
local combined = metricsCatalog.combined;

local shards = [
  'memory-bound',
  'urgent-other',
  'elasticsearch',
  'catchall',
  'low-urgency-cpu-bound',
  'urgent-cpu-bound',
];

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
        selector=shardSelector { le: '+Inf' },
      ),

      significantLabels: ['fqdn'],
    }
    for k in shards
  },
}
