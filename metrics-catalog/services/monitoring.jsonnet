local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customQuery = metricsCatalog.customQuery;

{
  type: 'monitoring',
  tier: 'inf',
  autogenerateRecordingRules: false,  // TODO: enable autogeneration of recording rules for this service
  slos: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
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
    },

  },
}
