local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;

{
  type: 'pgbouncer',
  tier: 'db',
  serviceDependencies: {
    patroni: true,
  },
  components: {
    service: {
      // The same query, with different labels is also used on the patroni nodes pgbouncer instances
      requestRate: combined([
        rateMetric(
          counter='pgbouncer_stats_sql_transactions_pooled_total',
          selector='type="pgbouncer", tier="db"'
        ),
        rateMetric(
          counter='pgbouncer_stats_queries_pooled_total',
          selector='type="pgbouncer", tier="db"'
        ),
      ]),

      significantLabels: ['fqdn'],
    },
  },

  saturationTypes: [
    'cpu',
    'memory',
    'open_fds',
    'pgbouncer_async_pool',
    'pgbouncer_single_core',
    'pgbouncer_sync_pool',
    'single_node_cpu',
  ],
}
