local multiburnFactors = import 'lib/multiburn_factors.libsonnet';

// For now, only include jobs that run 0.6 times per second, or 4 times a minute
// in the monitoring. This is to avoid low-volume, noisy alerts
local minimumOperationRateForMonitoring = 4 / 60;

local formatConfig = multiburnFactors {
  minimumOperationRateForMonitoring: minimumOperationRateForMonitoring,
};

local rules = {
  groups: [{
    name: 'Service Component Alerts',
    interval: '1m',
    rules: [
      {
        alert: 'component_apdex_ratio_burn_rate_slo_out_of_bounds_upper',
        expr: |||
          (
            (
              (
                gitlab_component_apdex:ratio_1h
                < on(tier, type) group_left()
                (1 - (%(burnrate_1h)g * (1 - slo:min:events:gitlab_service_apdex:ratio)))
              )
              and
              (
                gitlab_component_apdex:ratio_5m
                < on(tier, type) group_left()
                (1 - (%(burnrate_1h)g * (1 - slo:min:events:gitlab_service_apdex:ratio)))
              )
            )
            or
            (
              (
                gitlab_component_apdex:ratio_6h
                < on(tier, type) group_left()
                (1 - (%(burnrate_6h)g * (1 - slo:min:events:gitlab_service_apdex:ratio)))
              )
              and
              (
                gitlab_component_apdex:ratio_30m
                < on(tier, type) group_left()
                (1 - (%(burnrate_6h)g * (1 - slo:min:events:gitlab_service_apdex:ratio)))
              )
            )
          )
        ||| % formatConfig,
        'for': '2m',
        labels: {
          alert_type: 'symptom',
          rules_domain: 'general',
          metric: 'gitlab_component_apdex:ratio_1h',
          severity: 's2',
          pager: 'pagerduty',
          slo_alert: 'yes',
          period: '2m',
        },
        annotations: {
          title: 'The `{{ $labels.component }}` component of the `{{ $labels.type }}` service, (`{{ $labels.stage }}` stage), has a apdex-score burn rate outside of SLO',
          description: |||
            The `{{ $labels.component }}` component of the `{{ $labels.type }}` service, (`{{ $labels.stage }}` stage), has a apdex-score burn rate outside of SLO.

            Currently the apdex value is {{ $value | humanizePercentage }}.
          |||,
          runbook: 'docs/{{ $labels.type }}/service-{{ $labels.type }}.md',
          grafana_dashboard_id: 'alerts-component_multiburn_apdex/alerts-component-multi-window-multi-burn-rate-apdex-out-of-slo',
          grafana_panel_id: '4',
          grafana_variables: 'environment,type,stage,component',
          grafana_min_zoom_hours: '6',
          promql_template_1: 'gitlab_component_apdex:ratio_1h{environment="$environment", type="$type", stage="$stage", component="$component"}',
        },
      },
    ],
  }],
};

{
  'service-component-alerts.yml': std.manifestYamlDoc(rules),
}
