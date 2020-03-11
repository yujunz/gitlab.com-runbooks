local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;

{
  type: 'pages',
  tier: 'lb',
  monitoringThresholds: {
    errorRatio: 0.005,
  },
  components: {
    loadbalancer: {
      staticLabels: {
        stage: 'main',
      },

      requestRate: rateMetric(
        counter='haproxy_server_sessions_total',
        selector='type="pages", backend=~"pages_https|pages_http"'
      ),

      errorRate: combined([
        rateMetric(
          counter='haproxy_backend_http_responses_total',
          selector='type="pages",job="haproxy",code="5xx"'
        ),
        rateMetric(
          counter='haproxy_server_connection_errors_total',
          selector='type="pages", job="haproxy"'
        ),
      ]),

      significantLabels: [],
    },
  },

  saturationTypes: [
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'single_node_cpu',
  ],
}
