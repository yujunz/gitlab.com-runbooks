local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'web',
  tier: 'sv',
  contractualThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.9999,
  },
  // Deployment thresholds are optional, and when they are specified, they are
  // measured against the same multi-burn-rates as the monitoring indicators.
  // When a service is in violation, deployments may be blocked or may be rolled
  // back.
  deploymentThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.9999,
  },
  serviceDependencies: {
    gitaly: true,
    'redis-sidekiq': true,
    'redis-cache': true,
    redis: true,
    patroni: true,
    pgbouncer: true,
    praefect: true,
  },
  components: {
    loadbalancer: haproxyComponents.haproxyHTTPLoadBalancer(
      stageMappings={
        main: { backends: ['web'], toolingLinks: [] },  // What to do with `429_slow_down`?
        cny: { backends: ['canary_web'], toolingLinks: [] },
      },
      selector={ type: 'frontend' },
    ),

    workhorse: {
      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        // Note, using `|||` avoids having to double-escape the backslashes in the selector query
        selector=|||
          job="gitlab-workhorse-web", route!="^/([^/]+/){1,}[^/]+/uploads\\z", route!="^/-/health$", route!="^/-/(readiness|liveness)$"
        |||,
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector='job="gitlab-workhorse-web", type="web"'
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector='job="gitlab-workhorse-web", type="web", code=~"^5.*", route!="^/-/health$", route!="^/-/(readiness|liveness)$"'
      ),

      significantLabels: ['fqdn', 'route'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-web'),
        toolingLinks.sentry(slug='gitlab/gitlab-workhorse-gitlabcom'),
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='web', slowRequestSeconds=10),
      ],
    },

    puma: {
      local baseSelector = { job: 'gitlab-rails', type: 'web' },
      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=baseSelector,
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=baseSelector,
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=baseSelector { status: { re: '5..' } }
      ),

      significantLabels: ['fqdn', 'method'],

      toolingLinks: [
        // Improve sentry link once https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/532 arrives
        toolingLinks.sentry(slug='gitlab/gitlabcom'),
        toolingLinks.kibana(title='Rails', index='rails', type='web', slowRequestSeconds=10),
      ],
    },
  },
})
