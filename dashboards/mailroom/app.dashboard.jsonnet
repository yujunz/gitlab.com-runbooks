local basic = import 'grafana/basic.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local common = import 'container_common_graphs.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;

basic.dashboard(
  'Application Info',
  tags=['mailroom'],
)
.addTemplate(templates.gkeCluster)
.addTemplate(templates.namespaceGitlab)
.addTemplate(
  template.custom(
    'Deployment',
    'gitlab-mailroom,',
    'gitlab-mailroom',
    hide='variable',
  )
).addPanel(

  row.new(title='Stackdriver Metrics'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(common.logMessages(startRow=1))
.addPanel(

  row.new(title='Mailroom Metrics'),
  gridPos={
    x: 0,
    y: 100,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Unread Emails',
      description='Number of unread messages',
      query='max(imap_nb_unread_messages_in_mailbox{environment=~"$environment"})',
      interval='1m',
      intervalFactor=2,
      legendFormat='Count',
      yAxisLabel='',
      legend_show=true,
      linewidth=2
    ),
  ], cols=1, rowHeight=10, startRow=101)
)
