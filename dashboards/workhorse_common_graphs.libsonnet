local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';

{
  workhorsePanels(serviceType, serviceStage, startRow):: layout.grid([
    basic.latencyTimeseries(
      title="p50 Overall Latency Estimate",
      description="p50 Latency. Lower is better",
      query='
        histogram_quantile(
          0.5,
          sum(
            job:gitlab_workhorse_http_request_duration_seconds_bucket:rate1m{
              environment="$environment",
              type="' + serviceType + '",
              stage="' + serviceStage + '"}
          ) by (le))
      ',
      legendFormat='{{ method }} {{ route }}',
      format="s",
      min=0.001,
      yAxisLabel='Latency',
      interval="1m",
      intervalFactor=1,
      logBase=10),
    basic.latencyTimeseries(
      title="p90 Latency Estimate per Route",
      description="90th percentile Latency. Lower is better",
      query='
        label_replace(
          histogram_quantile(
            0.9,
            sum(
              job:gitlab_workhorse_http_request_duration_seconds_bucket:rate1m{
                environment="$environment",
                type="' + serviceType + '",
                stage="' + serviceStage + '"}
            ) by (route, le)),
        "route", "none", "route", "")
      ',
      legendFormat='{{ method }} {{ route }}',
      format="s",
      min=0.001,
      yAxisLabel='Latency',
      interval="1m",
      intervalFactor=1,
      logBase=10),
    basic.latencyTimeseries(
      title="p50 Latency Estimate per Route",
      description="Median Latency. Lower is better",
      query='
        label_replace(
          histogram_quantile(
            0.5,
            sum(
              job:gitlab_workhorse_http_request_duration_seconds_bucket:rate1m{
                environment="$environment",
                type="' + serviceType + '",
                stage="' + serviceStage + '"}
            ) by (route, le)),
        "route", "none", "route", "")
      ',
      legendFormat='{{ method }} {{ route }}',
      format="s",
      min=0.001,
      yAxisLabel='Latency',
      interval="1m",
      intervalFactor=1,
      logBase=10),
    basic.timeseries(
      title="Total Requests",
      description="Total Requests",
      query='
        sum(
          job:gitlab_workhorse_http_request_duration_seconds_bucket:rate1m{
              environment="$environment",
              type="' + serviceType + '",
              stage="' + serviceStage + '",
              le="+Inf"}
        )
      ',
      legendFormat='{{ code_class }}',
      interval="1m",
      intervalFactor=1,
    ),
    basic.timeseries(
      title="Requests by Status Class",
      description="Requests by Status Class",
      query='
        sum(
          label_replace(
            sum(
              job:gitlab_workhorse_http_request_duration_seconds_bucket:rate1m{
                  environment="$environment",
                  type="' + serviceType + '",
                  stage="' + serviceStage + '",
                  le="+Inf"}
            ) by (code),
          "code_class", "${1}XX", "code", "(.).*")
        ) by (code_class)
      ',
      legendFormat='{{ code_class }}',
      interval="1m",
      intervalFactor=1,
    ),
    basic.timeseries(
      title="Requests by Status Code",
      description="Requests by Status Code",
      query='
        sum(
          job:gitlab_workhorse_http_request_duration_seconds_bucket:rate1m{
              environment="$environment",
              type="' + serviceType + '",
              stage="' + serviceStage + '",
              le="+Inf"}
        ) by (code)
      ',
      legendFormat='{{ code }}',
      interval="1m",
      intervalFactor=1,
      legend_show=false,
    ),
    basic.timeseries(
      title="Requests by Route",
      description="Requests by Route",
      query='
        sum(
          label_replace(
            sum(
              job:gitlab_workhorse_http_request_duration_seconds_bucket:rate1m{
                  environment="$environment",
                  type="' + serviceType + '",
                  stage="' + serviceStage + '",
                  le="+Inf"}
            ) by (route),
          "route", "none", "route", "")
        ) by (route)
      ',
      legendFormat='{{ route }}',
      interval="1m",
      intervalFactor=1,
    ),
  ], cols=2,rowHeight=10, startRow=startRow),

}
