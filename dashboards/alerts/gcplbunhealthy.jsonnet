local basic = import 'grafana/basic.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;
local link = grafana.link;

local healthRatioPanel() = basic.timeseries(
  title='Percentage backends healthy per LB',
  description='Percentage ',
  query=|||
    load_balancer_name:health_backend:ratio{load_balancer_name="$load_balancer_name"}
  |||,
  max=1,
  format='percentunit',
  linewidth=2
);


basic.dashboard(
  'GCP Load Balancer Alert',
  tags=['alert-target', 'gcp'],
  graphTooltip='shared_crosshair',
  includeEnvironmentTemplate=false
)
.addTemplate(template.new(
  'load_balancer_name',
  '$PROMETHEUS_DS',
  'label_values(load_balancer_name:health_backend:ratio, load_balancer_name)',
  refresh='load',
  sort=1,
),)
.addPanels(layout.grid([
  healthRatioPanel(),
], cols=1, rowHeight=15))
+ {
  links+: platformLinks.triage + [
    link.dashboards('Google Cloud Console Load Balancers', '', type='link', url='https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list?project=gitlab-production'),
  ],
}
