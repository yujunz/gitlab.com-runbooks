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
  monitoringThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.001,
    alertTriggerDuration: 'long',
  },
  components: {
    goserver: {
      apdex: histogramApdex(
        histogram='grpc_server_handling_seconds_bucket',
        selector='job="gitaly", grpc_type="unary", grpc_method!~"%(gitalyApdexIgnoredMethodsRegexp)s"' % { gitalyApdexIgnoredMethodsRegexp: gitalyHelpers.gitalyApdexIgnoredMethodsRegexp },
        satisfiedThreshold=0.5,
        toleratedThreshold=1
      ),

      requestRate: rateMetric(
        counter='gitaly_service_client_requests_total',
        selector='job="gitaly"'
      ),

      errorRate: combined([
        rateMetric(
          counter='gitaly_service_client_requests_total',
          selector='job="gitaly", grpc_code!~"^(OK|NotFound|Unauthenticated|AlreadyExists|FailedPrecondition|DeadlineExceeded)$"'
        ),
        rateMetric(
          counter='gitaly_service_client_requests_total',
          selector='job="gitaly", grpc_code="DeadlineExceeded", deadline_type!="limited"'
        ),
      ]),

      significantLabels: ['fqdn'],
    },

    gitalyruby: {
      // Uses the goservers histogram, but only selects client unary calls: this is an effective proxy
      // go gitaly-ruby client call times
      apdex: customApdex(
        rateQueryTemplate=|||
          rate(grpc_server_handling_seconds_bucket{%(selector)s}[%(rangeInterval)s]) and on(grpc_service,grpc_method) grpc_client_handled_total{job="gitaly"}
        |||,
        selector='job="gitaly",grpc_type="unary"',
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

  saturationTypes: [
    'cgroup_memory',
    'cpu',
    'disk_space',
    'disk_sustained_read_iops',
    'disk_sustained_read_throughput',
    'disk_sustained_write_iops',
    'disk_sustained_write_throughput',
    'memory',
    'open_fds',
    'single_node_cpu',
    'go_memory',
  ],
}
