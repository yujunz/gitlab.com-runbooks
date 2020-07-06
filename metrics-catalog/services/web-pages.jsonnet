local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;

metricsCatalog.serviceDefinition({
  type: 'web-pages',
  tier: 'sv',
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.9999,
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

    server: {
      // 1 second satisfactory, 10 second tolerable thresholds are
      // very poor for what is essentially a static site server
      // we should investigate the poor performance
      apdex: histogramApdex(
        histogram='gitlab_pages_http_request_duration_seconds_bucket',
        selector='type="web-pages"',
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_pages_http_requests_total',
        selector=''
      ),

      errorRate: rateMetric(
        counter='gitlab_pages_http_requests_total',
        selector='code=~"5.."'
      ),

      significantLabels: ['fqdn'],
    },
  },
})
