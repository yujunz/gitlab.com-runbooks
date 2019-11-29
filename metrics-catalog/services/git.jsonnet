local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customQuery = metricsCatalog.customQuery;

{
  type: 'git',
  tier: 'sv',
  autogenerateRecordingRules: false,  // TODO: enable autogeneration of recording rules for this service
  slos: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
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
        selector='job="gitlab-workhorse-git", type="git", code=~"^5.*"'
      ),
    },

    unicorn: {
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
    },

    gitlab_shell: {
      staticLabels: {
        tier: 'sv',
        stage: 'main',
      },

      requestRate: customQuery(|||
        sum by (environment) (haproxy_backend_current_session_rate{backend=~"ssh|altssh"})
      |||),
    },
  },
}