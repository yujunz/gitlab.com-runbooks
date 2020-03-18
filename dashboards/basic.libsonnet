local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local graphPanel = grafana.graphPanel;
local grafana = import 'grafonnet/grafana.libsonnet';
local heatmapPanel = grafana.heatmapPanel;
local row = grafana.row;
local text = grafana.text;
local seriesOverrides = import 'series_overrides.libsonnet';
local singlestatPanel = grafana.singlestat;
local tablePanel = grafana.tablePanel;
local timepickerlib = import 'grafonnet/timepicker.libsonnet';
local templates = import 'templates.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';

local panelMethods = {
  addDataLink(datalink):: self + {
    options+: {
      dataLinks+: [datalink],
    },
  },
};

{
  dashboard(
    title,
    tags,
    editable=false,
    time_from='now-6h/m',
    time_to='now/m',
    refresh='',
    timepicker=timepickerlib.new(),
    graphTooltip='shared_crosshair',
    hideControls=false,
    description=null,
    includeStandardEnvironmentAnnotations=true,
    includeEnvironmentTemplate=true,
  )::
    local dashboard =
      grafana.dashboard.new(
        title,
        style='light',
        schemaVersion=16,
        tags=tags,
        timezone='utc',
        graphTooltip=graphTooltip,
        editable=editable,
        refresh=refresh,
        hideControls=false,
        description=null,
        time_from=time_from,
        time_to=time_to,
      )
      .addTemplate(templates.ds);  // All dashboards include the `ds` variable

    local dashboardWithAnnotations = if includeStandardEnvironmentAnnotations then
      dashboard
      .addAnnotation(commonAnnotations.deploymentsForEnvironment)
      .addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
      .addAnnotation(commonAnnotations.featureFlags)
    else
      dashboard;

    local dashboardWithEnvTemplate = if includeEnvironmentTemplate then
      dashboardWithAnnotations
      .addTemplate(templates.environment)
    else
      dashboardWithAnnotations;

    dashboardWithEnvTemplate {
      trailer()::
        self.addPanel(
          text.new(
            title='Source',
            mode='markdown',
            content=|||
              Made with ❤️ and [Grafonnet](https://github.com/grafana/grafonnet-lib). [Contribute to this dashboard on GitLab.com](https://gitlab.com/gitlab-com/runbooks/blob/master/dashboards/%(filePath)s)
            ||| % { filePath: std.extVar('dashboardPath') },
          ),
          gridPos={
            x: 0,
            y: 110000,
            w: 24,
            h: 2,
          }
        ),
    },

  heatmap(
    title='Heatmap',
    description='',
    query='',
    legendFormat='',
    format='short',
    interval='1m',
    intervalFactor=3,
    yAxisLabel='',
    legend_show=true,
    linewidth=2
  )::
    heatmapPanel.new(
      title,
      description=description,
      datasource='$PROMETHEUS_DS',
      legend_show=false,
      yAxis_format='s',
      color_mode='opacity',
    )
    .addTarget(promQuery.target(query, legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
    + panelMethods,

  singlestat(
    title='SingleStat',
    description='',
    query='',
    colors=[
      '#299c46',
      'rgba(237, 129, 40, 0.89)',
      '#d44a3a',
    ],
    legendFormat='',
    format='percentunit',
    gaugeMinValue=0,
    gaugeMaxValue=100,
    gaugeShow=false,
    instant=true,
    interval='1m',
    intervalFactor=3,
    postfix=null,
    thresholds='',
    yAxisLabel='',
    legend_show=true,
    linewidth=2,
    valueName='current',
  )::
    singlestatPanel.new(
      title,
      description=description,
      datasource='$PROMETHEUS_DS',
      colors=colors,
      format=format,
      gaugeMaxValue=gaugeMaxValue,
      gaugeShow=gaugeShow,
      postfix=postfix,
      thresholds=thresholds,
      valueName=valueName,
    )
    .addTarget(promQuery.target(query, instant)) +
    panelMethods,

  table(
    title='Table',
    description='',
    span=null,
    min_span=null,
    styles=[],
    columns=[],
  )::
    tablePanel.new(
      title,
      description=description,
      span=span,
      min_span=min_span,
      datasource='$PROMETHEUS_DS',
      styles=[],
      columns=[],
    ) +
    panelMethods,

  multiTimeseries(
    title='Multi timeseries',
    description='',
    queries=[],
    format='short',
    interval='1m',
    intervalFactor=3,
    yAxisLabel='',
    sort='decreasing',
    legend_show=true,
    legend_rightSide=false,
    linewidth=2,
    max=null,
    decimals=0
  )::
    local panel = graphPanel.new(
      title,
      description=description,
      sort=sort,
      linewidth=linewidth,
      fill=0,
      datasource='$PROMETHEUS_DS',
      decimals=decimals,
      legend_rightSide=legend_rightSide,
      legend_show=legend_show,
      legend_values=true,
      legend_min=true,
      legend_max=true,
      legend_current=true,
      legend_total=false,
      legend_avg=true,
      legend_alignAsTable=true,
      legend_hideEmpty=true,
    );

    local addPanelTarget(panel, query) =
      panel.addTarget(promQuery.target(query.query, legendFormat=query.legendFormat, interval=interval, intervalFactor=intervalFactor));

    std.foldl(addPanelTarget, queries, panel)
    .resetYaxes()
    .addYaxis(
      format=format,
      min=0,
      max=max,
      label=yAxisLabel,
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ) +
    panelMethods,

  timeseries(
    title='Timeseries',
    description='',
    query='',
    legendFormat='',
    format='short',
    interval='1m',
    intervalFactor=3,
    yAxisLabel='',
    sort='decreasing',
    legend_show=true,
    legend_rightSide=false,
    linewidth=2,
    max=null,
  )::
    self.multiTimeseries(
      queries=[{ query: query, legendFormat: legendFormat }],
      title=title,
      description=description,
      format=format,
      interval=interval,
      intervalFactor=intervalFactor,
      yAxisLabel=yAxisLabel,
      sort=sort,
      legend_show=legend_show,
      legend_rightSide=legend_rightSide,
      linewidth=linewidth,
      max=max,
    ),

  queueLengthTimeseries(
    title='Timeseries',
    description='',
    query='',
    legendFormat='',
    format='short',
    interval='1m',
    intervalFactor=3,
    yAxisLabel='Queue Length',
    linewidth=2,
  )::
    graphPanel.new(
      title,
      description=description,
      sort='decreasing',
      linewidth=linewidth,
      fill=0,
      datasource='$PROMETHEUS_DS',
      decimals=0,
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
    .addTarget(promQuery.target(query, legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
    .resetYaxes()
    .addYaxis(
      format=format,
      min=0,
      label=yAxisLabel,
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ) +
    panelMethods,

  percentageTimeseries(
    title,
    description='',
    query='',
    legendFormat='',
    yAxisLabel='Percent',
    interval='1m',
    intervalFactor=3,
    linewidth=2,
    legend_show=true,
    min=null,
    max=null,
    decimals=0,
  )::
    local formatConfig = {
      query: query,
    };
    graphPanel.new(
      title,
      description=description,
      sort='decreasing',
      linewidth=linewidth,
      fill=0,
      datasource='$PROMETHEUS_DS',
      decimals=decimals,
      legend_show=legend_show,
      legend_values=true,
      legend_min=true,
      legend_max=true,
      legend_current=true,
      legend_total=false,
      legend_avg=true,
      legend_alignAsTable=true,
      legend_hideEmpty=true,
    )
    .addTarget(
      promQuery.target(
        |||
          clamp_min(clamp_max(%(query)s,1),0)
        ||| % formatConfig,
        legendFormat=legendFormat,
        interval=interval,
        intervalFactor=intervalFactor
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      min=min,
      max=max,
      label=yAxisLabel,
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ) +
    panelMethods,

  saturationTimeseries(
    title='Saturation',
    description='',
    query='',
    legendFormat='',
    yAxisLabel='Saturation',
    interval='1m',
    intervalFactor=3,
    linewidth=2,
    legend_show=true,
    min=0,
    max=1,
  )::
    self.percentageTimeseries(
      title=title,
      description=description,
      query=query,
      legendFormat=legendFormat,
      yAxisLabel=yAxisLabel,
      interval=interval,
      intervalFactor=intervalFactor,
      linewidth=linewidth,
      legend_show=legend_show,
      min=min,
      max=max,
    ) +
    panelMethods,

  apdexTimeseries(
    title='Apdex',
    description='Apdex is a measure of requests that complete within an acceptable threshold duration. Actual threshold vary per service or endpoint. Higher is better.',
    query='',
    legendFormat='',
    yAxisLabel='% Requests w/ Satisfactory Latency',
    interval='1m',
    intervalFactor=3,
    linewidth=2,
    min=null,
    legend_show=true,
  )::
    local formatConfig = {
      query: query,
    };
    graphPanel.new(
      title,
      description=description,
      sort='increasing',
      linewidth=linewidth,
      fill=0,
      datasource='$PROMETHEUS_DS',
      decimals=0,
      legend_show=legend_show,
      legend_values=true,
      legend_min=true,
      legend_max=true,
      legend_current=true,
      legend_total=false,
      legend_avg=true,
      legend_alignAsTable=true,
      legend_hideEmpty=true,
    )
    .addTarget(
      promQuery.target(
        |||
          clamp_min(clamp_max(%(query)s,1),0)
        ||| % formatConfig,
        legendFormat=legendFormat,
        interval=interval,
        intervalFactor=intervalFactor
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      min=min,
      max=1,
      label=yAxisLabel,
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ) +
    panelMethods,

  latencyTimeseries(
    title='Latency',
    description='',
    query='',
    legendFormat='',
    format='s',
    yAxisLabel='Duration',
    interval='1m',
    intervalFactor=3,
    legend_show=true,
    logBase=1,
    decimals=2,
    linewidth=2,
    min=0,
  )::
    graphPanel.new(
      title,
      description=description,
      sort='decreasing',
      linewidth=linewidth,
      fill=0,
      datasource='$PROMETHEUS_DS',
      decimals=decimals,
      legend_show=legend_show,
      legend_values=true,
      legend_min=true,
      legend_max=true,
      legend_current=true,
      legend_total=false,
      legend_avg=true,
      legend_alignAsTable=true,
      legend_hideEmpty=true,
    )
    .addTarget(promQuery.target(query, legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
    .resetYaxes()
    .addYaxis(
      format=format,
      min=min,
      label=yAxisLabel,
      logBase=logBase,
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ) + panelMethods,

  slaTimeseries(
    title='SLA',
    description='',
    query='',
    legendFormat='',
    yAxisLabel='SLA',
    interval='1m',
    intervalFactor=3,
    points=false,
    pointradius=3,
  )::
    local formatConfig = {
      query: query,
    };
    graphPanel.new(
      title,
      description=description,
      sort='decreasing',
      linewidth=2,
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
      points=points,
      pointradius=pointradius,
    )
    .addTarget(
      promQuery.target(
        |||
          clamp_min(clamp_max(%(query)s,1),0)
        ||| % formatConfig,
        legendFormat=legendFormat,
        interval=interval,
        intervalFactor=intervalFactor,
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label=yAxisLabel,
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ) +
    panelMethods,

  networkTrafficGraph(
    title='Node Network Utilization',
    description='Network utilization',
    sendQuery,
    legendFormat='{{ fqdn }}',
    receiveQuery,
    intervalFactor=3,
    legend_show=true
  )::
    graphPanel.new(
      title,
      linewidth=1,
      fill=0,
      description=description,
      datasource='$PROMETHEUS_DS',
      decimals=2,
      sort='decreasing',
      legend_show=legend_show,
      legend_values=false,
      legend_alignAsTable=false,
      legend_hideEmpty=true,
    )
    .addSeriesOverride(seriesOverrides.networkReceive)
    .addTarget(
      promQuery.target(
        sendQuery,
        legendFormat='send ' + legendFormat,
        intervalFactor=intervalFactor,
      )
    )
    .addTarget(
      promQuery.target(
        receiveQuery,
        legendFormat='receive ' + legendFormat,
        intervalFactor=intervalFactor,
      )
    )
    .resetYaxes()
    .addYaxis(
      format='Bps',
      label='Network utilization',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ) +
    panelMethods,

  slaStats(
    title,
    description='Availability',
    query,
    fieldTitle='',
    legendFormat='',
    links=[],
  )::
    {
      datasource: '$PROMETHEUS_DS',
      targets: [promQuery.target(query, legendFormat=legendFormat, instant=true)],
      title: title,
      type: 'stat',
      pluginVersion: '6.6.1',
      options: {
        graphMode: 'none',
        colorMode: 'background',
        justifyMode: 'auto',
        fieldOptions: {
          values: true,
          calcs: [
            'last',
          ],
          defaults: {
            thresholds: {
              mode: 'absolute',
              steps: [
                {
                  color: 'red',
                  value: null,
                },
                {
                  value: 0.95,
                  color: 'light-red',
                },
                {
                  value: 0.99,
                  color: 'orange',
                },
                {
                  value: 0.995,
                  color: 'light-orange',
                },
                {
                  value: 0.9994,
                  color: 'yellow',
                },
                {
                  value: 0.9995,
                  color: 'light-yellow',
                },
                {
                  value: 0.9998,
                  color: 'green',
                },
              ],
            },
            mappings: [],
            decimals: 2,
            max: 1,
            min: 0,
            title: fieldTitle,
            unit: 'percentunit',
            color: {
              mode: 'thresholds',
            },
            links: links,
          },
          overrides: [],
          thresholds: [
            {
              color: 'green',
              index: 0,
              value: null,
            },
          ],
        },
        orientation: 'auto',
      },
    } +
    panelMethods,


  // This is a useful hack for displaying a label value in a stat panel
  labelStat(
    query,
    title,
    panelTitle,
    color,
    legendFormat,
    links=[],
  )::
    {
      type: 'stat',
      title: panelTitle,
      targets: [promQuery.target(query, legendFormat=legendFormat, instant=true)],
      pluginVersion: '6.6.1',
      links: [],
      options: {
        graphMode: 'none',
        colorMode: 'background',
        justifyMode: 'auto',
        fieldOptions: {
          values: false,
          calcs: [
            'lastNotNull',
          ],
          defaults: {
            thresholds: {
              mode: 'absolute',
              steps: [
                {
                  value: null,
                  color: color,
                },
              ],
            },
            mappings: [
              {
                value: 'null',
                op: '=',
                text: title,
                id: 0,
                type: 2,
                from: '-10000000',
                to: '10000000',
              },
            ],
            unit: 'none',
            nullValueMode: 'connected',
            title: '${__field.name}',
            links: links,
          },
          overrides: [],
        },
        orientation: 'vertical',
      },
    },
}
