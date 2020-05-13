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
  'UserCherryPick',
  'UserFFBranch',
  'UserRebase',
  'UserRevert',
  'UserSquash',
  'UserUpdateBranch',

  // Excluding Hook RPCs, as these are dependent on the internal Rails API.
  // Almost all time is spend there, once it's slow of failing it's usually not
  // a Gitaly alert that should fire.
  'PreReceiveHook',
  'PostReceiveHook',
  'UpdateHook',
]);

{
  // This is a list of unary GRPC methods that should not be included in measuring the apdex score
  // for Gitaly or Praefect services, since they're called from background jobs and the latency
  // does not reflect the overall latency of the Gitaly server
  gitalyApdexIgnoredMethodsRegexp:: std.join('|', gitalyApdexIgnoredMethods),
}
