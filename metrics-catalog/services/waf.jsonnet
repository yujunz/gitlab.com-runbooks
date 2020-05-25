local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

{
  type: 'waf',
  tier: 'lb',
  monitoringThresholds: {
    errorRatio: 0.001,
  },
  eventBasedSLOTargets: {
    errorRatio: 0.999,
  },
  serviceDependencies: {
    frontend: true,
  },
  components: {
    gitlab_zone: {
      requestRate: rateMetric(
        counter='cloudflare_zones_http_responses_total',
        selector='zone=~"gitlab.com|staging.gitlab.com"'
      ),

      errorRate: rateMetric(
        counter='cloudflare_zones_http_responses_total',
        selector='zone=~"gitlab.com|staging.gitlab.com", edge_response_status=~"5.."',
      ),

      significantLabels: [],
    },
    // The "gitlab.net" zone
    gitlab_net_zone: {
      requestRate: rateMetric(
        counter='cloudflare_zones_http_responses_total',
        selector='zone="gitlab.net"'
      ),

      errorRate: rateMetric(
        counter='cloudflare_zones_http_responses_total',
        selector='zone="gitlab.net", edge_response_status=~"5.."',
      ),

      significantLabels: [],
    },
  },
}
