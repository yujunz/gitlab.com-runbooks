local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customApdex = metricsCatalog.customApdex;

{
  type: 'gitaly',
  tier: 'stor',
  autogenerateRecordingRules: false,  // TODO: enable autogeneration of recording rules for this service
  slos: {
    apdexRatio: 0.95,
    errorRatio: 0.001,
    alertTriggerDuration: 'long',
  },
  components: {
    goserver: {
      apdex: histogramApdex(
        histogram='grpc_server_handling_seconds_bucket',
        selector='job="gitaly", grpc_type="unary", grpc_method!~"GarbageCollect|Fsck|RepackFull|RepackIncremental|CommitLanguages|CreateRepositoryFromURL|UserFFBranch|UserRebase|UserSquash|CreateFork|UserUpdateBranch|FindRemoteRepository|UserCherryPick|FetchRemote|UserRevert|FindRemoteRootRef"',
        satisfiedThreshold=0.5,
        toleratedThreshold=1
      ),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector='job="gitaly"'
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector='job="gitaly", grpc_code!~"^(OK|NotFound|Unauthenticated|AlreadyExists|FailedPrecondition)$"'
      ),
    },

    gitalyruby: {
      // Uses the goservers histogram, but only selects client unary calls: this is an effective proxy
      // go gitaly-ruby client call times
      apdex: customApdex(
        rateQueryTemplate=|||
          rate(grpc_server_handling_seconds_bucket{job="gitaly",grpc_type="unary", %(selector)s}[%(rangeInterval)s]) and on(grpc_service,grpc_method) grpc_client_handled_total{job="gitaly"}
        |||,
        satisfiedThreshold=10,
        toleratedThreshold=30
      ),

      requestRate: rateMetric(
        counter='grpc_client_handled_total',
        selector='job="gitaly"'
      ),

      errorRate: rateMetric(
        counter='grpc_client_handled_total',
        selector='job="gitaly", grpc_code!~"^(OK|NotFound|Unauthenticated|AlreadyExists|FailedPrecondition)$"'
      ),
    },
  },
}
