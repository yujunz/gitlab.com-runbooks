local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local k8sCommon = import 'kubernetes_application_common.libsonnet';
local template = grafana.template;
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local basic = import 'basic.libsonnet';

basic.dashboard(
  'Pod Info',
  tags=['container registry', 'docker', 'registry'],
)
.addTemplate(templates.gkeCluster)
.addTemplate(templates.namespaceGitlab)
.addTemplate(templates.Node)
.addTemplate(
  template.custom(
    'Deployment',
    'gitlab-registry,',
    'gitlab-registry',
    hide='variable',
  )
)
.addPanel(

  row.new(title='Container Registry Version'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sCommon.version(startRow=1))
.addPanel(

  row.new(title='Deployment Info'),
  gridPos={
    x: 0,
    y: 500,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sCommon.deployment(startRow=501))
.addPanels(k8sCommon.status(startRow=502))
.addPanel(

  row.new(title='CPU'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sCommon.cpu(startRow=1001))
.addPanel(

  row.new(title='Memory'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sCommon.memory(startRow=2001, container='registry'))
.addPanel(

  row.new(title='Network'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(k8sCommon.network(startRow=3001))
