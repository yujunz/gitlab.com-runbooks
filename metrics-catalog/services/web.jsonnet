local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customQuery = metricsCatalog.customQuery;

{
  type: 'web',
  tier: 'sv',
  slos: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  components: {
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
        selector='job="gitlab-workhorse-web", type="web", code=~"^5.*", route!="^/-/health$", route!="^/-/(readiness|liveness)$'
      ),

      significantLabels: ['fqdn', 'route'],
    },

    unicorn: {
      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector='job="gitlab-rails", type="web"',
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='http_request_duration_seconds_count',
        selector='job="gitlab-rails", type="web"'
      ),

      errorRate: rateMetric(
        counter='http_request_duration_seconds_count',
        selector='job="gitlab-rails", type="web", status=~"5.."'
      ),

      significantLabels: ['fqdn', 'method'],
    },
  },

  saturationTypes: [
    'cpu',
    'disk_space',
    'memory',
    'open_fds',
    'single_node_cpu',
    'single_node_unicorn_workers',
    'workers',
    'go_memory',
  ],
}
