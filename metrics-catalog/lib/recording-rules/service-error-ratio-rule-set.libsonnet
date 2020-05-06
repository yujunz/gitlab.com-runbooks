{
  // serviceErrorRatioRuleSet generates rules at different burn rates for
  // aggregating component level error ratios up to the service level.
  // This is calculated as the total number of errors handled by the service
  // as a ratio of total requests to the service.
  // This aggregation should be evaluated in Thanos, but during the migration
  // it is evaluated in Thanos and Prometheus.
  // targetThanos is deprecated: remove option once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689 is complete
  serviceErrorRatioRuleSet(
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
          record: 'gitlab_service_errors:ratio%(suffix)s' % format,
          expr: |||
            sum by (environment, env, tier, type, stage) (gitlab_component_errors:rate%(suffix)s%(monitorSelector)s >= 0)
            /
            sum by (environment, env, tier, type, stage) (gitlab_component_ops:rate%(suffix)s%(monitorSelector)s > 0)
          ||| % format,
        }],
    },

}
