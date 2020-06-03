local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

local formatConfig = {
  productionEnvironmentsSelector: 'environment=~"gprd|ops|ci-prd"',
};

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
      staticLabels: {
        environment: 'ops',
      },

      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector='job="thanos", type="monitoring", %(productionEnvironmentsSelector)s' % formatConfig,
        satisfiedThreshold=1,
        toleratedThreshold=6
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector='job="thanos", type="monitoring", %(productionEnvironmentsSelector)s' % formatConfig
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector='job="thanos", type="monitoring", code=~"^5.*", %(productionEnvironmentsSelector)s' % formatConfig
      ),

      significantLabels: ['fqdn'],
    },

    thanos_store: {
      staticLabels: {
        environment: 'ops',
      },

      apdex: histogramApdex(
        histogram='grpc_server_handling_seconds_bucket',
        selector='job="thanos", type="monitoring", grpc_service="thanos.Store", grpc_type="unary", %(productionEnvironmentsSelector)s' % formatConfig,
        satisfiedThreshold=1,
        toleratedThreshold=3
      ),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector='job="thanos", type="monitoring", grpc_service="thanos.Store", %(productionEnvironmentsSelector)s' % formatConfig
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector='job="thanos", type="monitoring", grpc_service="thanos.Store", grpc_code!="OK", %(productionEnvironmentsSelector)s' % formatConfig
      ),

      significantLabels: ['fqdn'],
    },

    thanos_compactor: {
      staticLabels: {
        environment: 'ops',
      },

      requestRate: rateMetric(
        counter='thanos_compact_group_compactions_total',
        selector='job="thanos", type="monitoring", %(productionEnvironmentsSelector)s' % formatConfig
      ),

      errorRate: rateMetric(
        counter='thanos_compact_group_compactions_failures_total',
        selector='job="thanos", type="monitoring", %(productionEnvironmentsSelector)s' % formatConfig
      ),

      significantLabels: ['fqdn'],
    },

    grafana: {
      staticLabels: {
        environment: 'ops',
      },

      requestRate: rateMetric(
        counter='http_request_total',
        selector='job="grafana", %(productionEnvironmentsSelector)s' % formatConfig
      ),

      errorRate: rateMetric(
        counter='http_request_total',
        selector='job="grafana", statuscode=~"^5.*", %(productionEnvironmentsSelector)s' % formatConfig
      ),

      significantLabels: ['fqdn'],
    },

    prometheus: {
      staticLabels: {
        environment: 'ops',
      },

      apdex: histogramApdex(
        histogram='prometheus_http_request_duration_seconds_bucket',
        selector='job="prometheus", type="monitoring", %(productionEnvironmentsSelector)s' % formatConfig,
        satisfiedThreshold=0.4,
        toleratedThreshold=0.1
      ),

      requestRate: rateMetric(
        counter='prometheus_http_requests_total',
        selector='job="prometheus", type="monitoring", %(productionEnvironmentsSelector)s' % formatConfig
      ),

      errorRate: rateMetric(
        counter='prometheus_http_requests_total',
        selector='job="prometheus", type="monitoring", code=~"^5.*", %(productionEnvironmentsSelector)s' % formatConfig
      ),

      significantLabels: ['fqdn'],
    },
  },
}
