local basic = import 'basic.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local pgbouncerCommonGraphs = import 'pgbouncer_common_graphs.libsonnet';
local row = grafana.row;
local processExporter = import 'process_exporter.libsonnet';
local serviceDashboard = import 'service_dashboard.libsonnet';

serviceDashboard.overview('patroni', 'db', stage='main')
.addPanel(
  row.new(title='pgbouncer Workload', collapse=false),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.workloadStats('patroni', 1001))
.addPanel(
  row.new(title='pgbouncer Connection Pooling', collapse=false),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.connectionPoolingPanels('patroni', 2001))
.addPanel(
  row.new(title='pgbouncer Network', collapse=false),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.networkStats('patroni', 3001))
.addPanel(
  row.new(title='patroni process stats'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  processExporter.namedGroup(
    'patroni',
    {
      environment: '$environment',
      groupname: 'patroni',
      type: 'patroni',
      stage: 'main',
    },
    startRow=4001
  )
)
.overviewTrailer()
