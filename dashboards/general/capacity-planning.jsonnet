local capacityPlanning = import 'capacity_planning.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local basic = import 'grafana/basic.libsonnet';

local rowHeight = 8;
local colWidth = 12;

basic.dashboard(
  'Capacity Planning',
  tags=['general'],
  includeStandardEnvironmentAnnotations=false,
)
.addPanels(capacityPlanning.environmentCapacityPlanningPanels(''))
+ {
  links+: platformLinks.services,
}
