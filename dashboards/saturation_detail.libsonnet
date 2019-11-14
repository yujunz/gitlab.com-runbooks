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
local layout = import 'layout.libsonnet';
local magicNumbers = import 'magic_numbers.libsonnet';

local DETAILS = {
  active_db_connections: {
    title: 'Active DB Connection Saturation',
    description: 'Active db connection saturation per node.',
    query: |||
      sum without (state, datname) (
        pg_stat_activity_count{datname="gitlabhq_production", state!="idle", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
      )
      / pg_settings_max_connections{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  cgroup_memory: {
    title: 'Cgroup Memory Saturation per Node',
    description: 'Cgroup memory saturation per node.',
    query: |||
      (
        container_memory_usage_bytes{id="/system.slice/gitlab-runsvdir.service", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"} -
        container_memory_cache{id="/system.slice/gitlab-runsvdir.service", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"} -
        container_memory_swap{id="/system.slice/gitlab-runsvdir.service", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
      )
      /
      container_spec_memory_limit_bytes{id="/system.slice/gitlab-runsvdir.service", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  pgbouncer_async_pool: {
    title: 'Postgres Async (Sidekiq) Connection Pool Saturation per Node',
    description: 'Postgres connection pool saturation per database node.',
    query: |||
      (
        pgbouncer_pools_server_active_connections{user="gitlab", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", database="gitlabhq_production_sidekiq"} +
        pgbouncer_pools_server_testing_connections{user="gitlab", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", database="gitlabhq_production_sidekiq"} +
        pgbouncer_pools_server_used_connections{user="gitlab", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", database="gitlabhq_production_sidekiq"} +
        pgbouncer_pools_server_login_connections{user="gitlab", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", database="gitlabhq_production_sidekiq"}
      )
      /
      %(pgbouncer_async_pool_size_magic_number)d
    |||,
    legendFormat: '{{ fqdn }}: {{ database }}',
  },

  pgbouncer_sync_pool: {
    title: 'Postgres Sync (Web/API) Connection Pool Saturation per Node',
    description: 'Postgres sync connection pool saturation per database node.',
    query: |||
      (
        pgbouncer_pools_server_active_connections{user="gitlab", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", database="gitlabhq_production"} +
        pgbouncer_pools_server_testing_connections{user="gitlab", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", database="gitlabhq_production"} +
        pgbouncer_pools_server_used_connections{user="gitlab", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", database="gitlabhq_production"} +
        pgbouncer_pools_server_login_connections{user="gitlab", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", database="gitlabhq_production"}
      )
      /
      %(pgbouncer_sync_pool_size_magic_number)d
    |||,
    legendFormat: '{{ fqdn }}: {{ database }}',
  },

  cpu: {
    title: 'Average CPU Saturation per Node',
    description: 'Average CPU per Node.',
    query: |||
        avg(1 - rate(node_cpu_seconds_total{mode="idle", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval])) by (fqdn)
      |||,
    legendFormat: '{{ fqdn }}',
  },

  disk_sustained_read_iops: {
    title: 'Disk Sustained Read IOPS Saturation per Node',
    description: 'Disk sustained read IOPS saturation per node.',
    query: |||
      rate(node_disk_reads_completed_total{type="gitaly", device="sdb", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]) / (%(gitaly_disk_sustained_read_iops_maximum_magic_number)d)
    |||,  // Note, this rate is specific to our gitaly nodes, hence the hardcoded Gitaly type here
    legendFormat: '{{ fqdn }}',
  },

  disk_sustained_read_throughput: {
    title: 'Disk Sustained Read Throughput Saturation per Node',
    description: 'Disk sustained read throughput saturation per node.',
    query: |||
      rate(node_disk_read_bytes_total{type="gitaly", device="sdb", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]) / (%(gitaly_disk_sustained_read_throughput_bytes_maximum_magic_number)d)
    |||,  // Note, this rate is specific to our gitaly nodes, hence the hardcoded Gitaly type here
    legendFormat: '{{ fqdn }}',
  },

  disk_space: {
    title: 'Disk Utilization per Device per Node',
    description: 'Disk utilization per device per node.',
    query: |||
        max(
          (
            (
              node_filesystem_size_bytes{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", fstype=~"ext.|xfs"}
              -
              node_filesystem_free_bytes{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", fstype=~"ext.|xfs"}
            )
            /
            node_filesystem_size_bytes{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s", fstype=~"ext.|xfs"}
          )
        ) by (device, fqdn)
      |||,
    legendFormat: '{{ fqdn }} {{ device }}',
  },

  disk_sustained_write_iops: {
    title: 'Disk Sustained Write IOPS Saturation per Node',
    description: 'Disk sustained write IOPS saturation per node.',
    query: |||
      rate(node_disk_writes_completed_total{type="gitaly", device="sdb", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]) / (%(gitaly_disk_sustained_write_iops_maximum_magic_number)d)
    |||,  // Note, this rate is specific to our gitaly nodes, hence the hardcoded Gitaly type here
    legendFormat: '{{ fqdn }}',
  },

  disk_sustained_write_throughput: {
    title: 'Disk Sustained Write Throughput Saturation per Node',
    description: 'Disk sustained write throughput saturation per node.',
    query: |||
      rate(node_disk_written_bytes_total{type="gitaly", device="sdb", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval]) / (%(gitaly_disk_sustained_write_throughput_bytes_maximum_magic_number)d)
    |||,  // Note, this rate is specific to our gitaly nodes, hence the hardcoded Gitaly type here
    legendFormat: '{{ fqdn }}',
  },

  memory: {
    title: 'Memory Utilization per Node',
    description: 'Disk utilization per device per node.',
    query: |||
      instance:node_memory_utilization:ratio{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  open_fds: {
    title: 'Open file descriptor saturation per instance',
    description: 'Open file descriptor saturation per instance.',
    query: |||
      max(
        label_replace(
          process_open_fds{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
          /
          process_max_fds{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
          , "client", "general", "", ""
        )
        or
        label_replace(
          ruby_file_descriptors{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
          /
          ruby_process_max_fds{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
          , "client", "ruby", "", ""
        )
      ) by (job, instance)
    |||,
    legendFormat: '{{ job }}: {{ instance }}',
  },

  pgbouncer_single_core: {
    title: 'PGBouncer Single Core per Node',
    description: 'PGBouncer single core saturation per node.',
    query: |||
      sum(
        rate(
          namedprocess_namegroup_cpu_seconds_total{groupname=~"pgbouncer.*", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[1m]
        )
      ) by (groupname, fqdn, type, tier, stage, environment)
    |||,
    legendFormat: '{{ fqdn }}',
  },

  private_runners: {
    title: 'Private Runners Saturation',
    description: 'Private runners saturation per instance.',
    query: |||
      sum without (stage, state, executor_stage) (
        gitlab_runner_jobs{job="private-runners"}
      )
      /
      (
        gitlab_runner_limit{job="private-runners"}
        > 0
      )
    |||,
    legendFormat: '{{ instance }}',
  },

  redis_clients: {
    title: 'Redis Client Saturation per Node',
    description: 'Redis client saturation per node.',
    query: |||
      redis_connected_clients{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
      /
      redis_config_maxclients{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  redis_memory: {
    title: 'Redis Memory Saturation per Node',
    description: 'Redis memory saturation per node.',
    query: |||
      max(
        label_replace(redis_memory_used_rss_bytes{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}, "memtype", "rss","","")
        or
        label_replace(redis_memory_used_bytes{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}, "memtype", "used","","")
      ) by (type, tier, stage, environment, fqdn)
      / on(fqdn) group_left
      node_memory_MemTotal_bytes{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  shared_runners: {
    title: 'Shared Runner Saturation',
    description: 'Shared runner saturation per instance.',
    query: |||
      sum without (stage, state, executor_stage) (
        gitlab_runner_jobs{job="shared-runners"}
      )
      /
      (
        gitlab_runner_limit{job="shared-runners"}
        > 0
      )
    |||,
    legendFormat: '{{ instance }}',
  },

  shared_runners_gitlab: {
    title: 'Shared Runner GitLab Saturation',
    description: 'Shared runners saturation per instance.',
    query: |||
      sum without (stage, state, executor_stage) (
        gitlab_runner_jobs{job="shared-runners-gitlab-org"}
      )
      /
      (
        gitlab_runner_limit{job="shared-runners-gitlab-org"}
        > 0
      )
    |||,
    legendFormat: '{{ instance }}',
  },

  sidekiq_workers: {
    title: 'Sidekiq Worker Saturation per Node',
    description: 'Sidekiq worker saturation per node.',
    query: |||
      sum without (queue) (sidekiq_running_jobs{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"})
      /
      sidekiq_concurrency{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  single_node_cpu: {
    title: 'Average CPU Saturation per Node',
    description: 'Average CPU per Node.',
    component: 'single_node_cpu',
    query: |||
        avg(1 - rate(node_cpu_seconds_total{mode="idle", type="%(serviceType)s", environment="$environment", stage="%(serviceStage)s"}[$__interval])) by (fqdn)
      |||,
    legendFormat: '{{ fqdn }}',
  },

  single_node_unicorn_workers: {
    title: 'Unicorn Worker Saturation per Node',
    description: 'Worker saturation per node.',
    component: 'single_node_unicorn_workers',
    query: |||
      sum(avg_over_time(unicorn_active_connections{job=~"gitlab-(rails|unicorn)", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval])) by (fqdn)
      /
      sum(max(unicorn_workers{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}) without (pid)) by (fqdn)
    |||,
    legendFormat: '{{ fqdn }}',
  },

  single_threaded_cpu: {
    title: 'Redis CPU Saturation per Node',
    description: 'Redis CPU per node.',
    component: 'single_threaded_cpu',
    query: |||
      instance:redis_cpu_usage:rate1m{environment="$environment", type="%(serviceType)s"}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  workers: {
    title: 'Unicorn Worker Saturation per Node',
    description: 'Worker saturation per node.',
    query: |||
      sum(avg_over_time(unicorn_active_connections{job=~"gitlab-(rails|unicorn)", environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}[$__interval])) by (fqdn)
      /
      sum(max(unicorn_workers{environment="$environment", type="%(serviceType)s", stage="%(serviceStage)s"}) without (pid)) by (fqdn)
    |||,
    legendFormat: '{{ fqdn }}',
  },
};

{
  saturationPanel(title, description, component, linewidth=1, query, legendFormat)::
    local formatConfig = {
      component: component,
      query: query,
    } + magicNumbers.magicNumbers;
    graphPanel.new(
      title,
      description,
      sort='decreasing',
      linewidth=linewidth,
      fill=0,
      datasource='$PROMETHEUS_DS',
      decimals=2,
      legend_show=true,
      legend_values=true,
      legend_min=true,
      legend_max=true,
      legend_current=true,
      legend_total=false,
      legend_avg=true,
      legend_alignAsTable=true,
      legend_hideEmpty=true,
    )
    .addTarget(  // Primary metric
      promQuery.target(
        |||
          clamp_min(
            clamp_max(
              %(query)s
            ,1)
          ,0)
        ||| % formatConfig,
        legendFormat=legendFormat,
      )
    )
    .addTarget(  // Soft SLO
      promQuery.target(
        |||
          avg(slo:max:soft:gitlab_component_saturation:ratio{component="%(component)s"}) by (component)
        ||| % formatConfig,
        legendFormat='Soft SLO: {{ component }}',
      )
    )
    .addTarget(  // Hard SLO
      promQuery.target(
        |||
          avg(slo:max:hard:gitlab_component_saturation:ratio{component="%(component)s"}) by (component)
        ||| % formatConfig,
        legendFormat='Hard SLO: {{ component }}',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label='Saturation %',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    )
    .addSeriesOverride(seriesOverrides.softSlo)
    .addSeriesOverride(seriesOverrides.hardSlo),

  componentSaturationPanel(component, serviceType, serviceStage)::
    local formatConfig = {
      component: component,
      serviceType: serviceType,
      serviceStage: serviceStage,
    } + magicNumbers.magicNumbers;
    local componentDetails = DETAILS[component];
    local query = componentDetails.query % formatConfig;

    self.saturationPanel(
      '%s component saturation: %s' % [component, componentDetails.title],
      description=componentDetails.description + ' Lower is better.',
      component=component,
      linewidth=1,
      query=query,
      legendFormat=componentDetails.legendFormat
    ),

  saturationDetailPanels(serviceType, serviceStage, components)::
    row.new(title='🌡 Saturation Details', collapse=true)
      .addPanels(layout.grid([
        self.componentSaturationPanel(component, serviceType, serviceStage)
for component in components
      ])),
}
