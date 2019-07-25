local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local colors = import 'colors.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local layout = import 'layout.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

local componentSaturationPanel() = graphPanel.new(
    "Saturation",
    description="Saturation is a measure of what ratio of a finite resource is currently being utilized. Lower is better.",
    sort="decreasing",
    linewidth=2,
    fill=0,
    datasource="$PROMETHEUS_DS",
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
  )
  .addTarget( // Primary metric
    promQuery.target('
      max(
        max_over_time(
          gitlab_component_saturation:ratio{environment="$environment", type="$type", stage="$stage", component="$component"}[$__interval]
        )
      ) by (component)
      ',
      legendFormat='{{ component }} component',
    )
  )
  .addTarget( // Soft SLO
    promQuery.target('
      avg(slo:max:soft:gitlab_component_saturation:ratio{component="$component"})
      ',
      legendFormat='Soft SLO',
    )
  )
  .addTarget( // Hard SLO
    promQuery.target('
      avg(slo:max:hard:gitlab_component_saturation:ratio{component="$component"})
      ',
      legendFormat='Hard SLO',
    )
  )
  .resetYaxes()
  .addYaxis(
    format='percentunit',
    max=1,
    label="Saturation %",
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addSeriesOverride(seriesOverrides.goldenMetric("/ component/"))
  .addSeriesOverride(seriesOverrides.softSlo)
  .addSeriesOverride(seriesOverrides.hardSlo);

dashboard.new(
  'Saturation Component Alert',
  schemaVersion=16,
  tags=['alert-target'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.type)
.addTemplate(templates.stage)
.addTemplate(templates.saturationComponent)
.addPanels(layout.grid([
    componentSaturationPanel(),
  ], cols=1,rowHeight=10))
+ {
  links+: platformLinks.parameterizedServiceLink + platformLinks.triage,
}


