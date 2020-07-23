local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local serviceDashboard = import 'service_dashboard.libsonnet';
local row = grafana.row;
local processExporter = import 'process_exporter.libsonnet';

serviceDashboard.overview('frontend', 'lb')
.addPanel(
  row.new(title='HAProxy process'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  processExporter.namedGroup(
    'haproxy',
    {
      environment: '$environment',
      groupname: 'haproxy',
      type: 'frontend',
      stage: '$stage',
    },
    startRow=1001
  )
)
.overviewTrailer()
