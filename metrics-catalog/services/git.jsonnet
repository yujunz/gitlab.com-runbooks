local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customRateQuery = metricsCatalog.customRateQuery;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'git',
  tier: 'sv',
  contractualThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  monitoringThresholds: {
    apdexScore: 0.9995,
    errorRatio: 0.9995,
  },
  // Deployment thresholds are optional, and when they are specified, they are
  // measured against the same multi-burn-rates as the monitoring indicators.
  // When a service is in violation, deployments may be blocked or may be rolled
  // back.
  deploymentThresholds: {
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
    loadbalancer: haproxyComponents.haproxyHTTPLoadBalancer(
      stageMappings={
        main: { backends: ['https_git', 'websockets'], toolingLinks: [
          toolingLinks.bigquery(title='Top http clients by number of requests, main stage, 10m', savedQuery='805818759045:704c6bdf00a743d195d344306bf207ee'),
        ] },
        cny: { backends: ['canary_https_git'], toolingLinks: [
          toolingLinks.bigquery(title='Top http clients by number of requests, cny stage, 10m', savedQuery='805818759045:dea839bd669e41b5bc264c510294bb9f'),
        ] },  // What happens to cny websocket traffic?
      },
      selector={ type: 'frontend' },
    ),

    loadbalancer_ssh: haproxyComponents.haproxyL4LoadBalancer(
      stageMappings={
        main: {
          backends: ['ssh', 'altssh'],
          toolingLinks: [
            toolingLinks.bigquery(title='Top ssh clients by number of requests, 10m', savedQuery='805818759045:8a185b18fafe4081bf9fbdb5354844f9'),
          ],
        },
        // No canary SSH for now
      },
      selector={ type: 'frontend' },
    ),

    workhorse: {
      local baseSelector = {
        job: 'gitlab-workhorse-git',
        type: 'git',
        route: [{ ne: '^/-/health$' }, { ne: '^/-/(readiness|liveness)$' }, { ne: '^/api/' }],
      },

      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        selector=baseSelector {
          route+: [{
            ne: '^/([^/]+/){1,}[^/]+/-/jobs/[0-9]+/terminal.ws\\\\z',
          }, {
            ne: '^/([^/]+/){1,}[^/]+/-/environments/[0-9]+/terminal.ws\\\\z',
          }, {
            ne: '^/-/cable\\\\z',  // Exclude Websocket connections from apdex score
          }],
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
        selector=baseSelector {
          code: { re: '^5.*' },
        }
      ),

      significantLabels: ['fqdn', 'route'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-git'),
        toolingLinks.sentry(slug='gitlab/gitlab-workhorse-gitlabcom'),
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='git', slowRequestSeconds=10),
      ],
    },

    /**
     * The API route on Workhorse is used exclusively for auth requests from
     * GitLab shell. As such, it has much more performant latency requirements
     * that other Git/Workhorse traffic
     */
    workhorse_auth_api: {
      local baseSelector = {
        job: 'gitlab-workhorse-git',
        type: 'git',
        route: '^/api/',
      },

      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        selector=baseSelector,
        // Note: 10s is far too slow for an auth request. This threshold should be much lower
        // TODO: reduce this threshold to 1s
        satisfiedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=baseSelector {
          code: { re: '^5.*' },
        }
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-git'),
        toolingLinks.sentry(slug='gitlab/gitlab-workhorse-gitlabcom'),
        // TODO: filter kibana query on route once https://gitlab.com/gitlab-org/gitlab-workhorse/-/merge_requests/624 arrives
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='git', slowRequestSeconds=10),
      ],
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
        counter='http_requests_total',
        selector=baseSelector,
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=baseSelector { status: { re: '5..' } }
      ),

      significantLabels: ['fqdn', 'method', 'feature_category'],

      toolingLinks: [
        // Improve sentry link once https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/532 arrives
        toolingLinks.sentry(slug='gitlab/gitlabcom'),
        toolingLinks.kibana(title='Rails', index='rails', type='git', slowRequestSeconds=10),
      ],
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

      toolingLinks: [
        toolingLinks.kibana(title='GitLab Shell', index='shell'),
      ],
    },
  },
})
