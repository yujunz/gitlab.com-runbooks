local grafana = import 'grafonnet/grafana.libsonnet';
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
  processExporter.namedGroup('haproxy', 'haproxy', 'frontend', '$stage', startRow=1001)
)
.overviewTrailer()
