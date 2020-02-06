local gitalyApdexIgnoredMethods = std.set([
  'CommitLanguages',
  'CreateFork',
  'CreateRepositoryFromURL',
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
]);

{
  // This is a list of unary GRPC methods that should not be included in measuring the apdex score
  // for Gitaly or Praefect services, since they're called from background jobs and the latency
  // does not reflect the overall latency of the Gitaly server
  gitalyApdexIgnoredMethodsRegexp:: std.join('|', gitalyApdexIgnoredMethods),
}
