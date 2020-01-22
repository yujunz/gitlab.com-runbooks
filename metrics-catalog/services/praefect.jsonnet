local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

{
  type: 'praefect',
  tier: 'stor',
  slos: {
    apdexRatio: 0.995,
    errorRatio: 0.001,
  },
  components: {
    proxy: {
      apdex: histogramApdex(
        histogram='grpc_server_handling_seconds_bucket',
        selector='job="praefect", grpc_type="unary", grpc_method!~"GarbageCollect|Fsck|RepackFull|RepackIncremental|CommitLanguages|CreateRepositoryFromURL|UserRebase|UserSquash|CreateFork|UserUpdateBranch|FindRemoteRepository|UserCherryPick|FetchRemote|UserRevert|FindRemoteRootRef"',
        satisfiedThreshold=0.5,
        toleratedThreshold=1
      ),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector='job="praefect"'
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector='job="praefect", grpc_code!~"^(OK|NotFound|Unauthenticated|AlreadyExists|FailedPrecondition)$"'
      ),

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
