local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local graphPanel = grafana.graphPanel;
local grafana = import 'grafonnet/grafana.libsonnet';
local row = grafana.row;
local seriesOverrides = import 'series_overrides.libsonnet';

{
  nodeMetricsDetailRow(nodeSelector)::
    row.new(title="🖥️ Node Metrics", collapse=true)
    .addPanel(
      graphPanel.new(
        "Node CPU",
        linewidth=1,
        fill=0,
        description="The amount of non-idle time consumed by nodes for this service",
        datasource="$PROMETHEUS_DS",
        decimals=2,
        sort="decreasing",
        legend_show=false,
        legend_values=false,
        legend_alignAsTable=false,
        legend_hideEmpty=true,
      )
      .addTarget( // Primary metric
          promQuery.target('
            avg(instance:node_cpu_utilization:ratio{' + nodeSelector + '}) by (fqdn)
            ',
            legendFormat='{{ fqdn }}',
            intervalFactor=5,
          )
        )
        .resetYaxes()
        .addYaxis(
          format='percentunit',
          label="Average CPU Utilization",
        )
        .addYaxis(
          format='short',
          max=1,
          min=0,
          show=false,
        ),
      gridPos={
        x: 0,
        y: 0,
        w: 12,
        h: 10,
      }
    )
    .addPanel(
      graphPanel.new(
        "Node Network Utilization",
        linewidth=1,
        fill=0,
        description="Network utilization for nodes for this service",
        datasource="$PROMETHEUS_DS",
        decimals=2,
        sort="decreasing",
        legend_show=false,
        legend_values=false,
        legend_alignAsTable=false,
        legend_hideEmpty=true,
      )
      .addSeriesOverride(seriesOverrides.networkReceive)
      .addTarget(
        promQuery.target('
          sum(rate(node_network_transmit_bytes_total{' + nodeSelector + '}[$__interval])) by (fqdn)
          ',
          legendFormat='send {{ fqdn }}',
          intervalFactor=5,
        )
      )
      .addTarget(
        promQuery.target('
          sum(rate(node_network_receive_bytes_total{' + nodeSelector + '}[$__interval])) by (fqdn)
          ',
          legendFormat='receive {{ fqdn }}',
          intervalFactor=5,
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
      ),
      gridPos={
        x: 12,
        y: 0,
        w: 12,
        h: 10,
      }
    )


}
