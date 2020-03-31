local basic = import 'basic.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local issueSearch = import 'issue_search.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
local thresholds = import 'thresholds.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local tablePanel = grafana.tablePanel;

local findIssuesLink = issueSearch.buildInfraIssueSearch(
  labels=['GitLab.com Resource Saturation'],
  search='${__cell_1}+${__cell_3}'
);

local saturationTable(title, description, query, saturationDays, valueColumnName) =
  tablePanel.new(
    title,
    description=description,
    datasource='$PROMETHEUS_DS',
    styles=[
      {
        alias: 'Satuation Resource',
        link: true,
        linkTargetBlank: true,
        linkTooltip: 'Click the link to review the past %d day(s) history for this saturation point.' % [saturationDays],
        linkUrl: 'https://dashboards.gitlab.net/d/alerts-saturation_component/alerts-saturation-component-alert?var-environment=gprd&var-type=${__cell_3}&var-stage=${__cell_2}&var-component=${__cell_1}&from=now-' + saturationDays + 'd/d&to=now/h',
        mappingType: 1,
        pattern: 'component',
        type: 'string',
      },
      {
        alias: 'Type',
        mappingType: 1,
        pattern: 'type',
        thresholds: [],
        type: 'string',
      },
      {
        alias: valueColumnName,
        colorMode: 'row',
        colors: [
          colors.errorColor,
          colors.errorColor,
          colors.errorColor,
        ],
        mappingType: 1,
        pattern: 'Value',
        thresholds: [
          '0',
          '100',
        ],
        type: 'number',
        unit: 'percentunit',
        decimals: 2,
      },
      {
        alias: 'Stage',
        mappingType: 2,
        pattern: 'stage',
        type: 'string',
      },
      {  // Sneaky repurposing of the Time column as a find issues link
        alias: 'Issues',
        mappingType: 2,
        pattern: 'Time',
        type: 'string',
        rangeMaps: [
          {
            from: '0',
            to: '9999999999999',
            text: 'Find Issues',
          },
        ],
        link: true,
        linkTargetBlank: true,
        linkUrl: findIssuesLink,
        linkTooltip: 'Click the link to find issues on GitLab.com related to this saturation point.',
      },
      {
        alias: '',
        mappingType: 1,
        pattern: '/.*/',
        type: 'hidden',
      },
    ],
  )
  .addTarget(promQuery.target(query, instant=true, format='table')) + {
    sort: {
      col: 13,
      desc: true,
    },
  };

local currentSaturationBreaches(nodeSelector) =
  saturationTable(
    'Currently Saturated Resources',
    description='Lists saturated resources that are breaching their soft SLO thresholds at this instant',
    query=|||
      max by (type, stage, component) (
        clamp_max(
          gitlab_component_saturation:ratio{environment="$environment", %(nodeSelector)s}
          ,
          1
        ) >= on(component, monitor, env, cluster) group_left slo:max:soft:gitlab_component_saturation:ratio
      )
    ||| % { nodeSelector: nodeSelector },
    saturationDays=1,
    valueColumnName='Current %'
  );

local currentSaturationWarnings(nodeSelector) =
  saturationTable(
    'Resources Currently at Risk of being Saturated',
    description='Lists saturated resources that, given their current value and weekly variance, have a high probability of breaching their soft thresholds limits within the next few hours',
    query=|||
      sort_desc(
        max by (type, stage, component) (
          clamp_max(
            gitlab_component_saturation:ratio:avg_over_time_1w{
              environment="$environment",
              %(nodeSelector)s
            } +
            2 *
              gitlab_component_saturation:ratio:stddev_over_time_1w{
                environment="$environment",
                %(nodeSelector)s
              }
            , 1
          )
          >= on(component, monitor, env, cluster) group_left slo:max:soft:gitlab_component_saturation:ratio
        )
      )
    ||| % { nodeSelector: nodeSelector },
    saturationDays=7,
    valueColumnName='Worst-case Saturation Today'
  );

local twoWeekSaturationWarnings(nodeSelector) =
  saturationTable(
    'Resources Forecasted to be at Risk of Saturation in 14d',
    description='Lists saturated resources that, given their growth rate over the the past week, and their weekly variance, are likely to breach their soft thresholds limits in the next 14d',
    query=|||
      sort_desc(
        max by (type, stage, component) (
          clamp_max(
            gitlab_component_saturation:ratio:predict_linear_2w{
              environment="$environment",
              %(nodeSelector)s
            } +
            2 *
              gitlab_component_saturation:ratio:stddev_over_time_1w{
                environment="$environment",
                %(nodeSelector)s
              }
          , 1
          )
          >= on(component, monitor, env, cluster) group_left slo:max:soft:gitlab_component_saturation:ratio
        )
      )
    ||| % { nodeSelector: nodeSelector },
    saturationDays=30,
    valueColumnName='Worst-case Saturation 14d Forecast'
  );

{
  environmentCapacityPlanningRow()::
    row.new(title='📆 Capacity Planning', collapse=true)
    .addPanels(self.environmentCapacityPlanningPanels()),

  environmentCapacityPlanningPanels(startRow=1)::
    local nodeSelector = 'type!="", component!=""';

    layout.grid([
      currentSaturationBreaches(nodeSelector),
      currentSaturationWarnings(nodeSelector),
      twoWeekSaturationWarnings(nodeSelector),
    ], cols=1, startRow=startRow),

  capacityPlanningRow(serviceType, serviceStage)::
    local formatConfig = { serviceType: serviceType, serviceStage: serviceStage };
    local nodeSelector = 'type="%(serviceType)s", stage=~"|%(serviceStage)s"' % formatConfig;
    row.new(title='📆 Capacity Planning', collapse=true)
    .addPanels(
      layout.grid(
        [
          currentSaturationBreaches(nodeSelector),
          currentSaturationWarnings(nodeSelector),
          twoWeekSaturationWarnings(nodeSelector),
          graphPanel.new(
            'Long-term Resource Saturation',
            description='Resource saturation levels for saturation components for this service. Lower is better.',
            sort='decreasing',
            linewidth=1,
            fill=0,
            datasource='$PROMETHEUS_DS',
            decimals=0,
            legend_show=true,
            legend_hideEmpty=true,
          )
          .addTarget(
            promQuery.target(
              |||
                clamp_min(clamp_max(
                  max(
                    gitlab_component_saturation:ratio{
                      type="%(serviceType)s",
                      environment="$environment",
                      stage=~"|%(serviceStage)s"
                    }
                  ) by (component)
                  ,1)
                ,0)
              ||| % formatConfig,
              legendFormat='{{ component }}',
              interval='5m',
              intervalFactor=5
            )
          )
          .resetYaxes()
          .addYaxis(
            format='percentunit',
            min=0,
            max=1,
            label='Saturation %',
          )
          .addYaxis(
            format='short',
            min=0,
            show=false,
          ) {
            timeFrom: '21d',
            seriesOverrides+: seriesOverrides.capacityThresholds + [seriesOverrides.capacityTrend],
          },
          graphPanel.new(
            'Long-term Resource Saturation - Rolling 1w average trend',
            description='Percentage of time that resource is within capacity SLOs. Higher is better.',
            sort='decreasing',
            linewidth=1,
            fill=0,
            datasource='$PROMETHEUS_DS',
            decimals=0,
            legend_show=true,
            legend_hideEmpty=true,
            thresholds=[
              thresholds.warningLevel('gt', 0.85),
              thresholds.errorLevel('lt', 0.95),
            ]
          )
          .addTarget(
            promQuery.target(
              |||
                clamp_min(
                  clamp_max(
                    max(
                      gitlab_component_saturation:ratio:avg_over_time_1w{
                        type="%(serviceType)s",
                        environment="$environment",
                        stage=~"%(serviceStage)s|"
                      }
                    ) by (component)
                  ,1)
                ,0)
              ||| % formatConfig,
              legendFormat='{{ component }}',
              interval='5m',
              intervalFactor=5
            )
          )
          .resetYaxes()
          .addYaxis(
            format='percentunit',
            max=1,
            label='Saturation %',
          )
          .addYaxis(
            format='short',
            max=1,
            min=0,
            show=false,
          ) {
            timeFrom: '21d',
            seriesOverrides+: seriesOverrides.capacityThresholds + [seriesOverrides.capacityTrend],
          },
        ], cols=1
      )
    ),
}
