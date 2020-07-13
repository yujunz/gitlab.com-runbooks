local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'redis-sidekiq',
  tier: 'db',
  monitoringThresholds: {
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
        selector='storage="queues"',
      ),

      errorRate: rateMetric(
        counter='gitlab_redis_client_exceptions_total',
        selector='storage="queues"',
      ),
    },

    primary_server: {
      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-sidekiq"',
        instanceFilter='redis_instance_info{role="master"}'
      ),

      significantLabels: ['fqdn'],
    },
    secondary_servers: {
      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis-sidekiq"',
        instanceFilter='redis_instance_info{role="slave"}'
      ),

      significantLabels: ['fqdn'],
      aggregate_rps: 'no',
    },
  },
})
