local basic = import 'basic.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local railsCommon = import 'rails_common_graphs.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local unicornCommon = import 'unicorn_common_graphs.libsonnet';
local workhorseCommon = import 'workhorse_common_graphs.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local serviceHealth = import 'service_health.libsonnet';
local text = grafana.text;

dashboard.new(
  'GitLab Dashboards',
  schemaVersion=16,
  tags=[],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addTemplate(templates.ds)
.addTemplate(templates.defaultEnvironment)
.addPanel(
  row.new(title='FRONTEND SERVICES'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanel(
  text.new(
    title='Help',
    mode='markdown',
    content=|||
      This graphs show the frontend services that GitLab customer traffic will be initially handled by. Any issues in this
      fleet are more likely to be user-impacting.
    |||
  ),
  gridPos={
    x: 0,
    y: 1001,
    w: 24,
    h: 2,
  }
)
.addPanels(keyMetrics.headlineMetricsRow('web', 'main', startRow=1100, rowTitle='Web Frontend: gitlab.com web traffic'))
.addPanels(keyMetrics.headlineMetricsRow('api', 'main', startRow=1200, rowTitle='API: gitlab.com/api traffic'))
.addPanels(keyMetrics.headlineMetricsRow('git', 'main', startRow=1300, rowTitle='Git: git ssh and https traffic'))
.addPanels(keyMetrics.headlineMetricsRow('ci-runners', 'main', startRow=1400, rowTitle='CI Runners'))
.addPanels(keyMetrics.headlineMetricsRow('registry', 'main', startRow=1500, rowTitle='Container Registry'))
.addPanel(
  row.new(title='Welcome'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanel(
  text.new(
    title='Welcome',
    mode='markdown',
    content=|||
      # GitLab Public Dashboards

      Welcome to the GitLab public dashboard. GitLab [values transparency](https://about.gitlab.com/handbook/values/#transparency),
      so we maintain a public copy of our internal dashboards.

      Due to privacy reasons and more strict query limitations not all dashboards may work correctly.
    |||
  ),
  gridPos={
    x: 0,
    y: 2001,
    w: 18,
    h: 12,
  }
)
.addPanel(
  text.new(
    title='Welcome',
    mode='markdown',
    content=|||
      # Useful Links

      * **[Platform Triage Dashboard](/d/general-triage/general-platform-triage?orgId=1)** technical overview for all services.
      * **[Capacity Planning Dashboard](/d/general-capacity-planning/general-capacity-planning?orgId=1)** resources currently saturated, or at risk of becoming saturated.
      * **[Service SLA Dashboard](/d/general-slas/general-slas?orgId=1)** service SLA tracking.
      * **[Source repository for these dashboards](https://gitlab.com/gitlab-com/runbooks/tree/master/dashboards)** - interested in how we use [grafonnet-lib](https://github.com/grafana/grafonnet-lib)
        to build our dashboards?

    |||
  ),
  gridPos={
    x: 18,
    y: 2001,
    w: 6,
    h: 12,
  }
)
