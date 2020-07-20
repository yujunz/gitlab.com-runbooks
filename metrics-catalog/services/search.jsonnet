local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local derivMetric = metricsCatalog.derivMetric;
local customQuery = metricsCatalog.customQuery;

metricsCatalog.serviceDefinition({
  type: 'search',
  tier: 'inf',
  /*
   * Until this service starts getting more predictable traffic volumes
   * disable anomaly detection for RPS
   */
  disableOpsRatePrediction: true,
  components: {
    elasticsearch_searching: {
      requestRate: derivMetric(
        counter='elasticsearch_indices_search_query_total',
        selector='type="search"',
        clampMinZero=true,
      ),

      significantLabels: ['name'],
    },

    elasticsearch_indexing: {
      requestRate: derivMetric(
        counter='elasticsearch_indices_indexing_index_total',
        selector='type="search"',
        clampMinZero=true,
      ),

      significantLabels: ['name'],
    },
  },
})
