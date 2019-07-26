local grafana = import 'grafonnet/grafana.libsonnet';

{
  generalGraphPanel(
      title,
      description=null
    ):: grafana.graphPanel.new(
        title,
        description=description,
        linewidth=1,
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
      ),

  generalBytesGraphPanel(
      title,
      description = null
    ):: self.generalGraphPanel(
      title,
      description=null,
    )
    .resetYaxes()
    .addYaxis(
      format='bytes',
      label="Size",
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  generalPercentageGraphPanel(
      title,
      description = null
    ):: self.generalGraphPanel(
      title,
      description=null,
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label=title,
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    )
}
