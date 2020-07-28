local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local combined = metricsCatalog.combined;
local gitalyHelpers = import './lib/gitaly-helpers.libsonnet';

local gitalyApdexIgnoredMethods = std.set([
  'CalculateChecksum',
  'CommitLanguages',
  'CreateFork',
  'CreateRepositoryFromURL',
  'FetchInternalRemote',
  'FetchRemote',
  'FindRemoteRepository',
  'FindRemoteRootRef',
  'Fsck',
  'GarbageCollect',
  'RepackFull',
  'RepackIncremental',
  'ReplicateRepository',
  'FetchIntoObjectPool',
  'FetchSourceBranch',

  // Excluding Hook RPCs, as these are dependent on the internal Rails API.
  // Almost all time is spend there, once it's slow of failing it's usually not
  // a Gitaly alert that should fire.
  'PreReceiveHook',
  'PostReceiveHook',
  'UpdateHook',
]);

local gitalyApdexIgnoredMethodsRegexp = std.join('|', gitalyApdexIgnoredMethods);

{
  // This is a list of unary GRPC methods that should not be included in measuring the apdex score
  // for Gitaly or Praefect services, since they're called from background jobs and the latency
  // does not reflect the overall latency of the Gitaly server
  gitalyApdexIgnoredMethodsRegexp:: gitalyApdexIgnoredMethodsRegexp,

  // This calculates the apdex score for a Gitaly-like (Gitaly/Praefect)
  // GRPC service. It combines two values, unary values excluding the OperationService
  // on one threshold with OperationService requests on a slower threshold
  grpcServiceApdex(baseSelector)::
    combined([
    // Services excluding the Operation Service
    histogramApdex(
      histogram='grpc_server_handling_seconds_bucket',
      selector=baseSelector {
        grpc_type: 'unary',
        grpc_service: { ne: 'gitaly.OperationService' },
        grpc_method: { nre: gitalyApdexIgnoredMethodsRegexp },
      },
      satisfiedThreshold=0.5,
      toleratedThreshold=1
    ),
    // OperationService is relatively very slow compared to other
    // Gitaly services
    histogramApdex(
      histogram='grpc_server_handling_seconds_bucket',
      selector=baseSelector {
        grpc_type: 'unary',
        grpc_service: 'gitaly.OperationService'
      },
      satisfiedThreshold=10,
      toleratedThreshold=30
    )
  ])
}
