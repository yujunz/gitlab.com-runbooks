local basic = import 'basic.libsonnet';
local colors = import 'colors.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local seriesOverrides = import 'series_overrides.libsonnet';
local multiburnFactors = import 'lib/multiburn_factors.libsonnet';
local selectors = import 'lib/selectors.libsonnet';
local statusDescription = import 'status_description.libsonnet';

local combinations(shortMetric, shortDuration, longMetric, longDuration, selectorHash, apdexInverted, sloMetric) =
  local formatConfig = {
    shortMetric: shortMetric,
    shortDuration: shortDuration,
    longMetric: longMetric,
    longDuration: longDuration,
    longBurnFactor: multiburnFactors['burnrate_' + longDuration],
    selector: selectors.serializeHash(selectorHash),
    sloMetric: sloMetric,
  };

  [
    {
      legendFormat: '%(longDuration)s apdex burn rate' % formatConfig,
      query: '%(longMetric)s{%(selector)s}' % formatConfig,
    },
    {
      legendFormat: '%(shortDuration)s apdex burn rate' % formatConfig,
      query: '%(shortMetric)s{%(selector)s}' % formatConfig,
    },
    {
      legendFormat: '%(longDuration)s apdex burn threshold' % formatConfig,
      query: if apdexInverted then
        '(1 - (%(longBurnFactor)g * (1 - avg(%(sloMetric)s{type="$type"})))) unless (vector($proposed_slo) > 0) ' % formatConfig
      else
        '(%(longBurnFactor)g * avg(%(sloMetric)s{type="$type"})) unless (vector($proposed_slo) > 0)' % formatConfig,
    },
    {
      legendFormat: 'Proposed SLO @ %(longDuration)s burn' % formatConfig,
      query: if apdexInverted then
        '1 - (%(longBurnFactor)g * (1 - $proposed_slo))' % formatConfig
      else
        '%(longBurnFactor)g * (1 - $proposed_slo)' % formatConfig,
    },
  ];

local burnRatePanel(title, combinations) =
  local basePanel = basic.percentageTimeseries(
    title=title,
    decimals=4,
    description='apdex burn rates: higher is better',
    query=combinations[0].query,
    legendFormat=combinations[0].legendFormat,
  );

  std.foldl(
    function(memo, combo)
      memo.addTarget(promQuery.target(combo.query, legendFormat=combo.legendFormat)),
    combinations[1:],
    basePanel
  )
  .addSeriesOverride({
    alias: '6h apdex burn rate',
    color: '#5794F2',
    linewidth: 4,
    zindex: 0,
    fillBelowTo: '30m apdex burn rate',
  })
  .addSeriesOverride({
    alias: '1h apdex burn rate',
    color: '#73BF69',
    linewidth: 4,
    zindex: 1,
    fillBelowTo: '5m apdex burn rate',
  })
  .addSeriesOverride({
    alias: '30m apdex burn rate',
    color: '#5794F2',
    linewidth: 2,
    zindex: 2,
  })
  .addSeriesOverride({
    alias: '5m apdex burn rate',
    color: '#73BF69',
    linewidth: 2,
    zindex: 3,
  })
  .addSeriesOverride({
    alias: '6h apdex burn threshold',
    color: '#5794F2',
    dashLength: 2,
    dashes: true,
    lines: true,
    linewidth: 2,
    spaceLength: 4,
    zindex: -1,
  })
  .addSeriesOverride({
    alias: '1h apdex burn threshold',
    color: '#73BF69',
    dashLength: 2,
    dashes: true,
    lines: true,
    linewidth: 2,
    spaceLength: 4,
    zindex: -2,
  });

local burnRatePanelWithHelp(title, combinations, content) =
  [
    burnRatePanel(title, combinations),
    grafana.text.new(
      title='Help',
      mode='markdown',
      content=content
    ),
  ];


local multiburnRateAlertsDashboard(
  title,
  oneHourBurnRateCombinations,
  sixHourBurnRateCombinations,
  componentLevel,
  selectorHash,
  statusDescriptionPanel
      ) =
  local dashboardInitial = basic.dashboard(
    title,
    tags=['alert-target', 'general'],
  )
                           .addTemplate(templates.type)
                           .addTemplate(templates.stage)
                           .addTemplate(
    template.custom(
      'proposed_slo',
      'NaN,0.9,0.95,0.99,0.995,0.999,0.9995,0.9999',
      'NaN',
    )
  );

  local dashboard = if componentLevel then
    dashboardInitial.addTemplate(templates.component)
  else
    dashboardInitial;

  dashboard.addPanels(
    layout.columnGrid([
      (if statusDescriptionPanel != null then [statusDescriptionPanel] else [])
      +
      [
        basic.slaStats(
          title='',
          description='Availability',
          query='avg(slo:min:events:gitlab_service_apdex:ratio{type="$type"}) by (type)',
          legendFormat='{{ type }} service monitoring SLO',
          fieldTitle='SLO for the $type service'
        ),
        grafana.text.new(
          title='Help',
          mode='markdown',
          content=|||
            The SLO for this service will determine the thresholds (indicated by the dotted lines)
            in the following graphs. Over time, we expect these SLOs to become stricter (more nines) by
            improving the reliability of our service.

            **For more details of this technique, be sure to the Alerting on SLOs chapter of the
            [Google SRE Workbook](https://landing.google.com/sre/workbook/chapters/alerting-on-slos/)**
          |||
        ),
      ],
    ], rowHeight=6, columnWidths=[6, 6, 12]) +
    layout.columnGrid([
      burnRatePanelWithHelp(
        title='Multi-window, multi-burn-rates',
        combinations=oneHourBurnRateCombinations + sixHourBurnRateCombinations,
        content=|||
          # Multi-window, multi-burn-rates

          The alert will fire when both of the green solid series cross the green dotted threshold, or
          both of the blue solid series cross the blue dotted threshold.
        |||
      ),
      burnRatePanelWithHelp(
        title='Single window, 1h/5m burn-rates',
        combinations=oneHourBurnRateCombinations,
        content=|||
          # Single window, 1h/5m burn-rates

          Removing the 6h/30m burn-rates, this shows the same data over the 1h/5m burn-rates.

          The alert will fire when the solid lines cross the dotted threshold.
        |||
      ),
      burnRatePanelWithHelp(
        title='Single window, 6h/30m burn-rates',
        combinations=sixHourBurnRateCombinations,
        content=|||
          # Single window, 6h/30m burn-rates

          Removing the 1h/5m burn-rates, this shows the same data over the 6h/30m burn-rates.

          The alert will fire when the solid lines cross the dotted threshold.
        |||
      ),
      burnRatePanelWithHelp(
        title='Single window, 1h/5m burn-rates, no thresholds',
        combinations=oneHourBurnRateCombinations[:2],
        content=|||
          # Single window, 1h/5m burn-rates, no thresholds

          Since the threshold can be relatively high, removing it can help visualise the current values better.
        |||
      ),
      burnRatePanelWithHelp(
        title='Single window, 6h/30m burn-rates, no thresholds',
        combinations=sixHourBurnRateCombinations[:2],
        content=|||
          # Single window, 6h/30m burn-rates, no thresholds

          Since the threshold can be relatively high, removing it can help visualise the current values better.
        |||
      ),
    ], columnWidths=[18, 6], rowHeight=10, startRow=100)
  )
  .trailer()
  + {
    links+: platformLinks.triage,
  };

local componentSelectorHash = { environment: '$environment', env: '$environment', type: '$type', stage: '$stage', component: '$component' };
local serviceSelectorHash = { environment: '$environment', env: '$environment', type: '$type', stage: '$stage', monitor: 'global' };
local apdexSLOMetric = 'slo:min:events:gitlab_service_apdex:ratio';
local errorSLOMetric = 'slo:max:events:gitlab_service_errors:ratio';

{
  // Apdex, for components
  component_multiburn_apdex: multiburnRateAlertsDashboard(
    title='Component Multi-window Multi-burn-rate Apdex Out of SLO',
    selectorHash=componentSelectorHash,
    oneHourBurnRateCombinations=combinations(
      shortMetric='gitlab_component_apdex:ratio_5m',
      shortDuration='5m',
      longMetric='gitlab_component_apdex:ratio_1h',
      longDuration='1h',
      selectorHash=componentSelectorHash,
      apdexInverted=true,
      sloMetric=apdexSLOMetric,
    ),
    sixHourBurnRateCombinations=combinations(
      shortMetric='gitlab_component_apdex:ratio_30m',
      shortDuration='30m',
      longMetric='gitlab_component_apdex:ratio_6h',
      longDuration='6h',
      selectorHash=componentSelectorHash,
      apdexInverted=true,
      sloMetric=apdexSLOMetric,
    ),
    componentLevel=true,
    statusDescriptionPanel=statusDescription.componentApdexStatusDescriptionPanel(componentSelectorHash)
  ),

  // Error Rates, for components
  component_multiburn_error: multiburnRateAlertsDashboard(
    title='Component Multi-window Multi-burn-rate Error Rate Out of SLO',
    selectorHash=componentSelectorHash,
    oneHourBurnRateCombinations=combinations(
      shortMetric='gitlab_component_errors:ratio_5m',
      shortDuration='5m',
      longMetric='gitlab_component_errors:ratio_1h',
      longDuration='1h',
      selectorHash=componentSelectorHash,
      apdexInverted=false,
      sloMetric=errorSLOMetric,
    ),
    sixHourBurnRateCombinations=combinations(
      shortMetric='gitlab_component_errors:ratio_30m',
      shortDuration='30m',
      longMetric='gitlab_component_errors:ratio_6h',
      longDuration='6h',
      selectorHash=componentSelectorHash,
      apdexInverted=false,
      sloMetric=errorSLOMetric,
    ),
    componentLevel=true,
    statusDescriptionPanel=statusDescription.componentErrorRateStatusDescriptionPanel(componentSelectorHash)
  ),

  // Apdex, for services
  service_multiburn_apdex: multiburnRateAlertsDashboard(
    title='Service Multi-window Multi-burn-rate Apdex Out of SLO',
    selectorHash=serviceSelectorHash,
    oneHourBurnRateCombinations=combinations(
      shortMetric='gitlab_service_apdex:ratio_5m',
      shortDuration='5m',
      longMetric='gitlab_service_apdex:ratio_1h',
      longDuration='1h',
      selectorHash=serviceSelectorHash,
      apdexInverted=true,
      sloMetric=apdexSLOMetric,
    ),
    sixHourBurnRateCombinations=combinations(
      shortMetric='gitlab_service_apdex:ratio_30m',
      shortDuration='30m',
      longMetric='gitlab_service_apdex:ratio_6h',
      longDuration='6h',
      selectorHash=serviceSelectorHash,
      apdexInverted=true,
      sloMetric=apdexSLOMetric,
    ),
    componentLevel=false,
    statusDescriptionPanel=statusDescription.serviceApdexStatusDescriptionPanel(serviceSelectorHash)
  ),

  service_multiburn_error: multiburnRateAlertsDashboard(
    title='Service Multi-window Multi-burn-rate Error Rate Out of SLO',
    selectorHash=serviceSelectorHash,
    oneHourBurnRateCombinations=combinations(
      shortMetric='gitlab_service_errors:ratio_5m',
      shortDuration='5m',
      longMetric='gitlab_service_errors:ratio_1h',
      longDuration='1h',
      selectorHash=serviceSelectorHash,
      apdexInverted=false,
      sloMetric=errorSLOMetric,
    ),
    sixHourBurnRateCombinations=combinations(
      shortMetric='gitlab_service_errors:ratio_30m',
      shortDuration='30m',
      longMetric='gitlab_service_errors:ratio_6h',
      longDuration='6h',
      selectorHash=serviceSelectorHash,
      apdexInverted=false,
      sloMetric=errorSLOMetric,
    ),
    componentLevel=false,
    statusDescriptionPanel=statusDescription.serviceErrorStatusDescriptionPanel(serviceSelectorHash)
  ),
}
