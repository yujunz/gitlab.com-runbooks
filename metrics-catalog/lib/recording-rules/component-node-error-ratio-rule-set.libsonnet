{
  // The componentNodeErrorRatio ruleset will generate recording rules for a particular burn rate
  // to roll up nodeLevelMonitoring to the component level, providing insights into nodes
  // at a component level.
  //
  // Note: Only gitaly currently uses nodeLevelMonitoring.
  componentNodeErrorRatioRuleSet(suffix)::
    {
      generateRecordingRules()::
        local format = {
          suffix: suffix,
        };

        [{
          record: 'gitlab_component_node_errors:ratio%(suffix)s' % format,
          expr: |||
            sum by (environment, tier, type, stage, shard, fqdn, component) (gitlab_component_node_errors:rate%(suffix)s{monitor!="global"} >= 0)
            /
            sum by (environment, tier, type, stage, shard, fqdn, component) (gitlab_component_node_ops:rate%(suffix)s{monitor!="global"} > 0)
          ||| % format,
        }],
    },

}
