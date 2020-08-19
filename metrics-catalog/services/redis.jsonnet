local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'redis',
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

      apdex: histogramApdex(
        histogram='gitlab_redis_client_requests_duration_seconds_bucket',
        selector={ storage: 'shared_state' },
        satisfiedThreshold=0.5,
        toleratedThreshold=0.75,
      ),

      requestRate: rateMetric(
        counter='gitlab_redis_client_requests_total',
        selector={ storage: 'shared_state' },
      ),

      errorRate: rateMetric(
        counter='gitlab_redis_client_exceptions_total',
        selector={ storage: 'shared_state' },
      ),
    },

    primary_server: {
      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis"',
        instanceFilter='redis_instance_info{role="master"}'
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.kibana(title='Redis', index='redis', type='redis'),
      ],
    },

    secondary_servers: {
      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis"',
        instanceFilter='redis_instance_info{role="slave"}'
      ),

      significantLabels: ['fqdn'],
      aggregateRequestRate: false,
    },
  },
})
