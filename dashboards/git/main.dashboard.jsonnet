local grafana = import 'grafonnet/grafana.libsonnet';
local railsCommon = import 'rails_common_graphs.libsonnet';
local workhorseCommon = import 'workhorse_common_graphs.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'service_dashboard.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';

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
.addPanels(
  layout.grid(
    [
      basic.timeseries(
        title='Workhorse Git HTTP Sessions',
        query=|||
          gitlab_workhorse_git_http_sessions_active:total{environment="$environment",stage="$stage",type="git"}
        |||,
        legendFormat='Sessions',
        stableId='workhorse-sessions',
      ),
    ],
    startRow=2000
  )
)
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
