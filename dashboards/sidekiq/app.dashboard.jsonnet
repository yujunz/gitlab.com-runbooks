local commonAnnotations = import 'common_annotations.libsonnet';
local common = import 'container_common_graphs.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local template = grafana.template;
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;

dashboard.new(
  'Application Info',
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
.addTemplate(
  template.custom(
    'Deployment',
    'gitlab-sidekiq-export,',
    'gitlab-sidekiq-export',
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
.addPanels(common.generalRubyCounters(startRow=1001))
+ {
  links+: platformLinks.triage +
          serviceCatalog.getServiceLinks('sidekiq') +
          platformLinks.services +
          [platformLinks.dynamicLinks('Sidekiq Detail', 'type:sidekiq')],
}
