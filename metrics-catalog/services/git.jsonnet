local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customRateQuery = metricsCatalog.customRateQuery;

{
  type: 'git',
  tier: 'sv',
  monitoringThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  eventBasedSLOTargets: {
    errorRatio: 0.995,  // 99.5% of Git requests should succeed, over multiple window periods
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
      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        selector='job="gitlab-workhorse-git", type="git", route!="^/-/health$", route!="^/-/(readiness|liveness)$"',
        satisfiedThreshold=30,
        toleratedThreshold=60
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector='job="gitlab-workhorse-git", type="git"'
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector='job="gitlab-workhorse-git", type="git", code=~"^5.*", route!="^/-/health$", route!="^/-/(readiness|liveness)$"'
      ),

      significantLabels: ['fqdn', 'route'],
    },

    puma: {
      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector='job="gitlab-rails", type="git"',
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='http_request_duration_seconds_count',
        selector='job="gitlab-rails", type="git"'
      ),

      errorRate: rateMetric(
        counter='http_request_duration_seconds_count',
        selector='job="gitlab-rails", type="git", status=~"5.."'
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

  saturationTypes: [
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'single_node_cpu',
    'single_node_puma_workers',
    'single_node_unicorn_workers',
    'workers',
  ],
}
