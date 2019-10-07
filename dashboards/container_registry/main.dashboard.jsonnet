local commonAnnotations = import 'common_annotations.libsonnet';
local crCommon = import 'container_registry_common_graphs.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;

dashboard.new(
  'Application Info',
  schemaVersion=16,
  tags=['container registry', 'docker', 'registry'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.gkeCluster)
.addTemplate(templates.namespace)
.addPanel(

  row.new(title='Stackdriver Metrics'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(crCommon.logMessages(startRow=1))
.addPanel(

  row.new(title='General Counters'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(crCommon.generalCounters(startRow=1001))
.addPanel(

  row.new(title='Data'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(crCommon.data(startRow=2001))
.addPanel(

  row.new(title='Handler Latencies'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(crCommon.latencies(startRow=3001))
