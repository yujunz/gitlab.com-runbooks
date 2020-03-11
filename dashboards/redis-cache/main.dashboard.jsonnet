local grafana = import 'grafonnet/grafana.libsonnet';
local redisCommon = import 'redis_common_graphs.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'service_dashboard.libsonnet';
local processExporter = import 'process_exporter.libsonnet';

serviceDashboard.overview('redis-cache', 'db')
.addPanel(
  row.new(title='Clients'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.clientPanels(serviceType='redis-cache', startRow=1001))
.addPanel(
  row.new(title='Workload'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.workload(serviceType='redis-cache', startRow=2001))
.addPanel(
  row.new(title='Redis Data'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.data(serviceType='redis-cache', startRow=3001))
.addPanel(
  row.new(title='Replication'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.replication(serviceType='redis-cache', startRow=4001))
.addPanel(
  row.new(title='Sentinel Processes', collapse=true)
    .addPanels(
      processExporter.namedGroup('sentinel', 'redis-sentinel 0.0.0.0:26379 [sentinel]', 'redis-cache', '$stage', startRow=1)
    ),
  gridPos={
    x: 0,
    y: 5000,
    w: 24,
    h: 1,
  },
)
.overviewTrailer()
