local colors = import 'colors.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local row = grafana.row;

local activeAlertsPanel(type, stage) = grafana.tablePanel.new(
    'Active Alerts',
    datasource="$PROMETHEUS_DS",
    styles=[
{
      type: "hidden",
      pattern: "Time",
      alias: "Time",
    },
{
      unit: "short",
      type: "string",
      alias: "Alert",
      decimals: 2,
      pattern: "alertname",
      mappingType: 2,
      link: true,
      linkUrl: "https://alerts.${environment}.gitlab.net/#/alerts?filter=%7Balertname%3D%22${__cell}%22%2C%20env%3D%22${environment}%22%2C%20type%3D%22" + type + "%22%7D",
      linkTooltip: "Open alertmanager",
    },
{
      unit: "short",
      type: "number",
      alias: "Score",
      decimals: 0,
      colors: [
        colors.warningColor,
        colors.errorColor,
        colors.criticalColor,
      ],
      colorMode: "row",
      pattern: "Value",
      thresholds: [
        "2",
        "3",
      ],
      mappingType: 1,
    },
  ],
  )
  .addTarget(  // Alert scoring
    promQuery.target('
      sort(
        max(
        ALERTS{environment="$environment", type="' + type + '", stage=~"|' + stage + '", severity="s1", alertstate="firing"} * 4
        or
        ALERTS{environment="$environment", type="' + type + '", stage=~"|' + stage + '", severity="s2", alertstate="firing"} * 3
        or
        ALERTS{environment="$environment", type="' + type + '", stage=~"|' + stage + '", severity="s3", alertstate="firing"} * 2
        or
        ALERTS{environment="$environment", type="' + type + '", alertstate="firing"}
        ) by (alertname, severity)
      )
      ',
      format="table",
      instant=true
    )
  );

local latencySLOPanel(type, stage) = grafana.singlestat.new(
    '7d Latency SLO Error Budget',
    datasource="$PROMETHEUS_DS",
    format='percentunit',
  )
  .addTarget(
    promQuery.target('
        avg(avg_over_time(slo_observation_status{slo="error_ratio", environment="$environment", type="' + type + '", stage="' + stage + '"}[7d]))
      ',
      instant=true
    )
  );

local errorRateSLOPanel(type, stage) = grafana.singlestat.new(
    '7d Apdex Rate SLO Error Budget',
    datasource="$PROMETHEUS_DS",
    format='percentunit',
  )
  .addTarget(
    promQuery.target('
        avg_over_time(slo_observation_status{slo="apdex_ratio",  environment="$environment", type="' + type + '", stage="' + stage + '"}[7d])
      ',
      instant=true
    )
  );


{
  row(type, stage)::
  row.new(title="👩‍⚕️ Service Health", collapse=true)
    .addPanel(latencySLOPanel(type, stage),
      gridPos={
        x: 0,
        y: 1,
        w: 6,
        h: 4,
    })
    .addPanel(activeAlertsPanel(type, stage),
      gridPos={
        x: 6,
        y: 1,
        w: 18,
        h: 8,
    })
    .addPanel(errorRateSLOPanel(type, stage),
      gridPos={
        x: 0,
        y: 5,
        w: 6,
        h: 4,
    })

}
