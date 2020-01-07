local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customQuery = metricsCatalog.customQuery;
local combined = metricsCatalog.combined;

{
  type: 'patroni',
  tier: 'db',
  slos: {
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
    },
  },
}
