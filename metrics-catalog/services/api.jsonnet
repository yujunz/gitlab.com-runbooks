local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'api',
  tier: 'sv',
  contractualThresholds: {
    apdexRatio: 0.9,
    errorRatio: 0.005,
  },
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.999,
  },
  // Deployment thresholds are optional, and when they are specified, they are
  // measured against the same multi-burn-rates as the monitoring indicators.
  // When a service is in violation, deployments may be blocked or may be rolled
  // back.
  deploymentThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.999,
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
        main: {
          backends: ['api', 'api_rate_limit'],
          toolingLinks: [
            toolingLinks.bigquery(title='Main-stage: top paths for 5xx errors', savedQuery='805818759045:342973e81d4a481d8055b43564d09728'),
          ],
        },
        cny: { backends: ['canary_api'], toolingLinks: [] },
      },
      selector={ type: 'frontend' },
    ),

    workhorse: {
      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        // Note, using `|||` avoids having to double-escape the backslashes in the selector query
        selector=|||
          job="gitlab-workhorse-api", type="api", route!="^/api/v4/jobs/request\\z", route!="^/-/health$", route!="^/-/(readiness|liveness)$"
        |||,
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector='job="gitlab-workhorse-api", type="api"'
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector='job="gitlab-workhorse-api", type="api", code=~"^5.*", route!="^/-/health$", route!="^/-/(readiness|liveness)$"'
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-api'),
        toolingLinks.sentry(slug='gitlab/gitlab-workhorse-gitlabcom'),
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='api', slowRequestSeconds=10),
      ],
    },

    puma: {
      local baseSelector = { job: 'gitlab-rails', type: 'api' },
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

      significantLabels: ['fqdn'],

      toolingLinks: [
        // Improve sentry link once https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/532 arrives
        toolingLinks.sentry(slug='gitlab/gitlabcom'),
        toolingLinks.kibana(title='Rails', index='rails_api', type='api', slowRequestSeconds=10),
      ],
    },
  },
})
