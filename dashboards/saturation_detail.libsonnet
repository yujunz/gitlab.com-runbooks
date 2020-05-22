local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local layout = import 'layout.libsonnet';
local text = grafana.text;
local issueSearch = import 'issue_search.libsonnet';
local saturationResources = import './saturation-resources.libsonnet';

{
  saturationPanel(title, description, component, linewidth=1, query=null, legendFormat=null, selector=null)::
    local formatConfig = {
      component: component,
      query: query,
      selector: selector,
    };

    local panel = graphPanel.new(
      title,
      description,
      sort='decreasing',
      linewidth=linewidth,
      fill=0,
      datasource='$PROMETHEUS_DS',
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

    local p2 = if query != null then
      panel.addTarget(  // Primary metric
        promQuery.target(
          |||
            clamp_min(
              clamp_max(
                %(query)s
              ,1)
            ,0)
          ||| % formatConfig,
          legendFormat=legendFormat,
        )
      )
    else
      panel;

    p2.addTarget(  // Primary metric
      promQuery.target(
        |||
          clamp_min(
            clamp_max(
              max(
                max_over_time(
                  gitlab_component_saturation:ratio{%(selector)s, component="%(component)s"}[$__interval]
                )
              ) by (component)
            ,1)
          ,0)
        ||| % formatConfig,
        legendFormat='aggregated {{ component }}',
      )
    )
    .addTarget(  // Soft SLO
      promQuery.target(
        |||
          avg(slo:max:soft:gitlab_component_saturation:ratio{component="%(component)s"}) by (component)
        ||| % formatConfig,
        legendFormat='Soft SLO: {{ component }}',
      )
    )
    .addTarget(  // Hard SLO
      promQuery.target(
        |||
          avg(slo:max:hard:gitlab_component_saturation:ratio{component="%(component)s"}) by (component)
        ||| % formatConfig,
        legendFormat='Hard SLO: {{ component }}',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label='Saturation %',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    )
    .addSeriesOverride(seriesOverrides.softSlo)
    .addSeriesOverride(seriesOverrides.hardSlo)
    .addSeriesOverride(seriesOverrides.goldenMetric('/aggregated /', { linewidth: 2 },)),

  componentSaturationPanel(component, selector)::
    local formatConfig = {
      component: component,
      selector: selector,
    };
    local componentDetails = saturationResources[component];
    local query = componentDetails.getQuery(selector, '$__interval', maxAggregationLabels=componentDetails.resourceLabels);

    self.saturationPanel(
      '%s component saturation: %s' % [component, componentDetails.title],
      description=componentDetails.description + ' Lower is better.',
      component=component,
      linewidth=1,
      query=query,
      legendFormat=componentDetails.getLegendFormat(),
      selector=selector,
    ),

  saturationDetailPanels(selector, components)::
    row.new(title='🌡 Saturation Details', collapse=true)
    .addPanels(layout.grid([
      self.componentSaturationPanel(component, selector)
      for component in components
    ])),

  componentSaturationHelpPanel(component)::
    local componentDetails = saturationResources[component];

    text.new(
      title='Help',
      mode='markdown',
      content=componentDetails.description + |||
        * [Find related issues on GitLab.com](%s)
      ||| % [
        issueSearch.buildInfraIssueSearch(labels=['GitLab.com Resource Saturation'], search=component),
      ]
    ),
}
