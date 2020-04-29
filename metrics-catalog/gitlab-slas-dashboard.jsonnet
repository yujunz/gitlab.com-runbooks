local serviceCatalog = import 'service_catalog.libsonnet';
local keyServices = serviceCatalog.findServices(function(service)
  std.objectHas(service.business.SLA, 'overall_sla_weighting') && service.business.SLA.overall_sla_weighting > 0);

local keyServiceNames = std.sort(std.map(function(service) service.name, keyServices));
local keyServiceRegExp = std.join('|', keyServiceNames);

// Currently this is fixed, but ideally need have a variable range, like the
// grafana $__range variable supports
local range = '7d';

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
                // NB: this query takes into account values recorded in Prometheus prior to
                // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
                // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
                query: 'avg(clamp_max(avg_over_time(sla:gitlab:ratio{env=~"ops|gprd", environment="gprd", stage="main", monitor=~"global|"}[%(range)s]),1))' % {
                  range: range,
                },
                unit: '%',
                label: 'Weighted Availability Score - GitLab.com',
              },
            ],
          },
          {
            title: 'Overall SLA over time period - gitlab.com',
            type: 'line-chart',
            y_axis: {
              name: 'SLA',
              format: 'percent',
            },
            metrics: [
              {
                id: 'line-chart-overall-sla-time-period',
                // NB: this query takes into account values recorded in Prometheus prior to
                // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
                // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
                query_range: 'avg(clamp_max(avg_over_time(sla:gitlab:ratio{env=~"ops|gprd", environment="gprd", stage="main", monitor=~"global|"}[1d]),1))',
                unit: '%',
                label: 'gitlab.com SLA',
                step: 86400,
              },
            ],
          },
        ],
      },
      {
        group: 'SLA Trends - Per primary service',
        panels:
          [
            {
              title: 'Primary Services Average Availability for Period - %(type)s' % { type: type },
              type: 'single-stat',
              max_value: 1,
              metrics: [
                {
                  id: 'single-stat-sla-trend-%(type)s' % {
                    type: type,
                  },
                  // NB: this query takes into account values recorded in Prometheus prior to
                  // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
                  // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
                  query: 'avg(avg_over_time(slo_observation_status{env=~"ops|gprd", environment="gprd", stage="main", type="%(type)s"}[%(range)s]))' % {
                    type: type,
                    range: range,
                  },
                  unit: '%',
                  label: 'Primary Services Average Availability for Period - %(type)s' % { type: type },
                },
              ],
            }
            for type in keyServiceNames
          ]
          +
          [
            {
              title: 'SLA Trends - Primary Services',
              type: 'line-chart',
              y_axis: {
                name: 'SLA',
                format: 'percent',
              },
              metrics: [
                {
                  id: 'line-chart-sla-trends-primary-services',
                  // NB: this query takes into account values recorded in Prometheus prior to
                  // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
                  // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
                  query_range: 'clamp_min(clamp_max(avg(avg_over_time(slo_observation_status{env=~"ops|gprd", environment="gprd", stage="main", type=~"%(keyServiceRegExp)s"}[1d])) by (type),1),0)' % {
                    keyServiceRegExp: keyServiceRegExp,
                  },
                  unit: '%',
                  label: '{{type}}',
                  step: 86400,
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
