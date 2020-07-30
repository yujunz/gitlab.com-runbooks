local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local colors = import 'grafana/colors.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local capacityPlanning = import 'capacity_planning.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local redisCommon = import 'redis_common_graphs.libsonnet';
local nodeMetrics = import 'node_metrics.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local text = grafana.text;

{
  rcaLayout(sections)::
    std.flattenArrays(
      std.mapWithIndex(
        function(index, section)
          local panel = if std.objectHas(section, 'panel') then
            section.panel
          else
            basic.timeseries(
              title='',
              query=section.query,
              legendFormat=if std.objectHas(section, 'legendFormat') then section.legendFormat else '',
              format='short',
              interval='1m',
              linewidth=1,
              intervalFactor=5,
            );
          [
            text.new(
              title='',
              mode='markdown',
              content=section.description
            ) + {
              gridPos: {
                x: 0,
                y: index * 12,
                w: 6,
                h: 12,
              },
            },
            panel {
              gridPos: {
                x: 6,
                y: index * 12,
                w: 18,
                h: 12,
              },
            },

          ],
        sections
      )
    ),

}
