local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local platformLinks = import 'platform_links.libsonnet';

{
  shardWorkloads(querySelector, startRow, datalink=null)::
    local formatConfig = {
      querySelector: querySelector,
    };

    local panels = [
      basic.saturationTimeseries(
        title='Sidekiq Worker Saturation by Shard',
        description='Shows sidekiq worker saturation. Once saturated, all sidekiq workers will be busy processing jobs, and any new jobs that arrive will queue. Lower is better.',
        query=|||
          max by(shard, environment, tier, type, stage) (
            sum by (fqdn, instance, shard, environment, tier, type, stage) (sidekiq_running_jobs{%(querySelector)s})
            /
            sum by (fqdn, instance, shard, environment, tier, type, stage) (sidekiq_concurrency{%(querySelector)s})
          )
        ||| % formatConfig,
        legendFormat='{{ shard }}',
        intervalFactor=1,
        linewidth=2,
      ),
      basic.saturationTimeseries(
        'Node Average CPU Utilization per Shard',
        description='The maximum utilization of a single core on each node. Lower is better',
        query=|||
          avg(1 - rate(node_cpu_seconds_total{%(querySelector)s, mode="idle"}[$__interval])) by (shard)
        ||| % formatConfig,
        legendFormat='{{ shard }}',
        legend_show=true,
        linewidth=2
      ),
      basic.saturationTimeseries(
        'Node Maximum Single Core Utilization per Shard',
        description='The maximum utilization of a single core on each node. Lower is better',
        query=|||
          max(1 - rate(node_cpu_seconds_total{%(querySelector)s, mode="idle"}[$__interval])) by (shard)
        ||| % formatConfig,
        legendFormat='{{ shard }}',
        legend_show=true,
        linewidth=2
      ),
      basic.saturationTimeseries(
        title='Maximum Memory Utilization per Shard',
        description='Memory utilization. Lower is better.',
        query=|||
          max by (shard) (
            instance:node_memory_utilization:ratio{%(querySelector)s}
          )
        ||| % formatConfig,
        legendFormat='{{ shard }}',
        interval='1m',
        intervalFactor=1,
        legend_show=true,
        linewidth=2
      ),
    ];

    local panelsWithDataLink =
      if datalink != null then
        [p.addDataLink(datalink) for p in panels]
      else
        panels;

    layout.grid(panelsWithDataLink, cols=2, rowHeight=10, startRow=startRow),
}
