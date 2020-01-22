local commonAnnotations = import 'common_annotations.libsonnet';
local common = import 'container_common_graphs.libsonnet';
local crCommon = import 'container_registry_graphs.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local template = grafana.template;
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local basic = import 'basic.libsonnet';

basic.dashboard(
  'Application Info',
  tags=['container registry', 'docker', 'registry'],
)
.addTemplate(templates.gkeCluster)
.addTemplate(templates.namespaceGitlab)
.addTemplate(
  template.custom(
    'Deployment',
    'gitlab-registry,',
    'gitlab-registry',
    hide='variable',
  )
)
.addPanel(

  row.new(title='Stackdriver Metrics'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(common.logMessages(startRow=1))
.addPanel(

  row.new(title='General Counters'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(common.generalCounters(startRow=1001))
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
