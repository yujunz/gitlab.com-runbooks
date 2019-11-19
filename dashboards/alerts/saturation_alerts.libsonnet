local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

{
  saturationDashboard(
    dashboardTitle,
    component,
    panel,
    helpPanel
    )::
    dashboard.new(
      dashboardTitle,
      schemaVersion=16,
      tags=[
        'alert-target',
        'saturationdetail',
        if component != '$component' then 'saturationdetail:' + component else 'saturationdetail:general',
      ],
      timezone='utc',
      graphTooltip='shared_crosshair',
    )
    .addAnnotation(commonAnnotations.deploymentsForEnvironment)
    .addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
    .addTemplate(templates.ds)
    .addTemplate(templates.environment)
    .addTemplate(templates.type)
    .addTemplate(templates.stage)
    .addPanel(panel, gridPos={ x: 0, y: 0, h: 20, w: 24 })
    .addPanel(helpPanel, gridPos={ x: 0, y: 1000, h: 6, w: 24 })
    + {
      links+: platformLinks.parameterizedServiceLink +
        platformLinks.services +
        platformLinks.triage +
        [
          platformLinks.dynamicLinks('Service Dashboards', 'type:$type managed', asDropdown=false, includeVars=false, keepTime=false),
          platformLinks.dynamicLinks('Saturation Detail', 'saturationdetail', asDropdown=true, includeVars=true, keepTime=true),
        ],
    },

  saturationDashboardForComponent(
    component,
    )::
    self.saturationDashboard(
      dashboardTitle=component + ': Saturation Detail',
      component=component,
      panel=saturationDetail.componentSaturationPanel(component, '$type', '$stage'),
      helpPanel=saturationDetail.componentSaturationHelpPanel(component),
    ),
}
