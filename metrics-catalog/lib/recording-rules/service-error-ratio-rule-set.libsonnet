{
  // serviceErrorRatioRuleSet generates rules at different burn rates for
  // aggregating component level error ratios up to the service level.
  // This is calculated as the total number of errors handled by the service
  // as a ratio of total requests to the service.
  serviceErrorRatioRuleSet(suffix)::
    {
      generateRecordingRules()::
        local format = { suffix: suffix };

        [{
          record: 'gitlab_service_errors:ratio%(suffix)s' % format,
          expr: |||
            sum by (environment, env, tier, type, stage) (gitlab_component_errors:rate%(suffix)s{monitor!="global"} >= 0)
            /
            sum by (environment, env, tier, type, stage) (gitlab_component_ops:rate%(suffix)s{monitor!="global"} > 0)
          ||| % format,
        }],
    },

}
