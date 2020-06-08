{
  // The serviceNodeErrorRatio ruleset will generate recording rules for a particular burn rate
  // to roll up nodeLevelMonitoring to the service level, providing insights into nodes
  // at a service level.
  //
  // Note: Only gitaly currently uses nodeLevelMonitoring.
  serviceNodeErrorRatioRuleSet(suffix)::
    {
      generateRecordingRules()::
        local format = {
          suffix: suffix,
        };

        [{
          record: 'gitlab_service_node_errors:ratio%(suffix)s' % format,
          expr: |||
            sum by (environment, env, tier, type, stage, shard, fqdn) (gitlab_component_node_errors:rate%(suffix)s{monitor!="global"} >= 0)
            /
            sum by (environment, env, tier, type, stage, shard, fqdn) (gitlab_component_node_ops:rate%(suffix)s{monitor!="global"} > 0)
          ||| % format,
        }],
    },

}
