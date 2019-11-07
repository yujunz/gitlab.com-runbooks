local basic = import 'basic.libsonnet';
local colors = import 'colors.libsonnet';
local layout = import 'layout.libsonnet';

{
  logMessages(startRow):: layout.grid([
    basic.timeseries(
      title='Log messages with severity ERROR',
      query='sum(stackdriver_gke_container_logging_googleapis_com_log_entry_count{severity="ERROR", pod_id=~"^$Deployment.*", cluster_name="$cluster", namespace_id="$namespace"}) / 60',
      legendFormat='ERROR msgs per second',
    ),
    basic.timeseries(
      title='Log messages with severity INFO',
      query='sum(stackdriver_gke_container_logging_googleapis_com_log_entry_count{severity="INFO", pod_id=~"^$Deployment.*", cluster_name="$cluster", namespace_id="$namespace"}) / 60',
      legendFormat='INFO msgs per second',
    ),
  ], cols=2, rowHeight=5, startRow=startRow),

  generalCounters(startRow):: layout.grid([
    basic.timeseries(
      title='Registry Process CPU Time',
      query='rate(process_cpu_seconds_total{service=~"^$Deployment.*", cluster="$cluster", namespace="$namespace"}[$__interval])',
      legendFormat='{{ pod }}',
    ),
    basic.timeseries(
      title='Resident Memory Usage',
      query='process_resident_memory_bytes{service=~"^$Deployment.*", cluster="$cluster", namespace="$namespace"}',
      legendFormat='{{ pod }}',
    ),
    basic.timeseries(
      title='Open File Descriptors',
      query='process_open_fds{service=~"^$Deployment.*", cluster="$cluster", namespace="$namespace"}',
      legendFormat='{{ pod }}',
    ),
  ], cols=3, rowHeight=10, startRow=startRow),
}
