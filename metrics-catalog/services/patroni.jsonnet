local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;

{
  type: 'patroni',
  tier: 'db',
  monitoringThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  components: {
    // We don't have latency histograms for patroni but for now we will
    // use the rails controller SQL latencies as an indirect proxy.
    rails_sql: {
      staticLabels: {
        stage: 'main',
      },

      apdex: histogramApdex(
        histogram='gitlab_sql_duration_seconds_bucket',
        selector='',
        satisfiedThreshold=0.05,
        toleratedThreshold=0.1
      ),

      significantLabels: ['fqdn'],
    },

    service: {
      requestRate: combined([
        rateMetric(
          counter='pg_stat_database_xact_commit',
          selector='type="patroni", tier="db"'
        ),
        rateMetric(
          counter='pg_stat_database_xact_rollback',
          selector='type="patroni", tier="db"'
        ),
      ]),

      errorRate: rateMetric(
        counter='pg_stat_database_xact_rollback',
        selector='type="patroni", tier="db"'
      ),

      significantLabels: ['fqdn'],
    },

    // Records the operations rate for the pgbouncer instances running on the patroni nodes
    pgbouncer: {
      // The same query, with different labels is also used on the patroni nodes pgbouncer instances
      requestRate: combined([
        rateMetric(
          counter='pgbouncer_stats_sql_transactions_pooled_total',
          selector='type="patroni", tier="db"'
        ),
        rateMetric(
          counter='pgbouncer_stats_queries_pooled_total',
          selector='type="patroni", tier="db"'
        ),
      ]),

      significantLabels: ['fqdn'],
    },
  },
}
