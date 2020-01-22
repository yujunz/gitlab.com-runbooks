local grafana = import 'grafonnet/grafana.libsonnet';
local railsCommon = import 'rails_common_graphs.libsonnet';
local unicornCommon = import 'unicorn_common_graphs.libsonnet';
local workhorseCommon = import 'workhorse_common_graphs.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'service_dashboard.libsonnet';

serviceDashboard.overview('git', 'sv')
.addPanel(
  row.new(title='Workhorse'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(workhorseCommon.workhorsePanels(serviceType='git', serviceStage='$stage', startRow=1001))
.addPanel(
  row.new(title='Unicorn'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(unicornCommon.unicornPanels(serviceType='git', serviceStage='$stage', startRow=1001))
.addPanel(
  row.new(title='Rails'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(railsCommon.railsPanels(serviceType='git', serviceStage='$stage', startRow=3001))
.overviewTrailer()
