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
    // The "gitlab.net" zone
    zone_gitlab_net: {
      staticLabels: {
        // TODO: currently the cloudflare exporter is missing the required
        // type and tier labels
        type: 'waf',
        tier: 'lb',
        stage: 'main',
        environment: 'gprd',
      },

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

    // The "staging.gitlab.com" zone
    zone_staging_gitlab_com: {
      staticLabels: {
        // TODO: currently the cloudflare exporter is missing the required
        // type and tier labels
        type: 'waf',
        tier: 'lb',
        stage: 'main',
        environment: 'gstg',
      },

      requestRate: rateMetric(
        counter='cloudflare_zones_http_responses_total',
        selector='zone="staging.gitlab.com"'
      ),

      errorRate: rateMetric(
        counter='cloudflare_zones_http_responses_total',
        selector='zone="staging.gitlab.com", edge_response_status=~"5.."',
      ),

      significantLabels: [],
    },
  },

  saturationTypes: [],
}
