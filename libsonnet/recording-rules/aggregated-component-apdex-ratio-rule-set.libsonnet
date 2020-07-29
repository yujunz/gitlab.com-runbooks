{
  // The component error ratio recording ruleset records the rate of errors divides by the rate of requests
  // across all components.
  aggregatedComponentApdexRatioRuleSet(suffix)::
    {
      generateRecordingRules()::
        local format = { suffix: suffix };

        [{
          record: 'gitlab_component_apdex:weight:score%(suffix)s' % format,
          expr: |||
            sum by (env, environment, tier, type, stage, component) (
              (
                (gitlab_component_apdex:ratio%(suffix)s{monitor!="global"} >= 0)
                *
                (gitlab_component_apdex:weight:score%(suffix)s{monitor!="global"} >= 0)
              )
            )
            /
            sum by (env, environment, tier, type, stage, component) (
              (gitlab_component_apdex:weight:score%(suffix)s{monitor!="global"} >= 0)
            )
          ||| % format,
        }, {
          record: 'gitlab_component_apdex:ratio%(suffix)s' % format,
          expr: |||
            sum by (env, environment, tier, type, stage, component) (
              (
                (gitlab_component_apdex:ratio%(suffix)s{monitor!="global"} >= 0)
                *
                (gitlab_component_apdex:weight:score%(suffix)s{monitor!="global"} >= 0)
              )
            )
            /
            sum by (env, environment, tier, type, stage, component) (
              (gitlab_component_apdex:weight:score%(suffix)s{monitor!="global"} >= 0)
            )
          ||| % format,
        }],
    },

}
