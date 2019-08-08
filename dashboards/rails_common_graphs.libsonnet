local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';

{
  railsPanels(serviceType, serviceStage, startRow):: layout.grid([
    basic.latencyTimeseries(
      title="p95 Latency Estimate",
      description="95th percentile Latency. Lower is better",
      query='
        histogram_quantile(0.90,
          sum(job_environment:gitlab_transaction_duration_seconds_bucket:rate5m{
            environment="$environment",
            type="' + serviceType + '",
            stage="' + serviceStage + '"
          }) by (le, job)
        )
      ',
      legendFormat='{{ job }}',
      format="s",
      min=0.05,
      yAxisLabel='Latency',
      interval="1m",
      intervalFactor=1,
      logBase=10),
    basic.timeseries(
      title="Rails Total Time",
      description="Seconds of Rails processing, per second",
      query='
        sum(
          job_environment:gitlab_transaction_duration_seconds_sum:rate1m{
            environment="$environment",
            type="' + serviceType + '",
            stage="' + serviceStage + '"}
        ) by (job)
      ',
      legendFormat='{{ job }}',
      interval="1m",
      intervalFactor=2,
      format='s',
      legend_show=true,
    ),
    basic.timeseries(
      title="Rails Queue Time",
      description="Time spend waiting for a rails worker",
      query='
        sum(
          rate(
            gitlab_transaction_rails_queue_duration_total{
              environment="$environment",
              type="' + serviceType + '",
              stage="' + serviceStage + '"}
              [$__interval]
          )
        ) by (job)
      ',
      legendFormat='{{ job }}',
      interval="1m",
      intervalFactor=2,
      format='s',
      legend_show=true,
    ),
    basic.timeseries(
      title="Total SQL Time",
      description="Total seconds spent doing SQL processing, per second",
      query='
        sum(
          job_environment:gitlab_sql_duration_seconds_bucket:rate1m{
            environment="$environment",
            type="' + serviceType + '",
            stage="' + serviceStage + '"}
        ) by (job)
      ',
      legendFormat='{{ job }}',
      interval="1m",
      format='s',
      intervalFactor=5,
      legend_show=true,
    ),
    basic.timeseries(
      title="Cache Operations",
      description="Cache Operations per Second",
      query='
        sum(
          rate(
            gitlab_cache_operations_total{
              environment="$environment",
              type="' + serviceType + '",
              stage="' + serviceStage + '"}[$__interval]
          )
        ) by (job)
      ',
      legendFormat='{{ job }}',
      interval="1m",
      intervalFactor=10, // High interval as we don't have a recording rule yet
      legend_show=true,
    ),
  ], cols=2,rowHeight=10, startRow=startRow),

}
