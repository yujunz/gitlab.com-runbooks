local grafana = import 'grafonnet/grafana.libsonnet';

local layout = import 'layout.libsonnet';
local panels = import 'panels.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local templates = import 'templates.libsonnet';

#######################################
# ARC                                 #
#######################################

local arcHitRatePanel = panels.generalPercentageGraphPanel("ZFS ARC Hit Rate")
  .addTarget(
    promQuery.target('
      node_zfs_arc_hits{env="$environment", type="$type"}
      /
      (node_zfs_arc_hits{env="$environment", type="$type"} + node_zfs_arc_misses{env="$environment", type="$type"})
    ',
    legendFormat='{{instance}}')
  );

local arcDemandHitRatePanel = panels.generalPercentageGraphPanel("ZFS ARC Demand Hit Rate")
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
      min by (device) (node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"})
    ',
    legendFormat='Limit ({{device}})')
  )
  .addTarget(
    promQuery.target('
      node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
      -
      node_filesystem_free_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
    ',
    legendFormat='{{instance}} {{device}}')
  );

local totalFsUtilizationPanel = panels.generalBytesGraphPanel("Total Filesystem Utilization")
  .addTarget(
    promQuery.target('
      sum by (device) (node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"})
    ',
    legendFormat='Limit ({{device}})')
  )
  .addTarget(
    promQuery.target('
      sum by (device)
      (
        node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
        -
        node_filesystem_free_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
      )
    ',
    legendFormat='All Instances ({{device}})')
  );

local zfsFsUtilizationPanel = panels.generalBytesGraphPanel("Filesystem Utilization (ZFS)")
  .addTarget(
    promQuery.target('
      min (node_filesystem_size_bytes{device="tank/reservation", env="$environment", type="$type"})
    ',
    legendFormat='Absolute Limit')
  )
  .addTarget(
    promQuery.target('
      min (node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"})
    ',
    legendFormat='Limit excluding reservation')
  )
  .addTarget(
    promQuery.target('
      node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"}
      -
      node_filesystem_free_bytes{device="tank/dataset", env="$environment", type="$type"}
    ',
    legendFormat='{{instance}}')
  );

local totalZfsFsUtilizationPanel = panels.generalBytesGraphPanel("Total Filesystem Utilization (ZFS)")
  .addTarget(
    promQuery.target('
      sum (node_filesystem_size_bytes{device="tank/reservation", env="$environment", type="$type"})
    ',
    legendFormat='Absolute Limit')
  )
  .addTarget(
    promQuery.target('
      sum (node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"})
    ',
    legendFormat='Limit excluding reservation')
  )
  .addTarget(
    promQuery.target('
      sum
      (
        node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"}
        -
        node_filesystem_free_bytes{device="tank/dataset", env="$environment", type="$type"}
      )
    ',
    legendFormat='All Instances')
  );

grafana.dashboard.new(
  'Filesystems',
  schemaVersion=16,
  tags=[],
  timezone='UTC',
  graphTooltip='shared_crosshair',
  refresh='30s',
)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addTemplate(templates.type)
.addPanels(layout.grid([
  fsUtilizationPanel, totalFsUtilizationPanel,
  zfsFsUtilizationPanel, totalZfsFsUtilizationPanel,
  arcHitRatePanel, arcDemandHitRatePanel,
], cols=2, rowHeight=10))
