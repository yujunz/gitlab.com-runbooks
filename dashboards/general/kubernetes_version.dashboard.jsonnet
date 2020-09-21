local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local colors = import 'grafana/colors.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;
local tablePanel = grafana.tablePanel;
local basic = import 'grafana/basic.libsonnet';

local masterVersionPanel =
  tablePanel.new(
    'Master Version',
    datasource='$PROMETHEUS_DS',
    styles=[
      {
        type: 'hidden',
        pattern: 'Time',
        alias: 'Time',
      },
      {
        type: 'hidden',
        pattern: 'Value',
        alias: 'Value',
      },
    ],
  )
  .addTarget(  // Master Version
    promQuery.target(
      |||
        max (kubernetes_build_info{environment="$environment", job="apiserver"}) by (node, gitVersion)
      |||,
      format='table',
      instant=true
    )
  );

local nodeVersionsPanel =
  tablePanel.new(
    'Node Versions',
    datasource='$PROMETHEUS_DS',
    styles=[
      {
        type: 'hidden',
        pattern: 'Time',
        alias: 'Time',
      },
      {
        type: 'hidden',
        pattern: 'Value',
        alias: 'Value',
      },
    ],
  )
  .addTarget(  // Node Versions
    promQuery.target(
      |||
        max(kube_node_info{environment="$environment"}) by (cluster, node, kernel_version, kubelet_version, kubeproxy_version)
      |||,
      format='table',
      instant=true
    )
  );

basic.dashboard(
  'Kubernetes Version Matrix',
  tags=['general', 'kubernetes'],
)
.addTemplate(templates.stage)
.addPanel(masterVersionPanel, gridPos={ x: 0, y: 0, w: 24, h: 3 })
.addPanel(nodeVersionsPanel, gridPos={ x: 0, y: 1, w: 24, h: 18 })
