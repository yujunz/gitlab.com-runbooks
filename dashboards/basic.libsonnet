local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local graphPanel = grafana.graphPanel;
local grafana = import 'grafonnet/grafana.libsonnet';
local row = grafana.row;
local seriesOverrides = import 'series_overrides.libsonnet';

{
  timeseries(
    title="Timeseries",
    description="",
    query="",
    legendFormat='',
    format='short',
    interval="1m",
    intervalFactor=3,
    yAxisLabel='',
    legend_show=true,
    linewidth=2
    ):: graphPanel.new(
    title,
    description=description,
    sort="decreasing",
    linewidth=linewidth,
    fill=0,
    datasource="$PROMETHEUS_DS",
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
    title="Timeseries",
    description="",
    query="",
    legendFormat='',
    format='short',
    interval="1m",
    intervalFactor=3,
    yAxisLabel='Queue Length',
    linewidth=2,
    ):: graphPanel.new(
    title,
    description=description,
    sort="decreasing",
    linewidth=linewidth,
    fill=0,
    datasource="$PROMETHEUS_DS",
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
    title="Saturation",
    description="",
    query="",
    legendFormat='',
    yAxisLabel='Saturation',
    interval="1m",
    intervalFactor=3,
    linewidth=2,
    legend_show=true,
    ):: graphPanel.new(
    title,
    description=description,
    sort="decreasing",
    linewidth=linewidth,
    fill=0,
    datasource="$PROMETHEUS_DS",
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
    format="percentunit",
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
    title="Latency",
    description="",
    query="",
    legendFormat='',
    format="s",
    yAxisLabel='Duration',
    interval="1m",
    intervalFactor=3,
    legend_show=true,
    logBase=1,
    decimals=2,
    linewidth=2,
    min=0,
    ):: graphPanel.new(
    title,
    description=description,
    sort="decreasing",
    linewidth=linewidth,
    fill=0,
    datasource="$PROMETHEUS_DS",
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
    format="s",
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
    title="SLA",
    description="",
    query="",
    legendFormat='',
    yAxisLabel='SLA',
    interval="1m",
    intervalFactor=3,
    ):: graphPanel.new(
    title,
    description=description,
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
  .addTarget(promQuery.target('clamp_min(clamp_max(' + query + ',1),0)', legendFormat=legendFormat, interval=interval, intervalFactor=intervalFactor))
  .resetYaxes()
  .addYaxis(
    format="percentunit",
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
    title="Node Network Utilization",
    description="Network utilization",
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
        datasource="$PROMETHEUS_DS",
        decimals=2,
        sort="decreasing",
        legend_show=legend_show,
        legend_values=false,
        legend_alignAsTable=false,
        legend_hideEmpty=true,
      )
      .addSeriesOverride(seriesOverrides.networkReceive)
      .addTarget(
        promQuery.target(sendQuery,
          legendFormat='send ' + legendFormat,
          intervalFactor=intervalFactor,
        )
      )
      .addTarget(
        promQuery.target(receiveQuery,
          legendFormat='receive ' + legendFormat,
          intervalFactor=intervalFactor,
        )
      )
      .resetYaxes()
      .addYaxis(
        format='Bps',
        label="Network utilization",
      )
      .addYaxis(
        format='short',
        max=1,
        min=0,
        show=false,
      )
}
