local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'registry',
  tier: 'sv',
  contractualThresholds: {
    apdexRatio: 0.9,
    errorRatio: 0.005,
  },
  // Deployment thresholds are optional, and when they are specified, they are
  // measured against the same multi-burn-rates as the monitoring indicators.
  // When a service is in violation, deployments may be blocked or may be rolled
  // back.
  deploymentThresholds: {
    apdexScore: 0.9929,
    errorRatio: 0.9700,
  },
  monitoringThresholds: {
    apdexScore: 0.997,
    errorRatio: 0.9999,
  },
  serviceDependencies: {
    api: true,
  },
  provisioning: {
    kubernetes: true,
    vms: true,  // registry haproxy frontend still runs on vms
  },
  components: {
    loadbalancer: haproxyComponents.haproxyHTTPLoadBalancer(
      stageMappings={
        main: { backends: ['registry'], toolingLinks: [] },
        cny: { backends: ['canary_registry'], toolingLinks: [] },
      },
      selector={ type: 'registry' },
    ),

    server: {
      apdex: histogramApdex(
        histogram='registry_http_request_duration_seconds_bucket',
        selector='type="registry"',
        satisfiedThreshold=1,
        toleratedThreshold=2.5
      ),

      requestRate: rateMetric(
        counter='registry_http_requests_total',
        selector='type="registry"'
      ),

      errorRate: rateMetric(
        counter='registry_http_requests_total',
        selector='type="registry", code=~"5.."'
      ),

      significantLabels: ['handler'],

      toolingLinks: [
        toolingLinks.gkeDeployment('gitlab-registry', type='registry', containerName='registry'),
        // Add slowRequestSeconds=10 once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/11136 is fixed
        toolingLinks.kibana(title='Registry', index='registry', type='registry'),
      ],
    },

    storage: {
      apdex: histogramApdex(
        histogram='registry_storage_action_seconds_bucket',
        selector='',
        satisfiedThreshold=1,
        toleratedThreshold=2.5
      ),

      requestRate: rateMetric(
        counter='registry_storage_action_seconds_count',
      ),

      significantLabels: ['action'],
    },
  },
})
