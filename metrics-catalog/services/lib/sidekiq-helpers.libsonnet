
// Sidekiq Shard Definitions
// This should contain a list of sidekiq shards
//
// NOTE: while we transition to k8s, this list needs to be kept
// in sync with two other sources:
// 1. SHARD_CONFIGURATIONS: https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/tools/sidekiq-config/sidekiq-queue-configurations.libsonnet
// 2. Helm Configuration:
//    a. https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/values.yaml.gotmpl
//    b. https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl
//
// To avoid even more complication, this list should remain the SSOT for the runbooks project if at all possible!
local shards = {
  'low-urgency-cpu-bound': {},
  'memory-bound': { throttled: true },
  'urgent-cpu-bound': {},
  'urgent-other': { autoScaling: false },
  catchall: {},
  elasticsearch: { throttled: true },
};


// These values are used in several places, so best to DRY them up
{
  slos: {
    urgent: {
      queueingDurationSeconds: 10,
      executionDurationSeconds: 10,
    },
    lowUrgency: {
      queueingDurationSeconds: 60,
      executionDurationSeconds: 300,
    },
    throttled: {
      // Throttled jobs don't have a queuing duration,
      // so don't add one here!
      executionDurationSeconds: 300,
    },
  },
  shards: {
    listAll():: std.objectFields(shards),

    // List shards which match on the supplied predicate
    listFiltered(filterPredicate): std.filter(function(f) filterPredicate({ autoScaling: true, throttled: false } + shards[f]), std.objectFields(shards)),
  },
}
