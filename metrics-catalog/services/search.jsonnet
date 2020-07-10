local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local derivMetric = metricsCatalog.derivMetric;
local customQuery = metricsCatalog.customQuery;

metricsCatalog.serviceDefinition({
  type: 'search',
  tier: 'inf',
  slos: {
    /*
    TODO: enable SLOs
    apdexRatio: 0.95,
    errorRatio: 0.005,
    */
  },
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
