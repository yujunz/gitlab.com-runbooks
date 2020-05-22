local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

{
  type: 'monitoring',
  tier: 'inf',
  monitoringThresholds: {
    /*
    TODO: enable SLOs for monitoring service
    apdexRatio: 0.95,
    errorRatio: 0.005,
    */
  },
  /*
   * Our anomaly detection uses normal distributions and the monitoring service
   * is prone to spikes that lead to a non-normal distribution. For that reason,
   * disable ops-rate anomaly detection on this service.
   */
  disableOpsRatePrediction: true,
  components: {
    thanos_query: {
      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector='job="thanos", type="monitoring"',
        satisfiedThreshold=1,
        toleratedThreshold=5
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector='job="thanos", type="monitoring"'
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector='job="thanos", type="monitoring", code=~"^5.*"'
      ),

      significantLabels: ['fqdn'],
    },

    thanos_store: {
      apdex: histogramApdex(
        histogram='grpc_server_handling_seconds_bucket',
        selector='job="thanos", type="monitoring", grpc_service="thanos.Store"',
        satisfiedThreshold=0.4,
        toleratedThreshold=0.8
      ),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector='job="thanos", type="monitoring", grpc_service="thanos.Store"'
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector='job="thanos", type="monitoring", grpc_service="thanos.Store", grpc_code!="OK"'
      ),

      significantLabels: ['fqdn'],
    },

    grafana: {
      requestRate: rateMetric(
        counter='http_request_total',
        selector='job="grafana"'
      ),

      errorRate: rateMetric(
        counter='http_request_total',
        selector='job="grafana", statuscode=~"^5.*"'
      ),

      significantLabels: ['fqdn'],
    },

    prometheus: {
      apdex: histogramApdex(
        histogram='prometheus_http_request_duration_seconds_bucket',
        selector='job="prometheus", type="monitoring"',
        satisfiedThreshold=0.2,
        toleratedThreshold=0.4
      ),

      requestRate: rateMetric(
        counter='prometheus_http_requests_total',
        selector='job="prometheus", type="monitoring"'
      ),

      errorRate: rateMetric(
        counter='prometheus_http_requests_total',
        selector='job="prometheus", type="monitoring", code=~"^5.*"'
      ),

      significantLabels: ['fqdn'],
    },
  },
}
