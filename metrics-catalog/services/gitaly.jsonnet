local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customApdex = metricsCatalog.customApdex;
local combined = metricsCatalog.combined;
local gitalyHelpers = import './lib/gitaly-helpers.libsonnet';

{
  type: 'gitaly',
  tier: 'stor',
  // Since each Gitaly node is a SPOF for a subset of repositories, we need to ensure that
  // we have node-level monitoring on these hosts
  nodeLevelMonitoring: true,
  deprecatedSingleBurnThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.001,
    alertTriggerDuration: 'long',
  },
  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.9995,
  },
  serviceDependencies: {
    gitaly: true,
  },
  components: {
    goserver: {
      local baseSelector = { job: 'gitaly' },
      apdex: histogramApdex(
        histogram='grpc_server_handling_seconds_bucket',
        selector=baseSelector {
          grpc_type: 'unary',
          grpc_method: { nre: gitalyHelpers.gitalyApdexIgnoredMethodsRegexp },
        },
        satisfiedThreshold=0.5,
        toleratedThreshold=1
      ),

      requestRate: rateMetric(
        counter='gitaly_service_client_requests_total',
        selector=baseSelector
      ),

      errorRate: combined([
        rateMetric(
          counter='gitaly_service_client_requests_total',
          selector=baseSelector {
            grpc_code: { nre: '^(OK|NotFound|Unauthenticated|AlreadyExists|FailedPrecondition|DeadlineExceeded)$' },
          }
        ),
        rateMetric(
          counter='gitaly_service_client_requests_total',
          selector=baseSelector {
            grpc_code: 'DeadlineExceeded',
            deadline_type: { ne: 'limited' },
          }
        ),
      ]),

      significantLabels: ['fqdn'],
    },

    gitalyruby: {
      local baseSelector = { job: 'gitaly' },

      // Uses the goservers histogram, but only selects client unary calls: this is an effective proxy
      // go gitaly-ruby client call times
      apdex: customApdex(
        rateQueryTemplate=|||
          rate(grpc_server_handling_seconds_bucket{%(selector)s}[%(rangeInterval)s]) and on(grpc_service,grpc_method) grpc_client_handled_total{job="gitaly"}
        |||,
        selector=baseSelector { grpc_type: 'unary' },
        satisfiedThreshold=10,
        toleratedThreshold=30
      ),

      /*
      TODO: Uncomment these lines once Gitaly Ruby observability issues are solved.
      See https://gitlab.com/gitlab-org/gitaly/issues/2467
      requestRate: rateMetric(
        counter='grpc_client_handled_total',
        selector='job="gitaly"'
      ),

      errorRate: rateMetric(
        counter='grpc_client_handled_total',
        selector='job="gitaly", grpc_code!~"^(OK|NotFound|Unauthenticated|AlreadyExists|FailedPrecondition)$"'
      ),
      */

      significantLabels: ['fqdn'],
    },
  },

}
