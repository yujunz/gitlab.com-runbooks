local grafana = import 'grafonnet/grafana.libsonnet';

local basic = import 'basic.libsonnet';
local layout = import 'layout.libsonnet';
local panels = import 'panels.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';

local gatewayNameTemplate = grafana.template.new(
  'gateway',
  '$PROMETHEUS_DS',
  'label_values(stackdriver_nat_gateway_logging_googleapis_com_user_nat_translations{environment="$environment"}, gateway_name)',
  current='gitlab-gke',
  refresh='load',
  sort=1,
);

local environmentTemplate = grafana.template.new(
  'environment',
  '$PROMETHEUS_DS',
  'label_values(stackdriver_nat_gateway_logging_googleapis_com_user_nat_translations, environment)',
  current='gprd',
  refresh='load',
  sort=1,
);

local errorsPanel =
  panels.generalGraphPanel('Cloud NAT errors', legend_show=true)
  .addTarget(
    promQuery.target(
      |||
        stackdriver_nat_gateway_logging_googleapis_com_user_nat_errors{environment="$environment"}
      |||,
      legendFormat='errors'
    ),
  )
  .addTarget(
    promQuery.target(
      |||
        stackdriver_nat_gateway_logging_googleapis_com_user_nat_translations{environment="$environment"}
      |||,
      legendFormat='translations'
    ),
  );

basic.dashboard(
  'Cloud NAT',
  tags=['general'],
  refresh='30s',
)
.addTemplate(gatewayNameTemplate)
.addPanels(layout.grid([
  errorsPanel,
], cols=1, rowHeight=10))
