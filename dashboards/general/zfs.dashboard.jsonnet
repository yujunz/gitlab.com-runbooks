local grafana = import 'grafonnet/grafana.libsonnet';

local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';
local panels = import 'panels.libsonnet';

#######################################
# ARC                                 #
#######################################

local arcHitRatePanel = panels.generalPercentageGraphPanel("ARC Hit Rate")
  .addTarget(
    promQuery.target('
      node_zfs_arc_hits{env="$environment", type="$type"}
      /
      (node_zfs_arc_hits{env="$environment", type="$type"} + node_zfs_arc_misses{env="$environment", type="$type"})
    ',
    legendFormat='{{instance}}')
  );

local arcDemandHitRatePanel = panels.generalPercentageGraphPanel("ARC Demand Hit Rate")
  .addTarget(
    promQuery.target('
      (node_zfs_arc_demand_data_hits{env="$environment", type="$type"} + node_zfs_arc_demand_metadata_hits{env="$environment", type="$type"})
      /
      (
        node_zfs_arc_demand_data_hits{env="$environment", type="$type"} + node_zfs_arc_demand_metadata_hits{env="$environment", type="$type"}
        + node_zfs_arc_demand_data_misses{env="$environment", type="$type"} + node_zfs_arc_demand_metadata_misses{env="$environment", type="$type"}
      )
    ',
    legendFormat='{{instance}}')
  );

#######################################
# Utilization                         #
#######################################

local fsUtilizationPanel = panels.generalBytesGraphPanel("Filesystem Utilization")
  .addTarget(
    promQuery.target('
      min by (instance) (node_filesystem_size_bytes{device="tank/reservation", env="$environment", type = "$type"})
    ',
    legendFormat='Absolute Limit')
  )
  .addTarget(
    promQuery.target('
      min by (instance) (node_filesystem_size_bytes{device="tank/dataset", env="$environment", type = "$type"})
    ',
    legendFormat='Limit excluding reservation')
  )
  .addTarget(
    promQuery.target('
      node_filesystem_size_bytes{device="tank/dataset", env="$environment", type = "$type"}
      -
      node_filesystem_free_bytes{device="tank/dataset", env="$environment", type = "$type"}
    ',
    legendFormat='{{instance}}')
  );

local totalFsUtilizationPanel = panels.generalBytesGraphPanel("Total Filesystem Utilization")
  .addTarget(
    promQuery.target('
      sum by (instance) (node_filesystem_size_bytes{device="tank/reservation", env="$environment", type = "$type"})
    ',
    legendFormat='Absolute Limit')
  )
  .addTarget(
    promQuery.target('
      sum by (instance) (node_filesystem_size_bytes{device="tank/dataset", env="$environment", type = "$type"})
    ',
    legendFormat='Limit excluding reservation')
  )
  .addTarget(
    promQuery.target('
      sum by (instance)
      (
        node_filesystem_size_bytes{device="tank/dataset", env="$environment", type = "$type"}
        -
        node_filesystem_free_bytes{device="tank/dataset", env="$environment", type = "$type"}
      )
    ',
    legendFormat='All Instances')
  );

grafana.dashboard.new(
  'ZFS',
  schemaVersion=16,
  tags=[],
  timezone='UTC',
  graphTooltip='shared_crosshair',
  refresh='30s',
)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.type)
.addPanel(fsUtilizationPanel, gridPos={
  x: 0,
  y: 0,
  w: 12,
  h: 10,
})
.addPanel(totalFsUtilizationPanel, gridPos={
  x: 12,
  y: 0,
  w: 12,
  h: 10,
})
.addPanel(arcHitRatePanel, gridPos={
  x: 0,
  y: 10,
  w: 12,
  h: 10,
})
.addPanel(arcDemandHitRatePanel, gridPos={
  x: 12,
  y: 10,
  w: 12,
  h: 10,
})
