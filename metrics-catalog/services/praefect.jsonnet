local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local histogramApdex = metricsCatalog.histogramApdex;
local gitalyHelpers = import './lib/gitaly-helpers.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'praefect',
  tier: 'stor',
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.9995,  // 99.95% of Praefect requests should succeed, over multiple window periods
  },
  serviceDependencies: {
    gitaly: true,
  },
  components: {
    proxy: {
      local baseSelector = { job: 'praefect' },
      apdex: gitalyHelpers.grpcServiceApdex(baseSelector),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=baseSelector {
          grpc_code: { nre: '^(OK|NotFound|Unauthenticated|AlreadyExists|FailedPrecondition)$' },
        }
      ),

      significantLabels: ['fqdn'],
    },

    replicator: {
      local baseSelector = { job: 'praefect' },
      apdex: histogramApdex(
        histogram='gitaly_praefect_replication_latency_bucket',
        selector=baseSelector,
        satisfiedThreshold=0.5,
        toleratedThreshold=1
      ),

      requestRate: rateMetric(
        counter='gitaly_praefect_replication_latency_count',
        selector=baseSelector
      ),

      significantLabels: ['fqdn', 'type'],
    },
  },
})
