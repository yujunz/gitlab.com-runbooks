local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

local generalGraphPanel(
  title,
  description=null
      ) = graphPanel.new(
  title,
  linewidth=1,
  fill=0,
  datasource='default',
  description=description,
  decimals=2,
  legend_show=true,
  legend_values=true,
  legend_min=true,
  legend_max=true,
  legend_current=true,
  legend_total=false,
  legend_avg=true,
  legend_alignAsTable=true,
  legend_hideEmpty=true,
);

local welcomePanel() = grafana.text.new(
  title='',
  mode='markdown',
  content=|||
    # GitLab Public Dashboards

    Welcome to the GitLab public dashboard. GitLab [values transparency](https://about.gitlab.com/handbook/values/#transparency), so we maintain a public copy of our internal dashboards.

    Due to privacy reasons and more strict query limitations not all dashboards may work correctly.

    We also sync a copy of the [dashboard source](https://gitlab.com/gitlab-org/grafana-dashboards).

    Some dashboards are also [automatically generated](https://gitlab.com/gitlab-com/runbooks/tree/master/dashboards) using [grafonnet-lib](https://github.com/grafana/grafonnet-lib).
  |||,
);

local apdexPanel(title, description, type) =
  generalGraphPanel(
    title,
    description,
  )
  .addTarget(
    promQuery.target(
      |||
        avg by (type) (
          avg_over_time(gitlab_service_apdex:ratio{env="gprd",type=~"$(type)s"}[$__interval])
        )
      ||| % {
        type: type,
      },
      interval='1m',
      intervalFactor=1,
      legendFormat='{{type}}',
    )
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    min=0,
    max=1,
  );

local apiwebPanel() =
  apdexPanel(
    'API/Web Apdex',
    'Apdex score for API and Web requests',
    '(api|web)',
  );

local gitalyPanel() =
  apdexPanel(
    'Gitaly Apdex',
    'Apdex score for Gitaly requests',
    'gitaly',
  );

local registryPanel() =
  apdexPanel(
    'Registry Apdex',
    'Apdex score for Docker Registry requests',
    'registry',
  );

dashboard.new(
  'Public Splashscreen',
  schemaVersion=16,
  tags=['general'],
  timezone='utc',
  graphTooltip='shared_crosshair',
)
.addTemplate(templates.ds)
.addPanel(
  welcomePanel(),
  gridPos={
    x: 0,
    y: 10,
    w: 12,
    h: 10,
  }
)
.addPanel(
  apiwebPanel(),
  gridPos={
    x: 12,
    y: 10,
    w: 12,
    h: 10,
  }
)
.addPanel(
  gitalyPanel(),
  gridPos={
    x: 0,
    y: 20,
    w: 12,
    h: 10,
  }
)
.addPanel(
  registryPanel(),
  gridPos={
    x: 12,
    y: 20,
    w: 12,
    h: 10,
  }
)
