local basic = import 'basic.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
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

dashboard.new(
  'GCP Load Balancer Alert',
  schemaVersion=16,
  tags=['alert-target', 'gcp'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
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
