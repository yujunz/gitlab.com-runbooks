local alerts = import 'alerts/alerts.libsonnet';
local multiburnFactors = import 'mwmbr/multiburn_factors.libsonnet';
local multiburnExpression = import 'mwmbr/expression.libsonnet';
local stableIds = import 'stable-ids/stable-ids.libsonnet';

// For now, only include components that run at least once a second
// in the monitoring. This is to avoid low-volume, noisy alerts
local minimumOperationRateForMonitoring = 1 /* rps */;

local formatConfig = multiburnFactors {
  minimumOperationRateForMonitoring: minimumOperationRateForMonitoring,
};

local rules = {
  groups: [{
    name: 'Service Component Alerts',
    partial_response_strategy: 'warn',
    interval: '1m',
    rules: [alerts.processAlertRule(
      {
        alert: 'component_apdex_ratio_burn_rate_slo_out_of_bounds_lower',
        expr: multiburnExpression.multiburnRateApdexExpression(
          metric1h='gitlab_component_apdex:ratio_1h',
          metric5m='gitlab_component_apdex:ratio_5m',
          metric30m='gitlab_component_apdex:ratio_30m',
          metric6h='gitlab_component_apdex:ratio_6h',
          metricSelectorHash={ monitor: 'global' },
          sloMetric='slo:min:events:gitlab_service_apdex:ratio',
          sloMetricSelectorHash={ monitor: 'global' },
          sloMetricAggregationLabels=['type', 'tier'],
          operationRateMetric='gitlab_component_ops:rate_1h',
          operationRateAggregationLabels=['environment', 'env', 'tier', 'type', 'component', 'stage'],
          operationRateSelectorHash={ monitor: { ne: "global" } },
          minimumOperationRateForMonitoring=minimumOperationRateForMonitoring
        ),
        'for': '2m',
        labels: {
          alert_type: 'symptom',
          rules_domain: 'general',
          severity: 's2',
          pager: 'pagerduty',
          slo_alert: 'yes',
        },
        annotations: {
          title: 'The `{{ $labels.component }}` component of the `{{ $labels.type }}` service, (`{{ $labels.stage }}` stage), has an apdex-score burn rate outside of SLO',
          description: |||
            Currently the apdex value is {{ $value | humanizePercentage }}.
          |||,
          runbook: 'docs/{{ $labels.type }}/service-{{ $labels.type }}.md',
          grafana_dashboard_id: 'alerts-component_multiburn_apdex/alerts-component-multi-window-multi-burn-rate-apdex-out-of-slo',
          grafana_panel_id: stableIds.hashStableId('multiwindow-multiburnrate'),
          grafana_variables: 'environment,type,stage,component',
          grafana_min_zoom_hours: '6',
          promql_template_1: 'gitlab_component_apdex:ratio_1h{environment="$environment", type="$type", stage="$stage", component="$component"}',
        },
      },
    ), alerts.processAlertRule({
      alert: 'component_error_ratio_burn_rate_slo_out_of_bounds_upper',
      expr: multiburnExpression.multiburnRateErrorExpression(
        metric1h='gitlab_component_errors:ratio_1h',
        metric5m='gitlab_component_errors:ratio_5m',
        metric30m='gitlab_component_errors:ratio_30m',
        metric6h='gitlab_component_errors:ratio_6h',
        metricSelectorHash={ monitor: 'global' },
        sloMetric='slo:max:events:gitlab_service_errors:ratio',
        sloMetricSelectorHash={ monitor: 'global' },
        sloMetricAggregationLabels=['type', 'tier'],
        operationRateMetric='gitlab_component_ops:rate_1h',
        operationRateAggregationLabels=['environment', 'env', 'tier', 'type', 'component', 'stage'],
        operationRateSelectorHash={ monitor: { ne: "global" } },
        minimumOperationRateForMonitoring=minimumOperationRateForMonitoring
      ),
      'for': '2m',
      labels: {
        rules_domain: 'general',
        severity: 's2',
        slo_alert: 'yes',
        alert_type: 'symptom',
        pager: 'pagerduty',
      },
      annotations: {
        title: 'The `{{ $labels.type }}` service, `{{ $labels.component }}` component, `{{ $labels.stage }}` stage, has an error burn-rate exceeding SLO',
        description: |||
          The `{{ $labels.type }}` service, `{{ $labels.component }}` component, `{{ $labels.stage }}` stage has an error burn-rate outside of SLO
          The error-burn rate for this service is outside of SLO over multiple windows. Currently the error-rate is {{ $value | humanizePercentage }}.
        |||,
        runbook: 'docs/{{ $labels.type }}/service-{{ $labels.type }}.md',
        grafana_dashboard_id: 'alerts-component_multiburn_error/alerts-component-multi-window-multi-burn-rate-out-of-slo',
        grafana_panel_id: stableIds.hashStableId('multiwindow-multiburnrate'),
        grafana_variables: 'environment,type,stage,component',
        grafana_min_zoom_hours: '6',
        link1_title: 'Definition',
        link1_url: 'https://gitlab.com/gitlab-com/runbooks/blob/master/docs/uncategorized/definition-service-error-rate.md',
        promql_template_1: 'gitlab_component_errors:ratio_5m{environment="$environment", type="$type", stage="$stage", component="$component"}',
      },
    })],
  }],
};

{
  'service-component-alerts.yml': std.manifestYamlDoc(rules),
}
