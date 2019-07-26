local basic = import 'basic.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
local thresholds = import 'thresholds.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

local baseBargauge = {
  type: 'bargauge',
  options: {
    displayMode: 'gradient',
    orientation: 'horizontal',
    fieldOptions: {
      values: true,
      calcs: ['last'],
      defaults: {
        min: 0,
        max: 1,
        decimals: 0,
        title: '',
      },
      mappings: [
        {
          id: 1,
          operator: '',
          value: '',
          text: 'Over-capacity ⚠️',
          type: 2,
          from: '0',
          to: '0.25',
        },
        {
          id: 2,
          operator: '',
          value: '',
          text: 'Nearing capacity limit',
          type: 2,
          from: '0.25',
          to: '0.5',
        },
        {
          id: 3,
          operator: '',
          value: '',
          text: 'Tending towards saturation',
          type: 2,
          from: '0.5',
          to: '0.75',
        },
        {
          id: 4,
          operator: '',
          value: '',
          text: 'Within capacity',
          type: 2,
          from: '0.75',
          to: '1',
        },
      ],
      thresholds: [
        {
          index: 0,
          value: null,
          color: colors.errorColor,
        },
        {
          color: colors.warningColor,
          index: 1,
          value: 0.25,
        },
        {
          color: colors.normalRangeColor,
          index: 2,
          value: 0.5,
        },
      ],
    },
  },
};


local currentSaturationBarGauge(serviceType, serviceStage) = baseBargauge {
  title: 'Current Saturation',
  description: 'Resource Saturation Acceptability (sapdex). Higher is better.',
  targets: [
    promQuery.target(
      'sort(
          clamp_min(
            clamp_max(
              min(
                gitlab_component_saturation:ratio:sapdex:avg_over_time_1w{environment="$environment", type="' + serviceType + '", stage=~"|' + serviceStage + '"}
              ) by (component),
            1),
          0)
        )',
      legendFormat='{{ component }}',
      instant=true
    ),
  ],
};

local oneMonthForecastBarGauge(serviceType, serviceStage) = baseBargauge {
  title: 'One Month Saturation Forecast',
  description: 'Resource Saturation Acceptability (sapdex) predictions for one month from now. Higher is better.',
  targets: [
    promQuery.target(
      'sort(
          clamp_min(
            clamp_max(
              min(
                gitlab_component_saturation:ratio:sapdex:avg_over_time_1w:predict_linear_30d{environment="$environment", type="' + serviceType + '", stage=~"|' + serviceStage + '"}
              ) by (component),
            1),
          0)
        )',
      legendFormat='{{ component }}',
      instant=true
    ),
  ],
};

{
  currentEnvironmentSaturationBarGauge():: baseBargauge {
    title: 'Resources currently at risk of saturation',
    description: 'Resource Saturation Acceptability (sapdex). Higher is better.',
    targets: [
      promQuery.target(
        'sort(
          gitlab_component_saturation:ratio:sapdex:avg_over_time_1w:predict_linear_30d{environment="$environment", stage="$stage"} < 0.75
        )',
        legendFormat='{{ type }} service, {{ component }} resource',
        instant=true
      ),
    ],
  },
  oneMonthEnvironmentForecastBarGauge():: baseBargauge {
    title: 'One month resource saturation forecast',
    description: 'Resource Saturation Acceptability (sapdex) predictions for one month from now. Higher is better.',
    targets: [
      promQuery.target(
        'sort(
          gitlab_component_saturation:ratio:sapdex:avg_over_time_1w{environment="$environment", stage="$stage"} < 0.75
        )',
        legendFormat='{{ type }} service, {{ component }} resource',
        instant=true
      ),
    ]
  },
  capacityPlanningRow(serviceType, serviceStage):: row.new(title='📆 Capacity Planning', collapse=true)
                                                   .addPanels(layout.grid([
    currentSaturationBarGauge(serviceType, serviceStage),
    oneMonthForecastBarGauge(serviceType, serviceStage),
    graphPanel.new(
      'Long Resource Saturation Trends',
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
        'clamp_min(clamp_max(
          gitlab_component_saturation:ratio{type="' + serviceType + '", environment="$environment", stage=~"|' + serviceStage + '"}
          ,1),0)
        ',
        legendFormat='{{ component }}',
        interval='5m',
        intervalFactor=5
      )
    )
    .addTarget(
      promQuery.target(
        'clamp_min(clamp_max(
          gitlab_component_saturation:ratio:avg_over_time_1w{type="' + serviceType + '", environment="$environment", stage=~"|' + serviceStage + '"}
          ,1),0)
        ',
        legendFormat='{{ component }} trend',
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
      'Long-term Resource Saturation Acceptability (sapdex) Trends',
      description='Percentage of time that resource is within capacity SLOs. Higher is better.',
      sort='increasing',
      linewidth=1,
      fill=0,
      datasource='$PROMETHEUS_DS',
      decimals=0,
      legend_show=true,
      legend_hideEmpty=true,
      thresholds=[
        thresholds.warningLevel('lt', 0.5),
        thresholds.errorLevel('lt', 0.25),
      ]
    )
    .addTarget(
      promQuery.target(
        'clamp_min(clamp_max(
          gitlab_component_saturation:ratio:sapdex{type="' + serviceType + '", environment="$environment", stage=~"' + serviceStage + '|"}
          ,1),0)
        ',
        legendFormat='{{ component }}',
        interval='5m',
        intervalFactor=5
      )
    )
    .addTarget(
      promQuery.target(
        'clamp_min(clamp_max(
          avg_over_time(gitlab_component_saturation:ratio:sapdex:avg_over_time_1w{type="' + serviceType + '", environment="gprd", stage=~"' + serviceStage + '|"}[$__interval])
          ,1),0)
        ',
        legendFormat='{{ component }} trend',
        interval='5m',
        intervalFactor=5
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label='Acceptability %',
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
  ], cols=1)),
}
