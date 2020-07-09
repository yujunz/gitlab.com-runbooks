local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local serviceDashboard = import 'service_dashboard.libsonnet';
local row = grafana.row;

local trafficPanel() =
  basic.timeseries(
    'Traffic',
    description='Traffic, in bytes per second',
    query='sum(rate(camo_response_size_bytes_sum{environment="$environment"}[$__interval]))',
    format='B'
  );

local eventPanel() =
  basic.timeseries(
    'Request Failures',
    description='Failed requests',
    query='sum(rate(camo_proxy_reponses_failed_total{environment="$environment"}[$__interval]))',
    legendFormat='Failed Requests',
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camo_proxy_content_length_exceeded_total{environment="$environment"}[$__interval]))',
      legendFormat='Content Length Exceeded - --max-size exceeded',
    )
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camo_proxy_reponses_truncated_total{environment="$environment"}[$__interval]))',
      legendFormat='Response Truncated - --max-size exceeded',
    )
  )
  .addTarget(
    promQuery.target(
      'sum(rate(camo_responses_total{environment="$environment",code="504"}[$__interval]))',
      legendFormat='504 - Gateway Timeout - maybe --timeout exceeded',
    )
  );


serviceDashboard.overview('camoproxy', 'sv')
.addPanel(row.new(title='Workhorse'), gridPos={ x: 0, y: 1000, w: 24, h: 1 })
.addPanels(layout.grid([
  trafficPanel(),
  eventPanel(),
], cols=2, rowHeight=10, startRow=1000))
.overviewTrailer()
