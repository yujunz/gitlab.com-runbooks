local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local graphPanel = grafana.graphPanel;
local grafana = import 'grafonnet/grafana.libsonnet';
local row = grafana.row;
local seriesOverrides = import 'series_overrides.libsonnet';
local thresholds = import 'thresholds.libsonnet';
local selectors = import 'lib/selectors.libsonnet';

{
  kubernetesOverview(nodeSelectorHash, startRow=1)::
    local formatConfig = {
      selector: selectors.serializeHash(nodeSelectorHash)
    };

    layout.grid([
      basic.timeseries(
        title='Total CPU Utilisation',
        description='Total CPU utilisation',
        query=|||
          sum(rate(container_cpu_usage_seconds_total{%(selector)s}[$__interval]))
        ||| % formatConfig,
        legendFormat='CPU',
        format='percent',
        interval='1m',
        intervalFactor=3,
        yAxisLabel='CPU Utilisation',
      ),
      basic.timeseries(
        title='Total Memory Utilisation',
        description='Total CPU utilisation',
        query=|||
          sum(rate(container_memory_usage_bytes{%(selector)s}[$__interval]))
        ||| % formatConfig,
        legendFormat='Memory Usage',
        format='bytes',
        interval='1m',
        intervalFactor=3,
        yAxisLabel='Memory Usage',
      ),
    ],
    startRow=startRow)
}
