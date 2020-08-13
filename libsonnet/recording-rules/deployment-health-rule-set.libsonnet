local mwmbrExpression = import 'mwmbr/expression.libsonnet';

{
  deploymentHealthRuleSet()::
    {
      generateRecordingRules()::
        [{
          record: 'gitlab_deployment_health:service:errors',
          expr: mwmbrExpression.errorHealthExpression(
            metric1h='gitlab_service_errors:ratio_1h',
            metric5m='gitlab_service_errors:ratio_5m',
            metric30m='gitlab_service_errors:ratio_30m',
            metric6h='gitlab_service_errors:ratio_6h',
            metricSelectorHash={ monitor: 'global' },
            sloMetric='slo:max:deployment:gitlab_service_errors:ratio',
            sloMetricSelectorHash={ monitor: 'global' },
            sloMetricAggregationLabels=['type', 'tier'],
          ),
        }, {
          record: 'gitlab_deployment_health:service:apdex',
          expr: mwmbrExpression.apdexHealthExpression(
            metric1h='gitlab_service_apdex:ratio_1h',
            metric5m='gitlab_service_apdex:ratio_5m',
            metric30m='gitlab_service_apdex:ratio_30m',
            metric6h='gitlab_service_apdex:ratio_6h',
            metricSelectorHash={ monitor: 'global' },
            sloMetric='slo:min:deployment:gitlab_service_apdex:ratio',
            sloMetricSelectorHash={ monitor: 'global' },
            sloMetricAggregationLabels=['type', 'tier'],
          ),
        }, {
          record: 'gitlab_deployment_health:service',
          expr: |||
            min without (sli_type) (
              label_replace(gitlab_deployment_health:service:apdex{monitor="global"}, "sli_type", "apdex", "", "")
              or
              label_replace(gitlab_deployment_health:service:errors{monitor="global"}, "sli_type", "errors", "", "")
            )
          |||
        }, {
          record: 'gitlab_deployment_health:stage',
          expr: |||
            min by (environment, env, stage) (
              gitlab_deployment_health:service{monitor="global"}
            )
          |||
        }],
    },

}
