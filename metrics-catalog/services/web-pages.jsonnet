local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'web-pages',
  tier: 'sv',
  contractualThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.05,
  },
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.9999,
  },
  components: {
    loadbalancer: haproxyComponents.haproxyHTTPLoadBalancer(
      stageMappings={
        main: { backends: ['pages_http'], toolingLinks: [] },
        // TODO: cny stage for pages?
      },
      selector={ type: 'pages' },
    ),

    loadbalancer_https: haproxyComponents.haproxyL4LoadBalancer(
      stageMappings={
        main: { backends: ['pages_https'], toolingLinks: [] },
        // TODO: cny stage for pages?
      },
      selector={ type: 'pages' },
    ),

    server: {
      // 1 second satisfactory, 10 second tolerable thresholds are
      // very poor for what is essentially a static site server
      // we should investigate the poor performance
      apdex: histogramApdex(
        histogram='gitlab_pages_http_request_duration_seconds_bucket',
        selector='type="web-pages"',
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_pages_http_requests_total',
        selector=''
      ),

      errorRate: rateMetric(
        counter='gitlab_pages_http_requests_total',
        selector='code=~"5.."'
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='gitlab-pages'),
        toolingLinks.sentry(slug='gitlab/gitlab-pages'),
        toolingLinks.kibana(title='GitLab Pages', index='pages'),
      ],
    },
  },
})
