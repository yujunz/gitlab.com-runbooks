local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local serviceDashboard = import 'service_dashboard.libsonnet';
local row = grafana.row;
local basic = import 'basic.libsonnet';

serviceDashboard.overview('nfs', 'stor')
.addPanel(
  row.new(title='NFS Client Activity'),
  gridPos={ x: 0, y: 1000, w: 24, h: 1 }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Total NFS read throughput per service-shard',
      description='The total number of jobs in the system queued up to be executed. Lower is better.',
      query=|||
        sum by (type, shard, export) (rate(node_mountstats_nfs_total_read_bytes_total{environment="$environment"}[$__interval]))
      |||,
      legendFormat='{{ type }} {{ shard }} shard - {{ export }}',
      format='bytes',
      yAxisLabel='Read Bytes/second',
    ),
    basic.timeseries(
      title='Total NFS writes throughput per service-shard',
      description='The total number of jobs in the system queued up to be executed. Lower is better.',
      query=|||
        sum by (type, shard, export) (rate(node_mountstats_nfs_total_write_bytes_total{environment="$environment"}[$__interval]))
      |||,
      legendFormat='{{ type }} {{ shard }} shard - {{ export }}',
      format='bytes',
      yAxisLabel='Write Bytes/second',
    ),
  ], cols=1, startRow=1001)
)
.overviewTrailer()
