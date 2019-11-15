local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local graphPanel = grafana.graphPanel;
local grafana = import 'grafonnet/grafana.libsonnet';
local row = grafana.row;
local seriesOverrides = import 'series_overrides.libsonnet';

{
  nodeMetricsDetailRow(nodeSelector)::
    local formatConfig = {
      nodeSelector: nodeSelector,
    };
    row.new(title='🖥️ Node Metrics', collapse=true)
    .addPanels(layout.grid([
      graphPanel.new(
        'Node CPU',
        linewidth=1,
        fill=0,
        description='The amount of non-idle time consumed by nodes for this service',
        datasource='$PROMETHEUS_DS',
        decimals=2,
        sort='decreasing',
        legend_show=false,
        legend_values=false,
        legend_alignAsTable=false,
        legend_hideEmpty=true,
      )
      .addTarget(  // Primary metric
        promQuery.target(
          |||
            avg(instance:node_cpu_utilization:ratio{%(nodeSelector)s}) by (fqdn)
          ||| % formatConfig,
          legendFormat='{{ fqdn }}',
          intervalFactor=5,
        )
      )
      .resetYaxes()
      .addYaxis(
        format='percentunit',
        label='Average CPU Utilization',
      )
      .addYaxis(
        format='short',
        max=1,
        min=0,
        show=false,
      ),
      basic.saturationTimeseries(
        'Node Maximum Single Core Utilization',
        description='The maximum utilization of a single core on each node. Lower is better',
        query=
        |||
          max(1 - rate(node_cpu_seconds_total{%(nodeSelector)s, mode="idle"}[$__interval])) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        legend_show=false,
        linewidth=1
      ),

      graphPanel.new(
        'Node Network Utilization',
        linewidth=1,
        fill=0,
        description='Network utilization for nodes for this service',
        datasource='$PROMETHEUS_DS',
        decimals=2,
        sort='decreasing',
        legend_show=false,
        legend_values=false,
        legend_alignAsTable=false,
        legend_hideEmpty=true,
      )
      .addSeriesOverride(seriesOverrides.networkReceive)
      .addTarget(
        promQuery.target(
          |||
            sum(rate(node_network_transmit_bytes_total{%(nodeSelector)s}[$__interval])) by (fqdn)
          ||| % formatConfig,
          legendFormat='send {{ fqdn }}',
          intervalFactor=5,
        )
      )
      .addTarget(
        promQuery.target(
          |||
            sum(rate(node_network_receive_bytes_total{%(nodeSelector)s}[$__interval])) by (fqdn)
          ||| % formatConfig,
          legendFormat='receive {{ fqdn }}',
          intervalFactor=5,
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
      basic.saturationTimeseries(
        title='Memory Utilization',
        description='Memory utilization. Lower is better.',
        query=
        |||
          instance:node_memory_utilization:ratio{%(nodeSelector)s}
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='1m',
        intervalFactor=1,
        legend_show=false,
        linewidth=1
      ),

      // Node-level disk metrics
      // Reads on the left, writes on the right
      //
      // IOPS ---------------
      basic.timeseries(
        title='Disk Read IOPs',
        description='Disk Read IO operations per second. Lower is better.',
        query=
        |||
          max(
            rate(node_disk_reads_completed_total{%(nodeSelector)s}[$__interval])
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='ops',
        interval='1m',
        intervalFactor=1,
        yAxisLabel='Operations/s',
        legend_show=false,
        linewidth=1
      ),
      basic.timeseries(
        title='Disk Write IOPs',
        description='Disk Write IO operations per second. Lower is better.',
        query=
        |||
          max(
            rate(node_disk_writes_completed_total{%(nodeSelector)s}[$__interval])
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='ops',
        interval='1m',
        intervalFactor=1,
        yAxisLabel='Operations/s',
        legend_show=false,
        linewidth=1
      ),
      // Disk Throughput ---------------
      basic.timeseries(
        title='Disk Read Throughput',
        description='Disk Read throughput datarate. Lower is better.',
        query=
        |||
          max(
            rate(node_disk_read_bytes_total{%(nodeSelector)s}[$__interval])
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='Bps',
        interval='1m',
        intervalFactor=1,
        yAxisLabel='Bytes/s',
        legend_show=false,
        linewidth=1
      ),
      basic.timeseries(
        title='Disk Write Throughput',
        description='Disk Write throughput datarate. Lower is better.',
        query=
        |||
          max(
            rate(node_disk_written_bytes_total{%(nodeSelector)s}[$__interval])
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='Bps',
        interval='1m',
        intervalFactor=1,
        yAxisLabel='Bytes/s',
        legend_show=false,
        linewidth=1
      ),
      // Disk Total Time ---------------
      basic.timeseries(
        title='Disk Read Total Time',
        description='Total time spent in read operations across all disks on the node. Lower is better.',
        query=
        |||
          sum(
            rate(node_disk_read_time_seconds_total{%(nodeSelector)s}[$__interval])
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='s',
        interval='30s',
        intervalFactor=1,
        yAxisLabel='Total Time/s',
        legend_show=false,
        linewidth=1
      ),
      basic.timeseries(
        title='Disk Write Total Time',
        description='Total time spent in write operations across all disks on the node. Lower is better.',
        query=
        |||
          sum(
            rate(node_disk_write_time_seconds_total{%(nodeSelector)s}[$__interval])
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        format='s',
        interval='30s',
        intervalFactor=1,
        yAxisLabel='Total Time/s',
        legend_show=false,
        linewidth=1
      ),
    ])),
}
