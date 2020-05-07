{
  // The component error ratio recording ruleset records the rate of errors divides by the rate of requests
  // across all components.
  //
  // It is intended to only run in Thanos, but while we migrate, it will run in both
  // Thanos and Prometheus.
  componentErrorRatioRuleSet(
    suffix,
    targetThanos=true,  // targetThanos is deprecated: remove option once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689 is complete
  )::
    {
      generateRecordingRules()::
        local monitorSelector = if targetThanos then
          '{monitor!="global"}'
        else
          '';

        local format = { suffix: suffix, monitorSelector: monitorSelector };

        [{
          record: 'gitlab_component_errors:ratio%(suffix)s' % format,
          expr: |||
            gitlab_component_errors:rate%(suffix)s%(monitorSelector)s
            /
            gitlab_component_ops:rate%(suffix)s%(monitorSelector)s
          ||| % format,
        }],
    },

}
