local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local graphPanel = grafana.graphPanel;
local grafana = import 'grafonnet/grafana.libsonnet';
local heatmapPanel = grafana.heatmapPanel;
local row = grafana.row;
local seriesOverrides = import 'series_overrides.libsonnet';
local singlestatPanel = grafana.singlestat;
local tablePanel = grafana.tablePanel;

{
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
  ):: heatmapPanel.new(
    title,
    description=description,
    datasource='$PROMETHEUS_DS',
    legend_show=false,
  )
      .addTarget(promQuery.target(query, legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor)),

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
  ):: singlestatPanel.new(
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
      .addTarget(promQuery.target(query, instant)),

  table(
    title='Table',
    description='',
    span=null,
    min_span=null,
    styles=[],
    columns=[],
  ):: tablePanel.new(
    title,
    description=description,
    span=span,
    min_span=min_span,
    datasource='$PROMETHEUS_DS',
    styles=[],
    columns=[],
  ),

  timeseries(
    title='Timeseries',
    description='',
    query='',
    legendFormat='',
    format='short',
    interval='1m',
    intervalFactor=3,
    yAxisLabel='',
    legend_show=true,
    legend_rightSide=false,
    linewidth=2
  ):: graphPanel.new(
    title,
    description=description,
    sort='decreasing',
    linewidth=linewidth,
    fill=0,
    datasource='$PROMETHEUS_DS',
    decimals=0,
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
  ):: graphPanel.new(
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
  ),

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
  ):: graphPanel.new(
    title,
    description=description,
    sort='decreasing',
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
      .addTarget(promQuery.target('clamp_min(clamp_max(' + query + ',1),0)', legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
      .resetYaxes()
      .addYaxis(
    format='percentunit',
    min=0,
    max=1,
    label=yAxisLabel,
  )
      .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  ),

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
  ):: graphPanel.new(
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
    format='s',
    min=min,
    label=yAxisLabel,
    logBase=logBase,
  )
      .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  ),

  slaTimeseries(
    title='SLA',
    description='',
    query='',
    legendFormat='',
    yAxisLabel='SLA',
    interval='1m',
    intervalFactor=3,
  ):: graphPanel.new(
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
  )
      .addTarget(promQuery.target('clamp_min(clamp_max(' + query + ',1),0)', legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
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
  ),

  networkTrafficGraph(
    title='Node Network Utilization',
    description='Network utilization',
    sendQuery,
    legendFormat='{{ fqdn }}',
    receiveQuery,
    intervalFactor=3,
    legend_show=true
  ):: graphPanel.new(
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
  ),
}
