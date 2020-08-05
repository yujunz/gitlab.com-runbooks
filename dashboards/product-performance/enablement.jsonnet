local basic = import 'grafana/basic.libsonnet';
local colors = import 'grafana/colors.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local grafite = grafana.grafite;

local datasource = 'sitespeed new';

local pageSpeed(title, page_alias, url) = 
  graphPanel.new(
    title,
    datasource,
    description = page_alias,
  ).addSeriesOverride({
      "alias": "LastVisualChange",
      "color": "#E0B400",
      "fillBelowTo": "FirstVisualChange",
      "lines": false,
  }).addTarget(
    grafite.target(
      "aliasByNode(sitespeed_io.desktop.pageSummary.gitlab_com." + page_alias + ".chrome.cable.browsertime.statistics.visualMetrics.FirstVisualChange.$function, 10)"
      ),
  ).addTarget(
    grafite.target(
      "aliasByNode(sitespeed_io.desktop.pageSummary.gitlab_com." + page_alias + ".chrome.cable.browsertime.statistics.visualMetrics.LastVisualChange.$function, 10)"
    ),
  ).addTarget(
    grafite.target(
      "aliasByNode(sitespeed_io.desktop.pageSummary.gitlab_com." + page_alias + ".chrome.cable.browsertime.statistics.timings.largestContentfulPaint.renderTime.$function, 10)"
    ),
  );

  dashboard.new(
    title = "Performance - Enablement",
    time_from = "now-7d",
    tags = ["product performance"],
  ).addTemplate(
      template.interval("function", "min, mean, median, p90, max", "median"),
  ).addPanel(
    grafana.text.new(
      title = "Apdex by Feature Category Help",
      mode = "markdown",
      content = "### Synthetic tests of GitLab.com pages for the Enablement group.\n\nFor more information, please see: https://gitlab.com/gitlab-org/gitlab/-/issues/221018\n\n\n\n",
    ),
  ).addPanel(
    row.new(title='Global Search'),
    gridPos={
      "x": 0,
      "y": 1000,
      "w": 24,
      "h": 1,
    }
  ).addPanels(
    [
      pageSpeed("Basic Global Search - Projects", "Basic_Search_Projects", "https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=&repository_ref=&search=gitlab") { "gridPos": { "h": 8, "w": 12}, },
    ]
  )