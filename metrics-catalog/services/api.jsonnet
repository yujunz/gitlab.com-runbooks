local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

{
  type: 'api',
  tier: 'sv',
  monitoringThresholds: {
    apdexRatio: 0.9,
    errorRatio: 0.005,
  },
  eventBasedSLOTargets: {
    errorRatio: 0.999,  // 99.9% of API requests should succeed, over multiple window periods
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
    },

    puma: {
      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector='job="gitlab-rails", type="api"',
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='http_request_duration_seconds_count',
        selector='job="gitlab-rails", type="api"'
      ),

      errorRate: rateMetric(
        counter='http_request_duration_seconds_count',
        selector='job="gitlab-rails", type="api", status=~"5.."'
      ),

      significantLabels: ['fqdn'],
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
    'go_memory',
  ],
}
