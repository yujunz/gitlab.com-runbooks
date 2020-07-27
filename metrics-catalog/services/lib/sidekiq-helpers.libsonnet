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
  'database-throttled': { urgency: 'throttled' },
  'gitaly-throttled': { urgency: 'throttled' },
  'low-urgency-cpu-bound': { urgency: 'low' },
  'memory-bound': { urgency: 'throttled' },
  'urgent-cpu-bound': { urgency: 'high' },
  'urgent-other': { urgency: 'high', autoScaling: false },
  catchall: { urgency: null /* no urgency attribute since multiple values are supported */ },
  elasticsearch: { urgency: 'throttled' },
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
    listByName():: std.objectFields(shards),

    listAll():: std.map(function(name) shards[name] { name: name }, std.objectFields(shards)),

    // List shards which match on the supplied predicate
    listFiltered(filterPredicate): std.filter(function(f) filterPredicate({ autoScaling: true } + shards[f]), std.objectFields(shards)),
  },
}
