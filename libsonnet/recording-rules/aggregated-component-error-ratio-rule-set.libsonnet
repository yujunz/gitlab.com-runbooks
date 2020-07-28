{
  // The component error ratio recording ruleset records the rate of errors divides by the rate of requests
  // across all components.
  aggregatedComponentErrorRatioRuleSet(suffix)::
    {
      generateRecordingRules()::
        local format = { suffix: suffix };

        [{
          record: 'gitlab_component_errors:ratio%(suffix)s' % format,
          expr: |||
            gitlab_component_errors:rate%(suffix)s{monitor!="global"}
            /
            gitlab_component_ops:rate%(suffix)s{monitor!="global"}
          ||| % format,
        }],
    },

}
