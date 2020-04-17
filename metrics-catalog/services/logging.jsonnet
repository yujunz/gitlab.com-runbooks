local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local derivMetric = metricsCatalog.derivMetric;
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
      requestRate: derivMetric(
        counter='elasticsearch_indices_search_query_total',
        selector='type="logging"',
        clampMinZero=true,
      ),

      significantLabels: ['name'],
    },

    elasticsearch_indexing: {
      requestRate: derivMetric(
        counter='elasticsearch_indices_indexing_index_total',
        selector='type="logging"',
        clampMinZero=true,
      ),

      significantLabels: ['name'],
    },

    // Stackdriver component represents log messages
    // ingested in Google Stackdrive Logging in GCP
    stackdriver: {
      staticLabels: {
        stage: 'main',
      },

      requestRate: rateMetric(
        counter='stackdriver_gce_instance_logging_googleapis_com_log_entry_count',
      ),

      significantLabels: ['log', 'severity'],
    },
  },

  saturationTypes: [
    'elastic_cpu',
    'elastic_single_node_cpu',
    'elastic_disk_space',
    'elastic_single_node_disk_space',
    'elastic_jvm_heap_memory',
    'elastic_thread_pools',
  ],
}
