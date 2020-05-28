local colors = import 'colors.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local row = grafana.row;

local activeAlertsPanel(selector, title='Active Alerts') =
  local formatConfig = {
    selector: selector,
  };

  grafana.tablePanel.new(
    title,
    datasource='$PROMETHEUS_DS',
    styles=[
      {
        type: 'hidden',
        pattern: 'Time',
        alias: 'Time',
      },
      {
        unit: 'short',
        type: 'string',
        alias: 'Alert',
        decimals: 2,
        pattern: 'alertname',
        mappingType: 2,
        link: true,
        linkUrl: 'https://alerts.${environment}.gitlab.net/#/alerts?filter=%7Balertname%3D%22${__cell}%22%2C%20env%3D%22${environment}%22%7D',
        linkTooltip: 'Open alertmanager',
      },
      {
        unit: 'short',
        type: 'number',
        alias: 'Score',
        decimals: 0,
        colors: [
          colors.warningColor,
          colors.errorColor,
          colors.criticalColor,
        ],
        colorMode: 'row',
        pattern: 'Value',
        thresholds: [
          '2',
          '3',
        ],
        mappingType: 1,
      },
    ],
  )
  .addTarget(  // Alert scoring
    promQuery.target(
      |||
        sort(
          max(
            ALERTS{environment="$environment", %(selector)s, severity="s1", alertstate="firing"} * 4
            or
            ALERTS{environment="$environment", %(selector)s, severity="s2", alertstate="firing"} * 3
            or
            ALERTS{environment="$environment", %(selector)s, severity="s3", alertstate="firing"} * 2
            or
            ALERTS{environment="$environment", %(selector)s, alertstate="firing"}
          ) by (alertname, severity)
        )
      ||| % formatConfig,
      format='table',
      instant=true
    )
  );

local latencySLOPanel(serviceType, serviceStage) =
  local formatConfig = {
    serviceType: serviceType,
    serviceStage: serviceStage,
  };

  grafana.singlestat.new(
    '7d Latency SLA',
    description='Percentage time the latency SLI for this service is within SLO',
    datasource='$PROMETHEUS_DS',
    format='percentunit',
  )
  .addTarget(
    promQuery.target(
      |||
        avg(avg_over_time(slo_observation_status{slo="apdex_ratio", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[7d]))
      ||| % formatConfig,
      instant=true
    )
  );

local errorRateSLOPanel(serviceType, serviceStage) =
  local formatConfig = {
    serviceType: serviceType,
    serviceStage: serviceStage,
  };

  grafana.singlestat.new(
    '7d Error Rate SLA',
    description='Percentage time the error ratio SLI for this service is within SLO',
    datasource='$PROMETHEUS_DS',
    format='percentunit',
  )
  .addTarget(
    promQuery.target(
      |||
        avg_over_time(slo_observation_status{slo="error_ratio", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[7d])
      ||| % formatConfig,
      instant=true
    )
  );


{
  activeAlertsPanel(selector, title='Active Alerts'):: activeAlertsPanel(selector, title=title),

  row(serviceType, serviceStage)::
    row.new(title='👩‍⚕️ Service Health', collapse=true)
    .addPanel(
      latencySLOPanel(serviceType, serviceStage),
      gridPos={
        x: 0,
        y: 1,
        w: 6,
        h: 4,
      }
    )
    .addPanel(
      activeAlertsPanel('type="%(serviceType)s", stage=~"|%(serviceStage)s"' % { serviceType: serviceType, serviceStage: serviceStage }),
      gridPos={
        x: 6,
        y: 1,
        w: 18,
        h: 8,
      }
    )
    .addPanel(
      errorRateSLOPanel(serviceType, serviceStage),
      gridPos={
        x: 0,
        y: 5,
        w: 6,
        h: 4,
      }
    ),
}
