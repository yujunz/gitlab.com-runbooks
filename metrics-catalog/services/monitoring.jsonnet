local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

local productionEnvironmentsSelector = {
  environment: { re: 'gprd|ops|ci-prd' },
};

{
  type: 'monitoring',
  tier: 'inf',
  deprecatedSingleBurnThresholds: {
    apdexRatio: 0.999,
    errorRatio: 0.001,
  },
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
  },
  /*
   * Our anomaly detection uses normal distributions and the monitoring service
   * is prone to spikes that lead to a non-normal distribution. For that reason,
   * disable ops-rate anomaly detection on this service.
   */
  disableOpsRatePrediction: true,
  components: {
    thanos_query: {
      local thanosQuerySelector = productionEnvironmentsSelector {
        job: 'thanos',
        type: 'monitoring',
      },
      staticLabels: {
        environment: 'ops',
      },

      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=thanosQuerySelector,
        satisfiedThreshold=1,
        toleratedThreshold=6
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector { code: { re: '^5.*' } }
      ),

      significantLabels: ['fqdn'],
    },

    thanos_store: {
      local thanosStoreSelector = productionEnvironmentsSelector {
        job: 'thanos',
        type: 'monitoring',
        grpc_service: 'thanos.Store',
        grpc_type: 'unary',
      },

      staticLabels: {
        environment: 'ops',
      },

      apdex: histogramApdex(
        histogram='grpc_server_handling_seconds_bucket',
        selector=thanosStoreSelector,
        satisfiedThreshold=1,
        toleratedThreshold=3
      ),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=thanosStoreSelector
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=thanosStoreSelector { grpc_code: { ne: 'OK' } }
      ),

      significantLabels: ['fqdn'],
    },

    thanos_compactor: {
      local thanosCompactorSelector = productionEnvironmentsSelector {
        job: 'thanos',
        type: 'monitoring',
      },

      staticLabels: {
        environment: 'ops',
      },

      requestRate: rateMetric(
        counter='thanos_compact_group_compactions_total',
        selector=thanosCompactorSelector
      ),

      errorRate: rateMetric(
        counter='thanos_compact_group_compactions_failures_total',
        selector=thanosCompactorSelector
      ),

      significantLabels: ['fqdn'],
    },

    grafana: {
      local grafanaSelector = productionEnvironmentsSelector {
        job: 'grafana',
      },

      staticLabels: {
        environment: 'ops',
      },

      requestRate: rateMetric(
        counter='http_request_total',
        selector=grafanaSelector
      ),

      errorRate: rateMetric(
        counter='http_request_total',
        selector=grafanaSelector { statuscode: { re: '^5.*' } }
      ),

      significantLabels: ['fqdn'],
    },

    prometheus: {
      local prometheusSelector = productionEnvironmentsSelector {
        job: 'prometheus',
        type: 'monitoring',
      },

      staticLabels: {
        environment: 'ops',
      },

      apdex: histogramApdex(
        histogram='prometheus_http_request_duration_seconds_bucket',
        selector=prometheusSelector,
        satisfiedThreshold=1,
        toleratedThreshold=3
      ),

      requestRate: rateMetric(
        counter='prometheus_http_requests_total',
        selector=prometheusSelector
      ),

      errorRate: rateMetric(
        counter='prometheus_http_requests_total',
        selector=prometheusSelector { code: { re: '^5.*' } }
      ),

      significantLabels: ['fqdn', 'handler'],
    },
  },
}
