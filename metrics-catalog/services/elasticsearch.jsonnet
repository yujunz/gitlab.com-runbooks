local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customQuery = metricsCatalog.customQuery;

{
  type: 'elasticsearch',
  tier: 'inf',
  slos: {
    /*
    TODO: enable SLOs for elasticsearch service
    apdexRatio: 0.95,
    errorRatio: 0.005,
    */
  },
  components: {
    search: {
      requestRate: rateMetric(
        counter='elasticsearch_indices_search_query_total',
        selector='job="elasticsearch"'
      ),

      significantLabels: ['name'],
    },

    indexing: {
      requestRate: rateMetric(
        counter='elasticsearch_indices_indexing_index_total',
        selector='job="elasticsearch"'
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
