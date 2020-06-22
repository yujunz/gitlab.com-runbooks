local basic = import 'basic.libsonnet';
local colors = import 'colors.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local railsCommon = import 'rails_common_graphs.libsonnet';
local workhorseCommon = import 'workhorse_common_graphs.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceDashboard = import 'service_dashboard.libsonnet';

local selector = 'environment="$environment", type="api", stage="$stage"';

serviceDashboard.overview('api', 'sv')
.addPanel(
  row.new(title='Workhorse'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(workhorseCommon.workhorsePanels(serviceType='api', serviceStage='$stage', startRow=1001))
.addPanel(
  row.new(title='Rails'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(railsCommon.railsPanels(serviceType='api', serviceStage='$stage', startRow=3001))
.overviewTrailer()
