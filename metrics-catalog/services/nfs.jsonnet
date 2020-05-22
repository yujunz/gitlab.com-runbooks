local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

{
  type: 'nfs',
  tier: 'stor',
  monitoringThresholds: {
    errorRatio: 0.0001,
  },
  eventBasedSLOTargets: {
    errorRatio: 0.9999,  // 99.99% of nfs requests should succeed, over multiple window periods
  },
  components: {
    nfs_service: {
      requestRate: rateMetric(
        counter='node_nfsd_server_rpcs_total',
        selector='type="nfs"'
      ),

      errorRate: rateMetric(
        counter='node_nfsd_rpc_errors_total',
        selector='type="nfs"'
      ),

      significantLabels: ['fqdn'],
    },
  },
}
