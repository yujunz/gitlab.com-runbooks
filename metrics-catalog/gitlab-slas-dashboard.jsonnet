local slaDashboard =
  {
    dashboard: 'general SLAs',
    panel_groups: [
      {
        group: 'Headline',
        panels: [
          {
            title: 'Weighted Availability Score - GitLab.com',
            type: 'single-stat',
            max_value: 1,
            metrics: [
              {
                id: 'single-stat-weighted-availability',
                query: 'avg_over_time(sla:gitlab:ratio{environment="gprd", stage="main"}[3m])',
                unit: '%',
                label: 'Weighted Availability Score - GitLab.com',
              },
            ],
          },
          {
            title: 'Overall SLA over time period - gitlab.com',
            type: 'line-chart',
            metrics: [
              {
                id: 'line-chart-overall-sla-time-period',
                query_range: 'clamp_min(clamp_max(avg_over_time(sla:gitlab:ratio{environment="gprd", stage="main"}[1d]),1),0)',
                unit: '%',
                label: 'gitlab.com SLA',
              },
            ],
          },
        ],
      },
      {
        group: 'SLA Trends - Per primary service',
        panels: [
          {
            title: 'Primary Services Average Availability for Period - Registry',
            type: 'single-stat',
            max_value: 1,
            metrics: [
              {
                id: 'single-stat-sla-trend-registry',
                query: 'avg(avg_over_time(slo_observation_status{environment="gprd", stage="main", type="registry"}[7d]))',
                unit: '%',
                label: 'Primary Services Average Availability for Period - Registry',
              },
            ],
          },
          {
            title: 'Primary Services Average Availability for Period - Api',
            type: 'single-stat',
            max_value: 1,
            metrics: [
              {
                id: 'single-stat-sla-trend-api',
                query: 'avg(avg_over_time(slo_observation_status{environment="gprd", stage="main", type="api"}[7d]))',
                unit: '%',
                label: 'Primary Services Average Availability for Period - Api',
              },
            ],
          },
          {
            title: 'Primary Services Average Availability for Period - Git',
            type: 'single-stat',
            max_value: 1,
            metrics: [
              {
                id: 'single-stat-sla-trend-git',
                query: 'avg(avg_over_time(slo_observation_status{environment="gprd", stage="main", type="git"}[7d]))',
                unit: '%',
                label: 'Primary Services Average Availability for Period - Git',
              },
            ],
          },
          {
            title: 'Primary Services Average Availability for Period - Sidekiq',
            type: 'single-stat',
            max_value: 1,
            metrics: [
              {
                id: 'single-stat-sla-trend-sidekiq',
                query: 'avg(avg_over_time(slo_observation_status{environment="gprd", stage="main", type="sidekiq"}[7d]))',
                unit: '%',
                label: 'Primary Services Average Availability for Period - Sidekiq',
              },
            ],
          },
          {
            title: 'Primary Services Average Availability for Period - Web',
            type: 'single-stat',
            max_value: 1,
            metrics: [
              {
                id: 'single-stat-sla-trend-web',
                query: 'avg(avg_over_time(slo_observation_status{environment="gprd", stage="main", type="web"}[7d]))',
                unit: '%',
                label: 'Primary Services Average Availability for Period - Web',
              },
            ],
          },
          {
            title: 'Primary Services Average Availability for Period - Runners',
            type: 'single-stat',
            max_value: 1,
            metrics: [
              {
                id: 'single-stat-sla-trend-runners',
                query: 'avg(avg_over_time(slo_observation_status{environment="gprd", stage="main", type="ci-runners"}[7d]))',
                unit: '%',
                label: 'Primary Services Average Availability for Period - Runners',
              },
            ],
          },
          {
            title: 'SLA Trends - Primary Services',
            type: 'line-chart',
            metrics: [
              {
                id: 'line-chart-sla-trends-primary-services',
                query_range: 'clamp_min(clamp_max(avg(avg_over_time(slo_observation_status{environment="gprd", stage="main", type=~"api|web|git|registry|sidekiq|ci-runners"}[1d])) by (type),1),0)',
                unit: '%',
                label: '{{type}}',
              },
            ],
          },
        ],
      },
    ],
  };

{
  'sla-dashboard.yml': std.manifestYamlDoc(slaDashboard),
}
