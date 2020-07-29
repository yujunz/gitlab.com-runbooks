local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'camoproxy',
  tier: 'sv',
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
  },
  serviceDependencies: {
    // If Camoproxy has any dependencies, we should add them here
  },
  components: {
    server: {
      apdex: histogramApdex(
        histogram='camo_response_duration_seconds_bucket',
        satisfiedThreshold=5,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='camo_response_duration_seconds_bucket',
        selector={ le: '+Inf' },
      ),

      errorRate: rateMetric(
        counter='camo_proxy_reponses_failed_total',
      ),

      significantLabels: ['fqdn'],
    },
  },
})
