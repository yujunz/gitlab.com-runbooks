local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customRateQuery = metricsCatalog.customRateQuery;

metricsCatalog.serviceDefinition({
  type: 'git',
  tier: 'sv',
  deprecatedSingleBurnThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  monitoringThresholds: {
    apdexScore: 0.9995,
    errorRatio: 0.9995,
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
    workhorse: {
      local baseSelector = {
        job: "gitlab-workhorse-git",
        type: "git",
        route: [ { ne: "^/-/health$" }, { ne: "^/-/(readiness|liveness)$" } ]
      },
      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        selector=baseSelector {
          route+: [{
            ne: "^/([^/]+/){1,}[^/]+/-/jobs/[0-9]+/terminal.ws\\\\z"
          }, {
            ne: "^/([^/]+/){1,}[^/]+/-/environments/[0-9]+/terminal.ws\\\\z"
          }]
        },
        satisfiedThreshold=30,
        toleratedThreshold=60
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=baseSelector + {
          code: { re: "^5.*" }
        }
      ),

      significantLabels: ['fqdn', 'route'],
    },

    puma: {
      local baseSelector = { job: 'gitlab-rails', type: 'git' },
      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=baseSelector,
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='http_request_duration_seconds_count',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='http_request_duration_seconds_count',
        selector=baseSelector { status: { re: '5..' } }
      ),

      significantLabels: ['fqdn', 'method'],
    },

    gitlab_shell: {
      staticLabels: {
        tier: 'sv',
        stage: 'main',
      },

      // Unfortunately we don't have a better way of measuring this at present,
      // so we rely on HAProxy metrics
      requestRate: customRateQuery(|||
        sum by (environment) (haproxy_backend_current_session_rate{backend=~"ssh|altssh"})
      |||),

      significantLabels: [],
    },
  },
})
