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
local text = grafana.text;
local issueSearch = import 'issue_search.libsonnet';

local DETAILS = {
  active_db_connections: {
    title: 'Active DB Connection Saturation',
    description: |||
      Active db connection saturation per node.

      Postgres is configured to use a maximum number of connections. When this resource is saturated,
      connections may queue.
    |||,
    query: |||
      sum without (state, datname) (
        pg_stat_activity_count{datname="gitlabhq_production", state!="idle", %(selector)s}
      )
      / pg_settings_max_connections{%(selector)s}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  cgroup_memory: {
    title: 'Cgroup Memory Saturation per Node',
    description: |||
      Cgroup memory saturation per node.

      Some services, notably Gitaly, are configured to run within a cgroup with a memory limit lower than the
      memory limit for the node. This ensures that a traffic spike to Gitaly does not affect other services on the node.

      If this resource is becoming saturated, this may indicate traffic spikes to Gitaly, abuse or possibly resource leaks in
      the application. Gitaly or other git processes may be killed by the OOM killer when this resource is saturated.
    |||,
    query: |||
      (
        container_memory_usage_bytes{id="/system.slice/gitlab-runsvdir.service", %(selector)s} -
        container_memory_cache{id="/system.slice/gitlab-runsvdir.service", %(selector)s} -
        container_memory_swap{id="/system.slice/gitlab-runsvdir.service", %(selector)s}
      )
      /
      container_spec_memory_limit_bytes{id="/system.slice/gitlab-runsvdir.service", %(selector)s}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  go_memory: {
    title: 'Go Memory Saturation per Node',
    description: |||
      Go's memory allocation strategy can make it look like a Go process is saturating memory when measured using RSS, when in fact
      the process is not at risk of memory saturation. For this reason, we measure Go processes using the `go_memstat_alloc_bytes`
      metric instead of RSS.
    |||,
    query: |||
      sum by (fqdn, type, tier, stage, environment) (
        go_memstats_alloc_bytes{%(selector)s}
      )
      /
      sum by (fqdn, type, tier, stage, environment) (
        node_memory_MemTotal_bytes{%(selector)s}
      )
    |||,
    legendFormat: '{{ fqdn }}',
  },

  pgbouncer_async_pool: {
    title: 'Postgres Async (Sidekiq) Connection Pool Saturation per Node',
    description: |||
      Postgres connection pool saturation per database node.

      Sidekiq maintains it's own pgbouncer connection pool. When this resource is saturated, database operations may
      queue, leading to additional latency in background processing.
    |||,
    query: |||
      (
        pgbouncer_pools_server_active_connections{user="gitlab", %(selector)s, database="gitlabhq_production_sidekiq"} +
        pgbouncer_pools_server_testing_connections{user="gitlab", %(selector)s, database="gitlabhq_production_sidekiq"} +
        pgbouncer_pools_server_used_connections{user="gitlab", %(selector)s, database="gitlabhq_production_sidekiq"} +
        pgbouncer_pools_server_login_connections{user="gitlab", %(selector)s, database="gitlabhq_production_sidekiq"}
      )
      /
      on(environment, tier, type, stage, fqdn, instance) group_left()
      sum by (environment, tier, type, stage, fqdn, instance) (
        pgbouncer_databases_pool_size{%(selector)s, name="gitlabhq_production_sidekiq"}
      )
    |||,
    legendFormat: '{{ fqdn }}: {{ database }}',
  },

  pgbouncer_sync_pool: {
    title: 'Postgres Sync (Web/API) Connection Pool Saturation per Node',
    description: |||
      Postgres sync connection pool saturation per database node.

      Web/api/git applications use a separate connection pool to sidekiq.

      When this resource is saturated, web/api database operations may queue, leading to unicorn/puma saturation and 503 errors in the web.
    |||,
    query: |||
      (
        pgbouncer_pools_server_active_connections{user="gitlab", %(selector)s, database="gitlabhq_production"} +
        pgbouncer_pools_server_testing_connections{user="gitlab", %(selector)s, database="gitlabhq_production"} +
        pgbouncer_pools_server_used_connections{user="gitlab", %(selector)s, database="gitlabhq_production"} +
        pgbouncer_pools_server_login_connections{user="gitlab", %(selector)s, database="gitlabhq_production"}
      )
      /
      on(environment, tier, type, stage, fqdn, instance) group_left()
      sum by (environment, tier, type, stage, fqdn, instance) (
        pgbouncer_databases_pool_size{%(selector)s, name="gitlabhq_production"}
      )
    |||,
    legendFormat: '{{ fqdn }}: {{ database }}',
  },

  cpu: {
    title: 'Average CPU Saturation per Node',
    description: |||
      Average CPU per Node.

      This resource measures all CPU across a fleet. If it is becoming saturated, it may indicate that the fleet needs horizontal or
      vertical scaling.
    |||,
    query: |||
      avg(1 - rate(node_cpu_seconds_total{mode="idle", %(selector)s}[$__interval])) by (fqdn)
    |||,
    legendFormat: '{{ fqdn }}',
  },

  elastic_cpu: {
    title: 'Average CPU Saturation per Node',
    description: |||
      Average CPU per Node.

      This resource measures all CPU across a fleet. If it is becoming saturated, it may indicate that the fleet needs horizontal or
      vertical scaling. The metrics are coming from elasticsearch_exporter.
    |||,
    query: |||
      avg_over_time(elasticsearch_os_cpu_percent{%(selector)s}[$__interval]) / 100
    |||,
    legendFormat: '{{ name }}',
  },

  disk_sustained_read_iops: {
    title: 'Disk Sustained Read IOPS Saturation per Node',
    description: |||
      Disk sustained read IOPS saturation per node.
    |||,
    query: |||
      rate(node_disk_reads_completed_total{type="gitaly", device="sdb", %(selector)s}[$__interval]) / (%(gitaly_disk_sustained_read_iops_maximum_magic_number)d)
      or
      rate(node_disk_reads_completed_total{type="nfs", device="sdb", %(selector)s}[$__interval]) / (%(nfs_disk_sustained_read_iops_maximum_magic_number)d)
      or
      rate(node_disk_reads_completed_total{type="patroni", device="sdb", %(selector)s}[$__interval]) / (%(patroni_disk_sustained_read_iops_maximum_magic_number)d)
    |||,  // Note, this rate is specific to the specific nodes, hence the hardcoded type here
    legendFormat: '{{ fqdn }}',
  },

  disk_sustained_read_throughput: {
    title: 'Disk Sustained Read Throughput Saturation per Node',
    description: |||
      Disk sustained read throughput saturation per node.
    |||,
    query: |||
      rate(node_disk_read_bytes_total{type="gitaly", device="sdb", %(selector)s}[$__interval]) / (%(gitaly_disk_sustained_read_throughput_bytes_maximum_magic_number)d)
      or
      rate(node_disk_read_bytes_total{type="nfs", device="sdb", %(selector)s}[$__interval]) / (%(nfs_disk_sustained_read_throughput_bytes_maximum_magic_number)d)
      or
      rate(node_disk_read_bytes_total{type="patroni", device="sdb", %(selector)s}[$__interval]) / (%(patroni_disk_sustained_read_throughput_bytes_maximum_magic_number)d)
    |||,  // Note, this rate is specific to the specific nodes, hence the hardcoded type here
    legendFormat: '{{ fqdn }}',
  },

  disk_space: {
    title: 'Disk Utilization per Device per Node',
    description: |||
      Disk utilization per device per node.
    |||,
    query: |||
      max(
        (
          1 -
          instance:node_filesystem_avail:ratio{%(selector)s ,fstype=~"ext.|xfs"}
        )
      ) by (device, fqdn)
    |||,
    legendFormat: '{{ fqdn }} {{ device }}',
  },

  elastic_disk_space: {
    title: 'Disk Utilization per Device per Node',
    description: |||
      Disk utilization per device per node.
    |||,
    query: |||
      max(
        (
          (elasticsearch_filesystem_data_size_bytes{%(selector)s} - elasticsearch_filesystem_data_free_bytes{%(selector)s})
          / elasticsearch_filesystem_data_size_bytes{%(selector)s}
        )
      ) by (name)
    |||,
    legendFormat: '{{ name }}',
  },

  disk_sustained_write_iops: {
    title: 'Disk Sustained Write IOPS Saturation per Node',
    description: |||
      Gitaly runs on Google Cloud's Persistent Disk product. This has a published sustained
      maximum write IOPS value. This value can be exceeded for brief periods.

      If a single node is consistently reaching saturation, it may indicate a noisy-neighbour repository,
      possible abuse or it may indicate that the node needs rebalancing.

      More information can be found at
      https://cloud.google.com/compute/docs/disks/performance.
    |||,
    query: |||
      rate(node_disk_writes_completed_total{type="gitaly", device="sdb", %(selector)s}[$__interval]) / (%(gitaly_disk_sustained_write_iops_maximum_magic_number)d)
      or
      rate(node_disk_writes_completed_total{type="nfs", device="sdb", %(selector)s}[$__interval]) / (%(nfs_disk_sustained_write_iops_maximum_magic_number)d)
      or
      rate(node_disk_writes_completed_total{type="patroni", device="sdb", %(selector)s}[$__interval]) / (%(patroni_disk_sustained_write_iops_maximum_magic_number)d)
    |||,  // Note, this rate is specific to the specific nodes, hence the hardcoded type here
    legendFormat: '{{ fqdn }}',
  },

  disk_sustained_write_throughput: {
    title: 'Disk Sustained Write Throughput Saturation per Node',
    description: |||
      Gitaly runs on Google Cloud's Persistent Disk product. This has a published sustained
      maximum write throughput value. This value can be exceeded for brief periods.

      If a single node is consistently reaching saturation, it may indicate a noisy-neighbour repository,
      possible abuse or it may indicate that the node needs rebalancing.

      More information can be found at
      https://cloud.google.com/compute/docs/disks/performance.
    |||,
    query: |||
      rate(node_disk_written_bytes_total{type="gitaly", device="sdb", %(selector)s}[$__interval]) / (%(gitaly_disk_sustained_write_throughput_bytes_maximum_magic_number)d)
      or
      rate(node_disk_written_bytes_total{type="nfs", device="sdb", %(selector)s}[$__interval]) / (%(nfs_disk_sustained_write_throughput_bytes_maximum_magic_number)d)
      or
      rate(node_disk_written_bytes_total{type="patroni", device="sdb", %(selector)s}[$__interval]) / (%(patroni_disk_sustained_write_throughput_bytes_maximum_magic_number)d)
    |||,  // Note, this rate is specific to the specific nodes, hence the hardcoded type here
    legendFormat: '{{ fqdn }}',
  },

  memory: {
    title: 'Memory Utilization per Node',
    description: |||
      Memory utilization per device per node.
    |||,
    query: |||
      instance:node_memory_utilization:ratio{%(selector)s}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  elastic_jvm_heap_memory: {
    title: 'JVM Heap Utilization per Node',
    description: |||
      JVM heap memory utilizationper node.
    |||,
    query: |||
      elasticsearch_jvm_memory_used_bytes{area="heap", %(selector)s} / elasticsearch_jvm_memory_max_bytes{area="heap", %(selector)s}
    |||,
    legendFormat: '{{ name }}',
  },

  open_fds: {
    title: 'Open file descriptor saturation per instance',
    description: |||
      Open file descriptor saturation per instance.

      Saturation on file descriptor limits may indicate a resource-descriptor leak in the application.

      As a temporary fix, you may want to consider restarting the affected process.
    |||,
    query: |||
      max(
        label_replace(
          process_open_fds{%(selector)s}
          /
          process_max_fds{%(selector)s}
          , "client", "general", "", ""
        )
        or
        label_replace(
          ruby_file_descriptors{%(selector)s}
          /
          ruby_process_max_fds{%(selector)s}
          , "client", "ruby", "", ""
        )
      ) by (job, instance)
    |||,
    legendFormat: '{{ job }}: {{ instance }}',
  },

  pgbouncer_single_core: {
    title: 'PGBouncer Single Core per Node',
    description: |||
      PGBouncer single core saturation per node.

      PGBouncer is a single threaded application. Under high volumes this resource may become saturated,
      and additional pgbouncer nodes may need to be provisioned.
    |||,
    query: |||
      sum(
        rate(
          namedprocess_namegroup_cpu_seconds_total{groupname=~"pgbouncer.*", %(selector)s}[1m]
        )
      ) by (groupname, fqdn, type, tier, stage, environment)
    |||,
    legendFormat: '{{ fqdn }}',
  },

  private_runners: {
    title: 'Private Runners Saturation',
    description: |||
      Private runners saturation per instance.

      Each runner manager has a maximum number of runners that it can coordinate at any single moment.

      When this metric is exceeded, new CI jobs will queue. When this occurs we should consider adding more runner managers,
      or scaling the runner managers vertically and increasing their maximum runner capacity.
    |||,
    query: |||
      sum without (state, executor_stage, exported_stage) (
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
    description: |||
      Redis client saturation per node.

      A redis server has a maximum number of clients that can connect. When this resource is saturated,
      new clients may fail to connect.

      More details at https://redis.io/topics/clients#maximum-number-of-clients
    |||,
    query: |||
      redis_connected_clients{%(selector)s}
      /
      redis_config_maxclients{%(selector)s}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  redis_memory: {
    title: 'Redis Memory Saturation per Node',
    description: |||
      Redis memory saturation per node.

      As Redis memory saturates node memory, the likelyhood of OOM kills, possibly to the Redis process,
      become more likely.

      For caches, consider lowering the `maxmemory` setting in Redis. For non-caching Redis instances,
      this has been caused in the past by credential stuffing, leading to large numbers of web sessions.
    |||,
    query: |||
      max(
        label_replace(redis_memory_used_rss_bytes{%(selector)s}, "memtype", "rss","","")
        or
        label_replace(redis_memory_used_bytes{%(selector)s}, "memtype", "used","","")
      ) by (type, tier, stage, environment, fqdn)
      / on(fqdn) group_left
      node_memory_MemTotal_bytes{%(selector)s}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  shared_runners: {
    title: 'Shared Runner Saturation',
    description: |||
      Shared runner saturation per instance.

      Each runner manager has a maximum number of runners that it can coordinate at any single moment.

      When this metric is exceeded, new CI jobs will queue. When this occurs we should consider adding more runner managers,
      or scaling the runner managers vertically and increasing their maximum runner capacity.
    |||,
    query: |||
      sum without (state, executor_stage, exported_stage) (
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
    description: |||
      Shared runners saturation per instance.

      Each runner manager has a maximum number of runners that it can coordinate at any single moment.

      When this metric is exceeded, new CI jobs will queue. When this occurs we should consider adding more runner managers,
      or scaling the runner managers vertically and increasing their maximum runner capacity.
    |||,
    query: |||
      sum without (state, executor_stage, exported_stage) (
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
    description: |||
      Sidekiq worker saturation per node.

      This metric represents the percentage of available threads*workers that are utilized actively processing jobs.

      When this metric is saturated, new Sidekiq jobs will queue. Depending on whether or not the jobs are latency sensitive,
      this could impact user experience.
    |||,
    query: |||
      sum by (fqdn, instance, environment, tier, type, stage) (sidekiq_running_jobs{%(selector)s})
      /
      sum by (fqdn, instance, environment, tier, type, stage) (sidekiq_concurrency{%(selector)s})
    |||,
    legendFormat: '{{ fqdn }}',
  },

  single_node_cpu: {
    title: 'Average CPU Saturation per Node',
    description: |||
      Average CPU per Node.

      If average CPU is satured, it may indicate that a fleet is in need to horizontal or vertical scaling. It may also indicate
      imbalances in load in a fleet.
    |||,
    component: 'single_node_cpu',
    query: |||
      avg(1 - rate(node_cpu_seconds_total{mode="idle", %(selector)s}[$__interval])) by (fqdn)
    |||,
    legendFormat: '{{ fqdn }}',
  },

  elastic_single_node_cpu: {
    title: 'Average CPU Saturation per Node',
    description: |||
      Average CPU per Node.

      This resource measures all CPU across a fleet. If it is becoming saturated, it may indicate that the fleet needs horizontal or
      vertical scaling. The metrics are coming from elasticsearch_exporter.
    |||,
    query: |||
      avg_over_time(elasticsearch_os_cpu_percent{%(selector)s}[$__interval]) / 100
    |||,
    legendFormat: '{{ name }}',
  },

  single_node_puma_workers: {
    title: 'Puma Worker Saturation per Node',
    description: |||
      Puma worker saturation per node.

      Each concurrent HTTP request being handled in the application needs a dedicated puma worker. When this resource is saturated,
      we will see puma queuing taking place. Leading to slowdowns across the application.

      Puma saturation is usually caused by latency problems in downstream services: usually Gitaly or Postgres, but possibly also Redis.
      Puma saturation can also be caused by traffic spikes.
    |||,
    component: 'single_node_puma_workers',
    query: |||
      sum by(fqdn) (avg_over_time(puma_active_connections{%(selector)s}[$__interval]))
      /
      sum by(fqdn) (puma_max_threads{pid="puma_master", %(selector)s})
    |||,
    legendFormat: '{{ fqdn }}',
  },

  single_node_unicorn_workers: {
    title: 'Unicorn Worker Saturation per Node',
    description: |||
      Unicorn worker saturation per node.

      Each concurrent HTTP request being handled in the application needs a dedicated unicorn worker. When this resource is saturated,
      we will see unicorn queuing taking place. Leading to slowdowns across the application.

      Unicorn saturation is usually caused by latency problems in downstream services: usually Gitaly or Postgres, but possibly also Redis.
      Unicorn saturation can also be caused by traffic spikes.
    |||,
    component: 'single_node_unicorn_workers',
    query: |||
      sum(avg_over_time(unicorn_active_connections{job=~"gitlab-(rails|unicorn)", %(selector)s}[$__interval])) by (fqdn)
      /
      sum(max(unicorn_workers{%(selector)s}) without (pid)) by (fqdn)
    |||,
    legendFormat: '{{ fqdn }}',
  },

  single_threaded_cpu: {
    title: 'Redis CPU Saturation per Node',
    description: |||
      Redis CPU per node.

      Redis is single-threaded. A single Redis server is only able to scale as far as a single CPU on a single host.
      When this resource is saturated, major slowdowns should be expected across the application, so avoid if at all
      possible.
    |||,
    component: 'single_threaded_cpu',
    query: |||
      instance:redis_cpu_usage:rate1m{%(selector)s}
    |||,
    legendFormat: '{{ fqdn }}',
  },

  workers: {
    title: 'Unicorn Worker Saturation per Node',
    description: |||
      Unicorn worker saturation per node.

      Each concurrent HTTP request being handled in the application needs a dedicated unicorn worker. When this resource is saturated,
      we will see unicorn queuing taking place. Leading to slowdowns across the application.

      Unicorn saturation is usually caused by latency problems in downstream services: usually Gitaly or Postgres, but possibly also Redis.
      Unicorn saturation can also be caused by traffic spikes.
    |||,
    query: |||
      sum(avg_over_time(unicorn_active_connections{job=~"gitlab-(rails|unicorn)", %(selector)s}[$__interval])) by (fqdn)
      /
      sum(max(unicorn_workers{%(selector)s}) without (pid)) by (fqdn)
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

  componentSaturationPanel(component, selector)::
    local formatConfig = {
      component: component,
      selector: selector,
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

  saturationDetailPanels(selector, components)::
    row.new(title='🌡 Saturation Details', collapse=true)
    .addPanels(layout.grid([
      self.componentSaturationPanel(component, selector)
      for component in components
    ])),

  componentSaturationHelpPanel(component)::
    local componentDetails = DETAILS[component];

    text.new(
      title='Help',
      mode='markdown',
      content=componentDetails.description + |||
        * [Find related issues on GitLab.com](%s)
      ||| % [
        issueSearch.buildInfraIssueSearch(labels=['GitLab.com Resource Saturation'], search=component),
      ]
    ),
}
