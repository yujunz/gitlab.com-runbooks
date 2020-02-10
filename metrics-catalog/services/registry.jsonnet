local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

{
  type: 'registry',
  tier: 'sv',
  slos: {
    apdexRatio: 0.9,
    errorRatio: 0.005,
  },
  components: {
    loadbalancer: {
      staticLabels: {
        stage: 'main',
      },

      requestRate: rateMetric(
        counter='haproxy_backend_http_responses_total',
        selector='backend="registry",job="haproxy"'
      ),

      errorRate: rateMetric(
        counter='haproxy_backend_http_responses_total',
        selector='backend="registry",job="haproxy",code="5xx"'
      ),

      significantLabels: [],
    },

    loadbalancer_cny: {
      staticLabels: {
        stage: 'cny',
      },

      requestRate: rateMetric(
        counter='haproxy_backend_http_responses_total',
        selector='backend="canary_registry",job="haproxy"'
      ),

      errorRate: rateMetric(
        counter='haproxy_backend_http_responses_total',
        selector='backend="canary_registry",job="haproxy",code="5xx"'
      ),

      significantLabels: [],
    },

    server: {
      apdex: histogramApdex(
        histogram='registry_http_request_duration_seconds_bucket',
        selector='type="registry"',
        satisfiedThreshold=1,
        toleratedThreshold=2.5
      ),

      requestRate: rateMetric(
        counter='registry_http_requests_total',
        selector='type="registry"'
      ),

      errorRate: rateMetric(
        counter='registry_http_requests_total',
        selector='type="registry", code=~"5.."'
      ),

      significantLabels: ['handler'],
    },

    storage: {
      apdex: histogramApdex(
        histogram='registry_storage_action_seconds_bucket',
        selector='',
        satisfiedThreshold=5,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='registry_storage_action_seconds_count',
      ),

      significantLabels: ['action'],
    },
  },

  saturationTypes: [
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'single_node_cpu',
    'go_memory',
  ],
}
