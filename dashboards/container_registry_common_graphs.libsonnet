local basic = import 'basic.libsonnet';
local layout = import 'layout.libsonnet';

{
  logMessages(startRow):: layout.grid([
    basic.timeseries(
      title='Log messages with severity ERROR',
      query='sum(stackdriver_gke_container_logging_googleapis_com_log_entry_count{severity="ERROR", cluster_name="$cluster", namespace_id="$namespace"}) / 60',
      legendFormat='ERROR msgs per second',
    ),
    basic.timeseries(
      title='Log messages with severity INFO',
      query='sum(stackdriver_gke_container_logging_googleapis_com_log_entry_count{severity="INFO", cluster_name="$cluster", namespace_id="$namespace"}) / 60',
      legendFormat='INFO msgs per second',
    ),
  ], cols=2, rowHeight=5, startRow=startRow),

  generalCounters(startRow):: layout.grid([
    basic.timeseries(
      title='Registry Process CPU Time',
      query='rate(process_cpu_seconds_total{job=~".*registry.*", cluster="$cluster", namespace="$namespace"}[$__interval])',
      legendFormat='{{ pod }}',
    ),
    basic.timeseries(
      title='Resident Memory Usage',
      query='process_resident_memory_bytes{job=~".*registry.*", cluster="$cluster", namespace="$namespace"}',
      legendFormat='{{ pod }}',
    ),
    basic.timeseries(
      title='Open File Descriptors',
      query='process_open_fds{job=~".*registry.*", cluster="$cluster", namespace="$namespace"}',
      legendFormat='{{ pod }}',
    ),
  ], cols=3, rowHeight=10, startRow=startRow),

  data(startRow):: layout.grid([
    basic.timeseries(
      title='HTTP Requests',
      query='sum(irate(registry_http_requests_total{cluster="$cluster", namespace="$namespace"}[1m])) by (handler, code)',
      legendFormat='{{ handler }}: {{ code }}',
    ),
    basic.timeseries(
      title='In-Flight HTTP Requests',
      query='sum(irate(registry_http_in_flight_requests{cluster="$cluster", namespace="$namespace"}[1m])) by (handler, code)',
      legendFormat='{{ handler }}',
    ),
    basic.timeseries(
      title='Registry Action Latency',
      query='avg(increase(registry_storage_action_seconds_sum{job=~".*registry.*", cluster="$cluster", namespace="$namespace"}[$__interval])) by (action)',
      legendFormat='{{ action }}',
    ),
    basic.timeseries(
      title='Cache Requests Rate',
      query='sum(irate(registry_storage_cache_total{cluster="$cluster", namespace="$namespace"}[1m])) by (type)',
      legend_show=false,
    ),
    basic.singlestat(
      title='Cache Hit %',
      query='sum(rate(registry_storage_cache_total{cluster="$cluster", environment="$environment", namespace="$namespace",exported_type="Hit"}[$__interval])) / sum(rate(registry_storage_cache_total{environment="$environment",exported_type="Request"}[$__interval]))',
      colors=[
        '#d44a3a',
        'rgba(237, 129, 40, 0.89)',
        '#299c46',
      ],
      gaugeMaxValue=1,
      gaugeShow=true,
      thresholds='0.5,0.75',
    ),
  ], cols=2, rowHeight=10, startRow=startRow),

  latencies(startRow):: layout.grid([
    basic.heatmap(
      title='manifest',
      query='rate(registry_http_request_duration_seconds_bucket{handler="manifest",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob_upload_chunk',
      query='rate(registry_http_request_duration_seconds_bucket{handler="blob_upload_chunk", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob',
      query='rate(registry_http_request_duration_seconds_bucket{handler="blob",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='base',
      query='rate(registry_http_request_duration_seconds_bucket{handler="base",cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='tags',
      query='rate(registry_http_request_duration_seconds_bucket{handler="tags", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
    basic.heatmap(
      title='blob_upload',
      query='rate(registry_http_request_duration_seconds_bucket{handler="blob_upload", cluster="$cluster", namespace="$namespace"}[10m])',
    ),
  ], cols=3, rowHeight=10, startRow=startRow),
}