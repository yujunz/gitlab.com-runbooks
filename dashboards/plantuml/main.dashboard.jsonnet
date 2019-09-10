local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;

local commonAnnotations = import 'common_annotations.libsonnet';
local templates = import 'templates.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local heatmapPanel = grafana.heatmapPanel;
local row = grafana.row;
local text = grafana.text;

dashboard.new(
  'Overview',
  schemaVersion=16,
  tags=['overview'],
  timezone='UTC',
  graphTooltip='shared_crosshair'
)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.gkeCluster)
.addTemplate(templates.projectId)
.addPanel(
  row.new(title='Stackdriver Logs'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Error messages',
      description='Stackdriver Errors',
      query='sum(stackdriver_gke_container_logging_googleapis_com_log_entry_count{severity="ERROR", cluster_name="$cluster", namespace_id="plantuml"}) by (container_name) / 60',
      legendFormat='{{ container_name }}',
      format='ops',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='Info messages',
      description='Stackdriver Errors',
      query='sum(stackdriver_gke_container_logging_googleapis_com_log_entry_count{severity="INFO", cluster_name="$cluster", namespace_id="plantuml"}) by (container_name) / 60',
      legendFormat='{{ container_name }}',
      format='ops',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),

  ], cols=2, rowHeight=10, startRow=1)
)
.addPanel(
  row.new(title='Stackdriver LoadBalancer'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='HTTP Requests CACHE HIT',
      description='HTTP Requests',
      query='sum(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count{cache_result!="MISS", project_id="$project_id", forwarding_rule_name=~".*plantuml.*"}) by (response_code) / 60',
      legendFormat='{{ response_code }}',
      format='ops',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='HTTP Requests bytes CACHE HIT',
      description='HTTP Requests',
      query='sum(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_request_bytes_count{cache_result!="MISS", project_id="$project_id", forwarding_rule_name=~".*plantuml.*"}) by (response_code)',
      legendFormat='{{ response_code }}',
      format='bytes',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='HTTP Requests CACHE MISS',
      description='HTTP Requests',
      query='sum(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count{cache_result="MISS", project_id="$project_id", forwarding_rule_name=~".*plantuml.*"}) by (response_code) / 60',
      legendFormat='{{ response_code }}',
      format='ops',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='HTTP Requests bytes CACHE MISS',
      description='HTTP Requests',
      query='sum(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_request_bytes_count{cache_result="MISS", project_id="$project_id", forwarding_rule_name=~".*plantuml.*"}) by (response_code)',
      legendFormat='{{ response_code }}',
      format='bytes',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
  ], cols=2, rowHeight=10, startRow=1001)
)

.addPanel(
  row.new(title='Stackdriver LoadBalancer Latencies'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='90th Percentile Latency CACHE MISS',
      description='90th Percentile Latency CACHE MISS',
      query='histogram_quantile(0.9,rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_latencies_bucket{cache_result="MISS", project_id="$project_id", forwarding_rule_name=~".*plantuml.*"}[10m]))',
      legendFormat='{{ response_code }}',
      format='ms',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='60th Percentile Latency CACHE MISS',
      description='60th Percentile Latency CACHE MISS',
      query='histogram_quantile(0.6,rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_latencies_bucket{cache_result="MISS", project_id="$project_id", forwarding_rule_name=~".*plantuml.*"}[10m]))',
      legendFormat='{{ response_code }}',
      format='ms',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='90th Percentile Latency CACHE HIT',
      description='90th Percentile Latency CACHE MISS',
      query='histogram_quantile(0.9,rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_latencies_bucket{cache_result="HIT", project_id="$project_id", forwarding_rule_name=~".*plantuml.*"}[10m]))',
      legendFormat='{{ response_code }}',
      format='ms',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
    basic.timeseries(
      title='60th Percentile Latency CACHE HIT',
      description='60th Percentile Latency CACHE MISS',
      query='histogram_quantile(0.6,rate(stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_backend_latencies_bucket{cache_result="HIT", project_id="$project_id", forwarding_rule_name=~".*plantuml.*"}[10m]))',
      legendFormat='{{ response_code }}',
      format='ms',
      interval='1m',
      intervalFactor=2,
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
  ], cols=2, rowHeight=10, startRow=2001)
)
