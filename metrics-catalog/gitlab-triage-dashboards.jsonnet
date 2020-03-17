local services = import './services/triage.jsonnet';
local generateDashboardForService(service) =
  local type = service.type;
  local formatConfig = { type: type };

  {
    dashboard: 'Frontend Services -  %(type)s' % formatConfig,
    panel_groups: [
      {
        group: 'Frontend Services - %(type)s' % formatConfig,
        panels: [
          {
            title: 'Latency: Apdex',
            type: 'line-chart',
            y_label: 'Apdex %',
            metrics: [
              {
                id: 'line-chart-latency-apdex-%(type)s-service' % formatConfig,
                query_range: 'min(min_over_time(gitlab_service_apdex:ratio{environment="gprd", type="%(type)s", stage="main"}[1m])) by (type)' % formatConfig,
                unit: '%',
                label: '{{type}} Service' % formatConfig,
              },
              {
                id: 'line-chart-latency-apdex-degradation-%(type)-service' % formatConfig,
                query_range: 'avg(slo:min:gitlab_service_apdex:ratio{environment="gprd", type="%(type)s", stage="main"}) or avg(slo:min:gitlab_service_apdex:ratio{type="%(type)s"})' % formatConfig, 
                unit: '%',
                label: 'Degradation SLO',
              },
              {
                id: 'line-chart-latency-apdex-outage-%(type)-service' % formatConfig,
                query_range: '2 * (avg(slo:min:gitlab_service_apdex:ratio{environment="gprd", type="%(type)s", stage="main"}) or avg(slo:min:gitlab_service_apdex:ratio{type="%(type)s"})) - 1' % formatConfig, 
                unit: '%',
                label: 'Outage SLO',
              },
              {
                id: 'line-chart-latency-apdex-last-week-%(type)-service' % formatConfig,
                query_range: 'max(max_over_time(gitlab_service_errors:ratio{environment="gprd", type="%(type)s", stage="main"}[1m] offset 1w)) by (type)' % formatConfig, 
                unit: '%',
                label: 'Last Week',
              },
            ],
          },
          {
            title: 'Error Ratios',
            type: 'line-chart',
            y_label: 'Percentile',
            metrics: [
              {
                id: 'line-chart-error-ratios-%(type)s-service' % formatConfig,
                query_range: 'max(max_over_time(gitlab_service_errors:ratio{environment="gprd", type="%(type)s", stage="main"}[1m])) by (type)' % formatConfig,
                unit: '%',
                label: '{{type}} service',
              },
              {
                id: 'line-chart-error-ratios-degradation-%(type)s-service' % formatConfig,
                query_range: 'avg(slo:max:gitlab_service_errors:ratio{environment="gprd", type="%(type)s", stage="main"}) or avg(slo:max:gitlab_service_errors:ratio{type="%(type)s"})' % formatConfig,
                unit: '%',
                label: 'Degradation SLO',
              },
              {
                id: 'line-chart-error-ratios-outage-%(type)s-service' % formatConfig,
                query_range: '2 * (avg(slo:max:gitlab_service_errors:ratio{environment="gprd", type="%(type)s", stage="main"}) or avg(slo:max:gitlab_service_errors:ratio{type="%(type)s"}))' % formatConfig,
                unit: '%',
                label: 'Outage SLO',
              },
              {
                id: 'line-chart-error-ratios-last-week-%(type)s-service' % formatConfig,
                query_range: 'max(max_over_time(gitlab_service_errors:ratio{environment="gprd", type="%(type)s", stage="main"}[1m] offset 1w)) by (type)' % formatConfig,
                unit: '%',
                label: 'Last week',
              },
            ],
          },
        ],
      },
    ],
  };

local outputDashboardYaml(service) =
  std.manifestYamlDoc(generateDashboardForService(service));

{
  ['triage-dashboard-%s.yml' % [service.type]]:
    outputDashboardYaml(service)
  for service in services
}
