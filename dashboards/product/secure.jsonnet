local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local annotation = grafana.annotation;
local productCommon = import 'product_common.libsonnet';

basic.dashboard(
  title='Performance - Secure',
  time_from='now-30d',
  tags=['product performance'],
).addLink(
  productCommon.productDashboardLink(),
).addLink(
  productCommon.pageDetailLink(),
).addTemplate(
  template.interval('function', 'min, mean, median, p90, max', 'median'),
).addPanel(
  grafana.text.new(
    title='Overview',
    mode='markdown',
    content='### Synthetic tests of GitLab.com pages for the Secure group.\n\nFor more information, please see: https://about.gitlab.com/handbook/product/product-processes/#page-load-performance-metrics\n\n\n\n',
  ), gridPos={ h: 3, w: 24, x: 0, y: 0 }
).addPanel(
  row.new(title='Threat Insights'), gridPos={ x: 0, y: 1000, w: 24, h: 1 }
).addPanels(
  layout.grid(
    [
      productCommon.pageDetail('Merge Request', 'Secure_Merge_Request', 'https://gitlab.com/gitlab-examples/security/security-reports/-/merge_requests/39'),
      productCommon.pageDetail('Instance Security Dashboard', 'Secure_Instance_Security_Dashboard', 'https://gitlab.com/-/security'),
      productCommon.pageDetail('Group Security Dashboard', 'Secure_Group_Security_Dashboard', 'https://gitlab.com/groups/gitlab-examples/security/-/security/dashboard'),
    ],
    startRow=1001,
  ),
).addPanel(
  row.new(title='Composition Analysis'), gridPos={ x: 0, y: 2000, w: 24, h: 1 }
).addPanels(
  layout.grid(
    [
      productCommon.pageDetail('License Compliance', 'Secure_License_Compliance', 'https://gitlab.com/gitlab-examples/security/security-reports/-/licenses#licenses'),
      productCommon.pageDetail('Dependency List', 'Secure_Dependency_List', 'https://gitlab.com/gitlab-examples/security/security-reports/-/dependencies'),
    ],
    startRow=2001,
  ),
)
