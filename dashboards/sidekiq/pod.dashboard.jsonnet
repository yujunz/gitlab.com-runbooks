local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local k8sCommon = import 'kubernetes_application_common.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local template = grafana.template;
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;

dashboard.new(
  'Pod Info',
  schemaVersion=16,
  tags=['sidekiq'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.gkeCluster)
.addTemplate(templates.namespaceGitlab)
.addTemplate(templates.Node)
.addTemplate(
  template.custom(
    'Deployment',
    'gitlab-sidekiq-export,',
    'gitlab-sidekiq-export',
    hide='variable',
  )
)
.addPanel(

  row.new(title='Sidekiq GitLab Version'),
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
.addPanels(k8sCommon.memory(startRow=2001, container='sidekiq'))
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
+ {
  links+: platformLinks.triage +
          serviceCatalog.getServiceLinks('sidekiq') +
          platformLinks.services +
          [platformLinks.dynamicLinks('Sidekiq Detail', 'type:sidekiq')],
}
