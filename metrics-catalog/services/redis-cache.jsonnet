local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'redis-cache',
  tier: 'db',
  monitoringThresholds: {
    apdexScore: 0.9995,
    errorRatio: 0.999,
  },
  components: {
    rails_redis_client: {
      staticLabels: {
        tier: 'db',
        stage: 'main',
      },
      significantLabels: ['type'],

      requestRate: rateMetric(
        counter='gitlab_redis_client_requests_total',
        selector='storage="cache"',
      ),

      errorRate: rateMetric(
        counter='gitlab_redis_client_exceptions_total',
        selector='storage="cache"',
      ),
    },

    primary_server: {
      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-cache"',
        instanceFilter='redis_instance_info{role="master"}'
      ),

      significantLabels: ['fqdn'],
    },

    secondary_servers: {
      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-cache"',
        instanceFilter='redis_instance_info{role="slave"}'
      ),

      significantLabels: ['fqdn'],
      aggregate_rps: 'no',
    },

    // Rails Cache uses metrics from the main application to guage to performance of the Redis cache
    // This is useful since it's not easy for us to directly calculate an apdex from the Redis metrics
    // directly
    rails_cache: {
      staticLabels: {
        // Redis only has a main stage, but since we take this metric from other services
        // which do have a `stage`, we should not aggregate on it
        stage: 'main',
      },

      apdex: histogramApdex(
        histogram='gitlab_cache_operation_duration_seconds_bucket',
        satisfiedThreshold=0.01,
        toleratedThreshold=0.1
      ),

      requestRate: rateMetric(
        counter='gitlab_cache_operation_duration_seconds_count',
      ),

      significantLabels: [],
    },
  },
})
