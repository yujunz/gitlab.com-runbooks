local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

{
  type: 'redis-cache',
  tier: 'db',
  slos: {
    apdexRatio: 0.95,
  },
  components: {
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

  saturationTypes: [
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'redis_clients',
    'redis_memory',
    'single_node_cpu',
    'single_threaded_cpu',
  ],
}