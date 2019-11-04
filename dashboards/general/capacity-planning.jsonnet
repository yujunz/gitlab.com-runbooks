local capacityPlanning = import 'capacity_planning.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;

local rowHeight = 8;
local colWidth = 12;

dashboard.new(
  'Capacity Planning',
  schemaVersion=16,
  tags=['general'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanels(capacityPlanning.environmentCapacityPlanningPanels())
 + {
  links+: platformLinks.services,
}
