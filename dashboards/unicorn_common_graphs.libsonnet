local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local metricsCatalogDashboards = import 'metrics_catalog_dashboards.libsonnet';
local row = grafana.row;

{
  unicornPanels(serviceType, serviceStage, startRow)::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
    };
    layout.grid([
      basic.timeseries(
        title='Active Unicorn Workers for Service',
        description='The number of unicorn workers actively processing a request. Lower is better.',
        query=|||
          sum(
            unicorn_active_connections{
              environment="$environment",
              type="%(serviceType)s",
              stage="%(serviceStage)s"}
          ) by (type)
        ||| % formatConfig,
        legendFormat='{{ type }}',
        interval='1m',
        intervalFactor=1,
        legend_show=true,
        linewidth=2
      ),
      basic.timeseries(
        title='Active Unicorn Workers by Node',
        description='The number of unicorn workers actively processing a request. Lower is better. Outliers may indicate a problem with a single node in the fleet.',
        query=|||
          sum(
            unicorn_active_connections{
              environment="$environment",
              type="%(serviceType)s",
              stage="%(serviceStage)s"}
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='1m',
        intervalFactor=1,
        legend_show=false,
        linewidth=1
      ),
      basic.timeseries(
        title='Queued Unicorn Requests for Service',
        description='The number of http requests actively waiting for an available unicorn. Zero is good, anything higher means clients are waiting.',
        query=|||
          sum(
            job:unicorn_queued_connections:sum{
              environment="$environment",
              type="%(serviceType)s",
              stage="%(serviceStage)s"}
          ) by (type)
        ||| % formatConfig,
        legendFormat='{{ type }}',
        interval='1m',
        intervalFactor=1,
        legend_show=true,
        linewidth=2
      ),
      basic.timeseries(
        title='Queued Unicorn Requests per Node',
        description='The number of http requests actively waiting for an available unicorn. Zero is good, anything higher means clients are waiting. Outliers may indicate a problem with a single node in the fleet.',
        query=|||
          sum(
            unicorn_queued_connections{
              environment="$environment",
              type="%(serviceType)s",
              stage="%(serviceStage)s"}
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='1m',
        intervalFactor=1,
        legend_show=false,
        linewidth=1
      ),
      basic.timeseries(
        title='Unicorn Kills for Service',
        description='The number of unicorn processes terminated after 60s timeout. Lower is better.',
        query=|||
          sum(
            changes(
              unicorn_killer_terminations_total{
                environment="$environment",
                type="%(serviceType)s",
                stage="%(serviceStage)s"
              }[$__interval])
          ) by (type)
        ||| % formatConfig,
        legendFormat='{{ type }}',
        interval='1m',
        intervalFactor=5,
        legend_show=true,
        linewidth=2
      ),
      basic.timeseries(
        title='Unicorn Kills per Node',
        description='The number of unicorn processes terminated after 60s timeout. Lower is better. Outliers may indicate a faulty node.',
        query=|||
          sum(
            changes(
              unicorn_killer_terminations_total{
                environment="$environment",
                type="%(serviceType)s",
                stage="%(serviceStage)s"
              }[$__interval])
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='1m',
        intervalFactor=5,
        legend_show=false,
        linewidth=1
      ),
    ], cols=2, rowHeight=10, startRow=startRow),

  componentDetailsRow(serviceType, selector)::
    local aggregationSets = [
      { title: 'Overall', aggregationLabels: '', legendFormat: 'unicorn' },
      { title: 'per Method', aggregationLabels: 'method', legendFormat: '{{ method }}' },
      { title: 'per Node', aggregationLabels: 'fqdn', legendFormat: '{{ fqdn }}' },
    ];
    metricsCatalogDashboards.componentDetailMatrix(serviceType, 'unicorn', selector, aggregationSets),
}
