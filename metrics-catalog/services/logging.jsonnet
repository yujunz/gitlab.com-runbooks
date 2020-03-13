local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customQuery = metricsCatalog.customQuery;

{
  type: 'logging',
  tier: 'inf',
  slos: {
    /*
    TODO: enable SLOs for logging service
    apdexRatio: 0.95,
    errorRatio: 0.005,
    */
  },
  components: {
    elasticsearch_searching: {
      requestRate: rateMetric(
        counter='elasticsearch_indices_search_query_total',
        selector='type="logging"'
      ),

      significantLabels: ['name'],
    },

    elasticsearch_indexing: {
      requestRate: rateMetric(
        counter='elasticsearch_indices_indexing_index_total',
        selector='type="logging"'
      ),

      significantLabels: ['name'],
    },
  },

  saturationTypes: [
    'elastic_cpu',
    'elastic_single_node_cpu',
    'elastic_disk_space',
    'elastic_jvm_heap_memory',
  ],
}
