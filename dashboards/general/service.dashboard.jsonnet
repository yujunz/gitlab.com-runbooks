local grafana = import 'grafonnet/grafana.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local colors = import 'colors.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local layout = import 'layout.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

local generalGraphPanel(
  title,
  description=null,
  linewidth=2,
  sort="increasing",
) = graphPanel.new(
    title,
    linewidth=linewidth,
    fill=0,
    datasource="$PROMETHEUS_DS",
    description=description,
    decimals=2,
    sort=sort,
    legend_show=true,
    legend_values=true,
    legend_min=true,
    legend_max=true,
    legend_current=true,
    legend_total=false,
    legend_avg=true,
    legend_alignAsTable=true,
    legend_hideEmpty=true,
  )
  .addSeriesOverride(seriesOverrides.goldenMetric("/ service/"))
  .addSeriesOverride(seriesOverrides.upper)
  .addSeriesOverride(seriesOverrides.lower)
  .addSeriesOverride(seriesOverrides.upperLegacy)
  .addSeriesOverride(seriesOverrides.lowerLegacy)
  .addSeriesOverride(seriesOverrides.lastWeek)
  .addSeriesOverride(seriesOverrides.alertFiring)
  .addSeriesOverride(seriesOverrides.alertPending)
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)
  .addSeriesOverride(seriesOverrides.slo);


local activeAlertsPanel() = grafana.tablePanel.new(
    'Active Alerts',
    datasource="$PROMETHEUS_DS",
    styles=[{
      "type": "hidden",
      "pattern": "Time",
      "alias": "Time",
    }, {
      "unit": "short",
      "type": "string",
      "alias": "Alert",
      "decimals": 2,
      "pattern": "alertname",
      "mappingType": 2,
      "link": true,
      "linkUrl": "https://alerts.${environment}.gitlab.net/#/alerts?filter=%7Balertname%3D%22${__cell}%22%2C%20env%3D%22${environment}%22%2C%20type%3D%22${type}%22%7D",
      "linkTooltip": "Open alertmanager",
    }, {
      "unit": "short",
      "type": "number",
      "alias": "Score",
      "decimals": 0,
      "colors": [
        colors.warningColor,
        colors.errorColor,
        colors.criticalColor
      ],
      "colorMode": "row",
      "pattern": "Value",
      "thresholds": [
        "2",
        "3"
      ],
      "mappingType": 1
    }
  ],
  )
  .addTarget( // Alert scoring
    promQuery.target('
      sort(
        max(
        ALERTS{environment="$environment", type="$type", stage="$stage", severity="critical", alertstate="firing"} * 3
        or
        ALERTS{environment="$environment", type="$type", stage="$stage", severity="error", alertstate="firing"} * 2
        or
        ALERTS{environment="$environment", type="$type", stage="$stage", severity="warn", alertstate="firing"}
        ) by (alertname, severity)
      )
      ',
      format="table",
      instant=true
    )
  );

local latencySLOPanel() = grafana.singlestat.new(
    '7d Latency SLO Error Budget',
    datasource="$PROMETHEUS_DS",
    format='percentunit',
  )
  .addTarget(
    promQuery.target('
        avg(avg_over_time(slo_observation_status{slo="error_ratio", environment="$environment", type="$type", stage="$stage"}[7d]))
      ',
      instant=true
    )
  );

local errorRateSLOPanel() = grafana.singlestat.new(
    '7d Apdex Rate SLO Error Budget',
    datasource="$PROMETHEUS_DS",
    format='percentunit',
  )
  .addTarget(
    promQuery.target('
        avg_over_time(slo_observation_status{slo="apdex_ratio",  environment="$environment", type="$type", stage="$stage"}[7d])
      ',
      instant=true
    )
  );

dashboard.new(
  'Service Platform Metrics',
  schemaVersion=16,
  tags=['general'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addAnnotation(commonAnnotations.deploymentsForEnvironment)
.addAnnotation(commonAnnotations.deploymentsForEnvironmentCanary)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.type)
.addTemplate(templates.stage)
.addTemplate(templates.sigma)
.addPanel(row.new(title="👩‍⚕️ Service Health", collapse=true)
  .addPanel(latencySLOPanel(),
    gridPos={
      x: 0,
      y: 1,
      w: 6,
      h: 4,
  })
  .addPanel(activeAlertsPanel(),
    gridPos={
      x: 6,
      y: 1,
      w: 18,
      h: 8,
  })
  .addPanel(errorRateSLOPanel(),
    gridPos={
      x: 0,
      y: 5,
      w: 6,
      h: 4,
  }),
  gridPos={
      x: 0,
      y: 0,
      w: 24,
      h: 1,
  }
)
.addPanel(row.new(title="🏅 Key Service Metrics"),
  gridPos={
      x: 0,
      y: 1000,
      w: 24,
      h: 1,
  }
)
.addPanels(layout.grid([
    keyMetrics.apdexPanel('$type', '$stage'),
    keyMetrics.errorRatesPanel('$type', '$stage'),
    keyMetrics.serviceAvailabilityPanel('$type', '$stage'),
    keyMetrics.qpsPanel('$type', '$stage'),
    keyMetrics.saturationPanel('$type', '$stage')
  ], startRow=1001)
)
.addPanel(keyMetrics.keyComponentMetricsRow('$type', '$stage'),
  gridPos={
      x: 0,
      y: 2000,
      w: 24,
      h: 1,
  }
)
.addPanel(nodeMetrics.nodeMetricsDetailRow('environment="$environment", stage=~"|$stage", type="$type"'),
  gridPos={
      x: 0,
      y: 3000,
      w: 24,
      h: 1,
  }
)
.addPanel(capacityPlanning.capacityPlanningRow('$type', '$stage'), gridPos={ x: 0, y: 4000, })

+ {
  links+: platformLinks.services + platformLinks.triage,
}


