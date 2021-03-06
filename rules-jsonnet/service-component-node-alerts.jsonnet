local alerts = import 'alerts/alerts.libsonnet';
local multiburnExpression = import 'mwmbr/expression.libsonnet';
local multiburnFactors = import 'mwmbr/multiburn_factors.libsonnet';
local stableIds = import 'stable-ids/stable-ids.libsonnet';

// For now, only include components that run at least once a second
// in the monitoring. This is to avoid low-volume, noisy alerts
local minimumOperationRateForMonitoring = 1/* rps */;

// Most MWMBR alerts use a 2m period
// Initially for this alert, use a long period to ensure that
// it's not too noisy.
// Consider bringing this down to 2m after 1 Sep 2020
local alertWaitPeriod = '10m';

local formatConfig = multiburnFactors {
  minimumOperationRateForMonitoring: minimumOperationRateForMonitoring,
};

local rules = {
  groups: [{
    name: 'Service Component/Node Alerts',
    interval: '1m',
    rules: [alerts.processAlertRule(
      {
        alert: 'ServiceSLOApdexViolationSingleNode',
        expr: multiburnExpression.multiburnRateApdexExpression(
          metric1h='gitlab_component_node_apdex:ratio_1h',
          metric5m='gitlab_component_node_apdex:ratio_5m',
          metric30m='gitlab_component_node_apdex:ratio_30m',
          metric6h='gitlab_component_node_apdex:ratio_6h',
          metricSelectorHash={},
          sloMetric='slo:min:events:gitlab_component_node_apdex:ratio',
          sloMetricSelectorHash={},
          sloMetricAggregationLabels=['type', 'tier'],
          operationRateMetric='gitlab_component_node_ops:rate_1h',
          minimumOperationRateForMonitoring=minimumOperationRateForMonitoring
        ),
        'for': alertWaitPeriod,
        labels: {
          alert_type: 'symptom',
          rules_domain: 'general',
          severity: 's4',
          // pager: 'pagerduty',
          slo_alert: 'yes',
        },
        annotations: {
          title: 'Node `{{ $labels.fqdn }}`, `{{ $labels.component }}` component is violating its apdex SLO',
          description: |||
            `{{ $labels.fqdn }}` has been violating its apdex SLO for more than %(alertWaitPeriod)s.

            Since the {{ $labels.type }} service is not redundant, failures in the `{{ $labels.component }}` component
            could lead to user-impacting service degradation.

            Currently the apdex value is {{ $value | humanizePercentage }}.

            Recommended course of action: review ELK logs, check for possible user action or unusual activity.
          ||| % {
            alertWaitPeriod: alertWaitPeriod,
          },
          runbook: 'docs/{{ $labels.type }}/README.md',
          grafana_dashboard_id: 'alerts-component_node_multiburn_apdex/alerts-component-node-multi-window-multi-burn-rate-apdex-out-of-slo',
          grafana_panel_id: stableIds.hashStableId('multiwindow-multiburnrate'),
          grafana_variables: 'environment,type,stage,component,fqdn',
          grafana_min_zoom_hours: '6',
          promql_template_1: 'gitlab_component_node_apdex:ratio_1h{environment="$environment", type="$type", stage="$stage", component="$component", fqdn="$fqdn"}',
        },
      },
    ), alerts.processAlertRule({
      alert: 'ServiceSLOErrorViolationSingleNode',
      expr: multiburnExpression.multiburnRateErrorExpression(
        metric1h='gitlab_component_node_errors:ratio_1h',
        metric5m='gitlab_component_node_errors:ratio_5m',
        metric30m='gitlab_component_node_errors:ratio_30m',
        metric6h='gitlab_component_node_errors:ratio_6h',
        metricSelectorHash={},
        sloMetric='slo:max:events:gitlab_component_node_errors:ratio',
        sloMetricSelectorHash={},
        sloMetricAggregationLabels=['type', 'tier'],
        operationRateMetric='gitlab_component_node_ops:rate_1h',
        minimumOperationRateForMonitoring=minimumOperationRateForMonitoring
      ),
      'for': alertWaitPeriod,
      labels: {
        rules_domain: 'general',
        severity: 's4',
        slo_alert: 'yes',
        alert_type: 'symptom',
        // pager: 'pagerduty',
      },
      annotations: {
        title: 'Node `{{ $labels.fqdn }}`, `{{ $labels.component }}` component is violating its error SLO',
        description: |||
          `{{ $labels.fqdn }}` has been violating its error SLO for more than %(alertWaitPeriod)s.

          Since the {{ $labels.type }} service is not redundant, failures in the `{{ $labels.component }}` component
          could lead to user-impacting service degradation.

          Currently the error rate value is {{ $value | humanizePercentage }}.

          Recommended course of action: review ELK logs, check for possible user action or unusual activity.
        ||| % {
          alertWaitPeriod: alertWaitPeriod,
        },
        runbook: 'docs/{{ $labels.type }}/README.md',
        grafana_dashboard_id: 'alerts-component_node_multiburn_error/alerts-component-node-multi-window-multi-burn-rate-error-rate-out-of-slo',
        grafana_panel_id: stableIds.hashStableId('multiwindow-multiburnrate'),
        grafana_variables: 'environment,type,stage,component,fqdn',
        grafana_min_zoom_hours: '6',
        promql_template_1: 'gitlab_component_node_errors:ratio_5m{environment="$environment", type="$type", stage="$stage", component="$component", fqdn="$fqdn"}',
      },
    })],
  }],
};

{
  'service-component-node-alerts.yml': std.manifestYamlDoc(rules),
}
