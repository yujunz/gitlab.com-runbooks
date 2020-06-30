{
  // serviceApdexRatioRuleSet generates rules at different burn rates for
  // aggregating component level error ratios up to the service level.
  // This is calculated as the combined apdex score across multiple components
  serviceApdexRatioRuleSet(suffix, weightScoreSuffix)::
    {
      generateRecordingRules()::
        local format = {
          suffix: suffix,
          weightScoreSuffix: weightScoreSuffix,
        };

        [{
          record: 'gitlab_service_apdex:ratio%(suffix)s' % format,
          expr: |||
            sum by (env, environment, tier, type, stage) (
              (
                (gitlab_component_apdex:ratio%(suffix)s{monitor!="global"} >= 0) * (gitlab_component_apdex:weight:score%(weightScoreSuffix)s{monitor!="global"} >= 0)
              )
              and on (env, tier, type, component)
              gitlab_component_service:mapping{monitor!="global"}
            )
            /
            sum by (env, environment, tier, type, stage) (
              (gitlab_component_apdex:weight:score%(weightScoreSuffix)s{monitor!="global"} >= 0)
              and on (env, tier, type, component)
              gitlab_component_service:mapping{monitor!="global"}
            )
          ||| % format,
        }],
    },
}
