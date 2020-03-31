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

local oneHourBurnRate =
  [
    ['1h apdex burn rate', 'gitlab_component_apdex:ratio_1h{environment="$environment", type="$type", stage="$stage", component="$component"}'],
    ['5m apdex burn rate', 'gitlab_component_apdex:ratio_5m{environment="$environment", type="$type", stage="$stage", component="$component"}'],
    [
      '1h apdex burn threshold',
      '1 - (%(burnrate_1h)g * (1 - avg(slo:min:events:gitlab_service_apdex:ratio{environment="$environment", type="$type"})))' % multiburnFactors,
    ],
    [
      'Proposed SLO @ 1h burn',
      '1 - (%(burnrate_1h)g * (1 - $proposed_slo))' % multiburnFactors,
    ],
  ];

local sixHourBurnRate =
  [
    ['6h apdex burn rate', 'gitlab_component_apdex:ratio_6h{environment="$environment", type="$type", stage="$stage", component="$component"}'],
    ['30m apdex burn rate', 'gitlab_component_apdex:ratio_30m{environment="$environment", type="$type", stage="$stage", component="$component"}'],
    [
      '6h apdex burn threshold',
      '1 - (%(burnrate_6h)g * (1 - avg(slo:min:events:gitlab_service_apdex:ratio{environment="$environment", type="$type"})))' % multiburnFactors,
    ],
    [
      'Proposed SLO @ 6h burn',
      '1 - (%(burnrate_6h)g * (1 - $proposed_slo))' % multiburnFactors,
    ],
  ];

local burnRatePanel(title, combinations) =
  local basePanel = basic.percentageTimeseries(
    title=title,
    decimals=4,
    description='apdex burn rates: higher is better',
    query=combinations[0][1],
    legendFormat=combinations[0][0],
  );

  std.foldl(
    function(memo, combo)
      memo.addTarget(promQuery.target(combo[1], legendFormat=combo[0])),
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

basic.dashboard(
  'Component Multi-window Multi-burn-rate Apdex Out of SLO',
  tags=['alert-target', 'general'],
)
.addTemplate(templates.type)
.addTemplate(templates.stage)
.addTemplate(templates.component)
.addTemplate(
  template.custom(
    'proposed_slo',
    'NaN,0.9,0.95,0.99,0.995,0.999,0.9995,0.9999',
    'NaN',
  )
)
.addPanels(
  layout.columnGrid([
    [
      basic.slaStats(
        title='SLO',
        description='Availability',
        query='avg(slo:min:events:gitlab_service_apdex:ratio{environment="$environment", type="$type"}) by (type)',
        legendFormat='{{ type }}',
        fieldTitle='Apdex Rate SLO for the $type service'
      ),
      grafana.text.new(
        title='Help',
        mode='markdown',
        content=|||
          The Apdex Rate SLO for this service will determine the thresholds (indicated by the dotted lines)
          in the following graphs. Over time, we expect these SLOs to become stricted (more nines) by
          improving the reliability of our service.

          **For more details of this technique, be sure to the Alerting on SLOs chapter of the
          [Google SRE Workbook](https://landing.google.com/sre/workbook/chapters/alerting-on-slos/)**
        |||
      ),
    ],
  ], rowHeight=8, columnWidths=[8, 16]) +
  layout.columnGrid([
    burnRatePanelWithHelp(
      title='Multi-window, multi-burn-rates',
      combinations=oneHourBurnRate + sixHourBurnRate,
      content=|||
        # Multi-window, multi-burn-rates

        The alert will fire when both of the green solid series cross the green dotted threshold, or
        both of the blue solid series cross the blue dotted threshold.
      |||
    ),
    burnRatePanelWithHelp(
      title='Single window, 1h/5m burn-rates',
      combinations=oneHourBurnRate,
      content=|||
        # Single window, 1h/5m burn-rates

        Removing the 6h/30m burn-rates, this shows the same data over the 1h/5m burn-rates.

        The alert will fire when the solid lines cross the dotted threshold.
      |||
    ),
    burnRatePanelWithHelp(
      title='Single window, 6h/30m burn-rates',
      combinations=sixHourBurnRate,
      content=|||
        # Single window, 6h/30m burn-rates

        Removing the 1h/5m burn-rates, this shows the same data over the 6h/30m burn-rates.

        The alert will fire when the solid lines cross the dotted threshold.
      |||
    ),
    burnRatePanelWithHelp(
      title='Single window, 1h/5m burn-rates, no thresholds',
      combinations=oneHourBurnRate[:2],
      content=|||
        # Single window, 1h/5m burn-rates, no thresholds

        Since the threshold can be relatively high, removing it can help visualise the current values better.
      |||
    ),
    burnRatePanelWithHelp(
      title='Single window, 6h/30m burn-rates, no thresholds',
      combinations=sixHourBurnRate[:2],
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
}
