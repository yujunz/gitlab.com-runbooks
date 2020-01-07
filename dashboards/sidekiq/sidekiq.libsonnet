local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';

{
  priorityWorkloads(querySelector, startRow)::
    local formatConfig = {
      querySelector: querySelector,
    };

    layout.grid([
      basic.saturationTimeseries(
        title='Sidekiq Worker Saturation by Priority',
        description='Shows sidekiq worker saturation. Once saturated, all sidekiq workers will be busy processing jobs, and any new jobs that arrive will queue. Lower is better.',
        query=|||
          max by(environment, tier, type, stage) (
            sum by (fqdn, instance,  environment, tier, type, stage) (sidekiq_running_jobs{%(querySelector)s})
            /
            sum by (fqdn, instance,  environment, tier, type, stage) (sidekiq_concurrency{%(querySelector)s})
          )
        ||| % formatConfig,
        legendFormat='{{ priority }}',
        intervalFactor=1,
        linewidth=2,
      ),
      basic.saturationTimeseries(
        'Node Average CPU Utilization per Priority',
        description='The maximum utilization of a single core on each node. Lower is better',
        query=|||
          avg(1 - rate(node_cpu_seconds_total{%(querySelector)s, mode="idle"}[$__interval])) by (priority)
        ||| % formatConfig,
        legendFormat='{{ priority }}',
        legend_show=true,
        linewidth=2
      ),
      basic.saturationTimeseries(
        'Node Maximum Single Core Utilization per Priority',
        description='The maximum utilization of a single core on each node. Lower is better',
        query=|||
          max(1 - rate(node_cpu_seconds_total{%(querySelector)s, mode="idle"}[$__interval])) by (priority)
        ||| % formatConfig,
        legendFormat='{{ priority }}',
        legend_show=true,
        linewidth=2
      ),
      basic.saturationTimeseries(
        title='Maximum Memory Utilization per Priority',
        description='Memory utilization. Lower is better.',
        query=|||
          max by (priority) (
            instance:node_memory_utilization:ratio{%(querySelector)s}
          )
        ||| % formatConfig,
        legendFormat='{{ priority }}',
        interval='1m',
        intervalFactor=1,
        legend_show=true,
        linewidth=2
      ),

    ], cols=2, rowHeight=10, startRow=startRow),
}
