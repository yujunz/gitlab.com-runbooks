local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

{
  type: 'redis',
  tier: 'db',
  components: {
    primary_server: {
      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis"',
        instanceFilter='redis_instance_info{role="master"}'
      ),

      significantLabels: ['fqdn'],
    },

    secondary_servers: {
      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector='type="redis"',
        instanceFilter='redis_instance_info{role="slave"}'
      ),

      significantLabels: ['fqdn'],
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
