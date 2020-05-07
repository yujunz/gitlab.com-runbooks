{
  // The serviceNodeErrorRatio ruleset will generate recording rules for a particular burn rate
  // to roll up nodeLevelMonitoring to the service level, providing insights into nodes
  // at a service level.
  //
  // Note: Only gitaly currently uses nodeLevelMonitoring.
  //
  // targetThanos is deprecated: remove option once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689 is complete
  serviceNodeErrorRatioRuleSet(
    suffix,
    targetThanos=true,
  )::
    {
      generateRecordingRules()::
        local monitorSelector = if targetThanos then
          '{monitor!="global"}'
        else
          '';

        local format = { suffix: suffix, monitorSelector: monitorSelector };

        [{
          record: 'gitlab_service_node_errors:ratio%(suffix)s' % format,
          expr: |||
            sum by (environment, env, tier, type, stage, shard, fqdn) (gitlab_component_node_errors:rate%(suffix)s%(monitorSelector)s >= 0)
            /
            sum by (environment, env, tier, type, stage, shard, fqdn) (gitlab_component_node_ops:rate%(suffix)s%(monitorSelector)s > 0)
          ||| % format,
        }],
    },

}
