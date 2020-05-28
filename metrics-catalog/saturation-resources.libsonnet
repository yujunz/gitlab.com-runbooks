local resourceSaturationPoint = (import './lib/resource-saturation-point.libsonnet').resourceSaturationPoint;

{
  active_db_connections: resourceSaturationPoint({
    title: 'Active DB Connection Saturation',
    appliesTo: ['patroni'],
    description: |||
      Active db connection saturation per node.

      Postgres is configured to use a maximum number of connections. When this resource is saturated,
      connections may queue.
    |||,
    grafana_dashboard_uid: 'sat_active_db_connections',
    resourceLabels: ['fqdn'],
    query: |||
      sum without (state) (
        pg_stat_activity_count{datname="gitlabhq_production", state!="idle", %(selector)s}
      )
      / on (%(aggregationLabels)s)
      pg_settings_max_connections{%(selector)s}
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  rails_db_connection_pool: resourceSaturationPoint({
    title: 'Rails DB Connection Pool Saturation',
    appliesTo: ['web', 'api', 'git', 'sidekiq'],
    description: |||
      Rails uses connection pools for its database connections. As each
      node may have multiple connection pools, this is by node and by
      database host.

      If this resource is saturated, it may indicate that our connection
      pools are not correctly sized, perhaps because an unexpected
      application thread is using a database connection.
    |||,
    grafana_dashboard_uid: 'sat_rails_db_connection_pool',
    resourceLabels: ['fqdn', 'host', 'port'],
    burnRatePeriod: '5m',
    query: |||
      (
        avg_over_time(gitlab_database_connection_pool_busy{class="ActiveRecord::Base", %(selector)s}[%(rangeInterval)s])
        +
        avg_over_time(gitlab_database_connection_pool_dead{class="ActiveRecord::Base", %(selector)s}[%(rangeInterval)s])
      )
      /
      gitlab_database_connection_pool_size{class="ActiveRecord::Base", %(selector)s}
    |||,
    slos: {
      soft: 0.90,
      hard: 0.99,
      alert_trigger_duration: 'long',
    },
  }),

  cgroup_memory: resourceSaturationPoint({
    title: 'Cgroup Memory Saturation per Node',
    appliesTo: ['gitaly', 'praefect'],
    description: |||
      Cgroup memory saturation per node.

      Some services, notably Gitaly, are configured to run within a cgroup with a memory limit lower than the
      memory limit for the node. This ensures that a traffic spike to Gitaly does not affect other services on the node.

      If this resource is becoming saturated, this may indicate traffic spikes to Gitaly, abuse or possibly resource leaks in
      the application. Gitaly or other git processes may be killed by the OOM killer when this resource is saturated.
    |||,
    grafana_dashboard_uid: 'sat_cgroup_memory',
    resourceLabels: ['fqdn'],
    query: |||
      (
        container_memory_usage_bytes{id="/system.slice/gitlab-runsvdir.service", %(selector)s} -
        container_memory_cache{id="/system.slice/gitlab-runsvdir.service", %(selector)s} -
        container_memory_swap{id="/system.slice/gitlab-runsvdir.service", %(selector)s}
      )
      /
      container_spec_memory_limit_bytes{id="/system.slice/gitlab-runsvdir.service", %(selector)s}
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  cpu: resourceSaturationPoint({
    title: 'Average Service CPU',
    appliesTo: { allExcept: ['waf', 'console-node', 'deploy-node'] },
    description: |||
      This resource measures average CPU across an all cores in a service fleet.
      If it is becoming saturated, it may indicate that the fleet needs
      horizontal or vertical scaling.
    |||,
    grafana_dashboard_uid: 'sat_cpu',
    resourceLabels: [],
    query: |||
      1 - avg by (%(aggregationLabels)s) (
        rate(node_cpu_seconds_total{mode="idle", %(selector)s}[%(rangeInterval)s])
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  shard_cpu: resourceSaturationPoint({
    title: 'Average CPU per Shard',
    appliesTo: { allExcept: ['waf', 'console-node', 'deploy-node'], default: 'sidekiq' },
    description: |||
      This resource measures average CPU across an all cores in a shard of a
      service fleet. If it is becoming saturated, it may indicate that the
      shard needs horizontal or vertical scaling.
    |||,
    grafana_dashboard_uid: 'sat_shard_cpu',
    resourceLabels: ['shard'],
    query: |||
      1 - avg by (%(aggregationLabels)s) (
        rate(node_cpu_seconds_total{mode="idle", %(selector)s}[%(rangeInterval)s])
      )
    |||,
    slos: {
      soft: 0.85,
      hard: 0.95,
    },
  }),

  disk_space: resourceSaturationPoint({
    title: 'Disk Utilization per Device per Node',
    appliesTo: { allExcept: ['waf', 'bastion'], default: 'gitaly' },
    description: |||
      Disk utilization per device per node.
    |||,
    grafana_dashboard_uid: 'sat_disk_space',
    resourceLabels: ['fqdn', 'device'],
    query: |||
      (
        1 - instance:node_filesystem_avail:ratio{fstype=~"ext.|xfs", %(selector)s}
      )
    |||,
    slos: {
      soft: 0.85,
      hard: 0.90,
    },
  }),

  disk_sustained_read_iops: resourceSaturationPoint({
    title: 'Disk Sustained Read IOPS Saturation per Node',
    appliesTo: { allExcept: ['waf', 'bastion', 'deploy-node'], default: 'patroni' },
    description: |||
      Disk sustained read IOPS saturation per node.
    |||,
    grafana_dashboard_uid: 'sat_disk_sus_read_iops',
    resourceLabels: ['fqdn', 'device'],
    query: |||
      rate(node_disk_reads_completed_total{%(selector)s}[%(rangeInterval)s])
      /
      node_disk_max_read_iops{%(selector)s}
    |||,
    burnRatePeriod: '20m',
    slos: {
      soft: 0.80,
      hard: 0.90,
      alert_trigger_duration: 'long',
    },
  }),

  disk_sustained_read_throughput: resourceSaturationPoint({
    title: 'Disk Sustained Read Throughput Saturation per Node',
    appliesTo: { allExcept: ['waf', 'bastion', 'deploy-node'], default: 'patroni' },
    description: |||
      Disk sustained read throughput saturation per node.
    |||,
    grafana_dashboard_uid: 'sat_disk_sus_read_throughput',
    resourceLabels: ['fqdn', 'device'],
    query: |||
      rate(node_disk_read_bytes_total{%(selector)s}[%(rangeInterval)s])
      /
      node_disk_max_read_bytes_seconds{%(selector)s}
    |||,
    burnRatePeriod: '20m',
    slos: {
      soft: 0.70,
      hard: 0.80,
      alert_trigger_duration: 'long',
    },
  }),

  disk_sustained_write_iops: resourceSaturationPoint({
    title: 'Disk Sustained Write IOPS Saturation per Node',
    appliesTo: { allExcept: ['waf', 'bastion', 'deploy-node'], default: 'patroni' },
    description: |||
      Gitaly runs on Google Cloud's Persistent Disk product. This has a published sustained
      maximum write IOPS value. This value can be exceeded for brief periods.

      If a single node is consistently reaching saturation, it may indicate a noisy-neighbour repository,
      possible abuse or it may indicate that the node needs rebalancing.

      More information can be found at
      https://cloud.google.com/compute/docs/disks/performance.
    |||,
    grafana_dashboard_uid: 'sat_disk_sus_write_iops',
    resourceLabels: ['fqdn', 'device'],
    query: |||
      rate(node_disk_writes_completed_total{%(selector)s}[%(rangeInterval)s])
      /
      node_disk_max_write_iops{%(selector)s}
    |||,
    burnRatePeriod: '20m',
    slos: {
      soft: 0.80,
      hard: 0.90,
      alert_trigger_duration: 'long',
    },
  }),

  disk_sustained_write_throughput: resourceSaturationPoint({
    title: 'Disk Sustained Write Throughput Saturation per Node',
    appliesTo: { allExcept: ['waf', 'bastion', 'deploy-node'], default: 'patroni' },
    description: |||
      Gitaly runs on Google Cloud's Persistent Disk product. This has a published sustained
      maximum write throughput value. This value can be exceeded for brief periods.

      If a single node is consistently reaching saturation, it may indicate a noisy-neighbour repository,
      possible abuse or it may indicate that the node needs rebalancing.

      More information can be found at
      https://cloud.google.com/compute/docs/disks/performance.
    |||,
    grafana_dashboard_uid: 'sat_disk_sus_write_throughput',
    resourceLabels: ['fqdn', 'device'],
    query: |||
      rate(node_disk_written_bytes_total{%(selector)s}[%(rangeInterval)s])
      /
      node_disk_max_write_bytes_seconds{%(selector)s}
    |||,
    burnRatePeriod: '20m',
    slos: {
      soft: 0.70,
      hard: 0.80,
      alert_trigger_duration: 'long',
    },
  }),

  elastic_cpu: resourceSaturationPoint({
    title: 'Average CPU Saturation per Node',
    appliesTo: ['logging', 'search'],
    description: |||
      Average CPU per Node.

      This resource measures all CPU across a fleet. If it is becoming saturated, it may indicate that the fleet needs horizontal or
      vertical scaling. The metrics are coming from elasticsearch_exporter.
    |||,
    grafana_dashboard_uid: 'sat_elastic_cpu',
    resourceLabels: [],
    query: |||
      avg by (%(aggregationLabels)s) (
        avg_over_time(elasticsearch_os_cpu_percent{%(selector)s}[%(rangeInterval)s]) / 100
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  elastic_disk_space: resourceSaturationPoint({
    title: 'Disk Utilization Overall',
    appliesTo: ['logging', 'search'],
    description: |||
      Disk utilization per device per node.
    |||,
    grafana_dashboard_uid: 'sat_elastic_disk_space',
    resourceLabels: [],
    query: |||
      sum by (%(aggregationLabels)s) (
        (elasticsearch_filesystem_data_size_bytes{%(selector)s} - elasticsearch_filesystem_data_free_bytes{%(selector)s})
      )
      /
      sum by (%(aggregationLabels)s) (
        elasticsearch_filesystem_data_size_bytes{%(selector)s}
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  elastic_jvm_heap_memory: resourceSaturationPoint({
    title: 'JVM Heap Utilization per Node',
    appliesTo: ['logging', 'search'],
    description: |||
      JVM heap memory utilization per node.
    |||,
    grafana_dashboard_uid: 'sat_elastic_jvm_heap_memory',
    resourceLabels: ['name'],
    query: |||
      elasticsearch_jvm_memory_used_bytes{area="heap", %(selector)s}
      /
      elasticsearch_jvm_memory_max_bytes{area="heap", %(selector)s}
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  elastic_single_node_cpu: resourceSaturationPoint({
    title: 'Average CPU Saturation per Node',
    appliesTo: ['logging', 'search'],
    description: |||
      Average CPU per Node.

      This resource measures all CPU across a fleet. If it is becoming saturated, it may indicate that the fleet needs horizontal or
      vertical scaling. The metrics are coming from elasticsearch_exporter.
    |||,
    grafana_dashboard_uid: 'sat_elastic_single_node_cpu',
    resourceLabels: ['name'],
    query: |||
      avg_over_time(elasticsearch_os_cpu_percent{%(selector)s}[%(rangeInterval)s]) / 100
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  elastic_single_node_disk_space: resourceSaturationPoint({
    title: 'Disk Utilization per Device per Node',
    appliesTo: ['logging', 'search'],
    description: |||
      Disk utilization per device per node.
    |||,
    grafana_dashboard_uid: 'sat_elastic_node_disk_space',
    resourceLabels: ['name'],
    query: |||
      (
        (
          elasticsearch_filesystem_data_size_bytes{%(selector)s}
          -
          elasticsearch_filesystem_data_free_bytes{%(selector)s}
        )
        /
        elasticsearch_filesystem_data_size_bytes{%(selector)s}
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  elastic_thread_pools: resourceSaturationPoint({
    title: 'Thread pool utilization',
    appliesTo: ['logging', 'search'],
    description: |||
      Saturation of each thread pool on each node.

      Descriptions of the threadpool types can be found at
      https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-threadpool.html.
    |||,
    grafana_dashboard_uid: 'sat_elastic_thread_pools',
    resourceLabels: ['name', 'exported_type'],
    query: |||
      (
        elasticsearch_thread_pool_active_count{exported_type!="snapshot", %(selector)s}
        /
        (elasticsearch_thread_pool_threads_count{exported_type!="snapshot", %(selector)s} > 0)
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  go_memory: resourceSaturationPoint({
    title: 'Go Memory Saturation per Node',
    appliesTo: ['gitaly', 'web-pages', 'monitoring', 'web', 'praefect', 'registry', 'api'],
    description: |||
      Go's memory allocation strategy can make it look like a Go process is saturating memory when measured using RSS, when in fact
      the process is not at risk of memory saturation. For this reason, we measure Go processes using the `go_memstat_alloc_bytes`
      metric instead of RSS.
    |||,
    grafana_dashboard_uid: 'sat_go_memory',
    resourceLabels: ['fqdn'],
    query: |||
      sum by (%(aggregationLabels)s) (
        go_memstats_alloc_bytes{%(selector)s}
      )
      /
      sum by (%(aggregationLabels)s) (
        node_memory_MemTotal_bytes{%(selector)s}
      )
    |||,
    slos: {
      soft: 0.90,
      hard: 0.98,
    },
  }),

  memory: resourceSaturationPoint({
    title: 'Memory Utilization per Node',
    appliesTo: { allExcept: ['waf', 'monitoring'] },
    description: |||
      Memory utilization per device per node.
    |||,
    grafana_dashboard_uid: 'sat_memory',
    resourceLabels: ['fqdn'],
    query: |||
      instance:node_memory_utilization:ratio{%(selector)s}
    |||,
    slos: {
      soft: 0.90,
      hard: 0.98,
    },
  }),

  open_fds: resourceSaturationPoint({
    title: 'Open file descriptor saturation per instance',
    appliesTo: { allExcept: ['waf'] },
    description: |||
      Open file descriptor saturation per instance.

      Saturation on file descriptor limits may indicate a resource-descriptor leak in the application.

      As a temporary fix, you may want to consider restarting the affected process.
    |||,
    grafana_dashboard_uid: 'sat_open_fds',
    resourceLabels: ['job', 'instance'],
    query: |||
      (
        process_open_fds{%(selector)s}
        /
        process_max_fds{%(selector)s}
      )
      or
      (
        ruby_file_descriptors{%(selector)s}
        /
        ruby_process_max_fds{%(selector)s}
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  pgbouncer_async_pool: resourceSaturationPoint({
    title: 'Postgres Async (Sidekiq) Connection Pool Saturation per Node',
    appliesTo: ['pgbouncer', 'patroni'],
    description: |||
      Postgres connection pool saturation per database node.

      Sidekiq maintains it's own pgbouncer connection pool. When this resource is saturated, database operations may
      queue, leading to additional latency in background processing.
    |||,
    grafana_dashboard_uid: 'sat_pgbouncer_async_pool',
    resourceLabels: ['fqdn', 'instance'],
    query: |||
      (
        pgbouncer_pools_server_active_connections{user="gitlab", database="gitlabhq_production_sidekiq", %(selector)s} +
        pgbouncer_pools_server_testing_connections{user="gitlab", database="gitlabhq_production_sidekiq", %(selector)s} +
        pgbouncer_pools_server_used_connections{user="gitlab", database="gitlabhq_production_sidekiq", %(selector)s} +
        pgbouncer_pools_server_login_connections{user="gitlab", database="gitlabhq_production_sidekiq", %(selector)s}
      )
      / on(%(aggregationLabels)s) group_left()
      sum by (%(aggregationLabels)s) (
        pgbouncer_databases_pool_size{name="gitlabhq_production_sidekiq", %(selector)s}
      )
    |||,
    slos: {
      soft: 0.90,
      hard: 0.98,
    },
  }),

  pgbouncer_single_core: resourceSaturationPoint({
    title: 'PGBouncer Single Core per Node',
    appliesTo: ['pgbouncer', 'patroni'],
    description: |||
      PGBouncer single core saturation per node.

      PGBouncer is a single threaded application. Under high volumes this resource may become saturated,
      and additional pgbouncer nodes may need to be provisioned.
    |||,
    grafana_dashboard_uid: 'sat_pgbouncer_single_core',
    resourceLabels: ['fqdn', 'groupname'],
    query: |||
      sum without(cpu, mode) (
        rate(
          namedprocess_namegroup_cpu_seconds_total{groupname=~"pgbouncer.*", %(selector)s}[1m]
        )
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  pgbouncer_sync_pool: resourceSaturationPoint({
    title: 'Postgres Sync (Web/API) Connection Pool Saturation per Node',
    appliesTo: ['pgbouncer', 'patroni'],
    description: |||
      Postgres sync connection pool saturation per database node.

      Web/api/git applications use a separate connection pool to sidekiq.

      When this resource is saturated, web/api database operations may queue, leading to unicorn/puma saturation and 503 errors in the web.
    |||,
    grafana_dashboard_uid: 'sat_pgbouncer_sync_pool',
    resourceLabels: ['fqdn', 'instance'],
    query: |||
      (
        pgbouncer_pools_server_active_connections{user="gitlab", database="gitlabhq_production", %(selector)s} +
        pgbouncer_pools_server_testing_connections{user="gitlab", database="gitlabhq_production", %(selector)s} +
        pgbouncer_pools_server_used_connections{user="gitlab", database="gitlabhq_production", %(selector)s} +
        pgbouncer_pools_server_login_connections{user="gitlab", database="gitlabhq_production", %(selector)s}
      )
      / on(%(aggregationLabels)s) group_left()
      sum by (%(aggregationLabels)s) (
        pgbouncer_databases_pool_size{name="gitlabhq_production", %(selector)s}
      )
    |||,
    slos: {
      soft: 0.85,
      hard: 0.95,
    },
  }),

  private_runners: resourceSaturationPoint({
    title: 'Private Runners Saturation',
    appliesTo: ['ci-runners'],
    description: |||
      Private runners saturation per instance.

      Each runner manager has a maximum number of runners that it can coordinate at any single moment.

      When this metric is exceeded, new CI jobs will queue. When this occurs we should consider adding more runner managers,
      or scaling the runner managers vertically and increasing their maximum runner capacity.
    |||,
    grafana_dashboard_uid: 'sat_private_runners',
    resourceLabels: ['instance'],
    staticLabels: {
      type: 'ci-runners',
      tier: 'runners',
      stage: 'main',
    },
    // TODO: remove relabelling silliness once
    // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/8456
    // is completed
    query: |||
      label_replace(
        sum without(executor_stage, exported_stage, state) (max_over_time(gitlab_runner_jobs{job="private-runners"}[%(rangeInterval)s]))
        /
        gitlab_runner_limit{job="private-runners"} > 0,
        "environment", "gprd", "environment", ""
      )
    |||,
    slos: {
      soft: 0.85,
      hard: 0.95,
    },
  }),

  redis_clients: resourceSaturationPoint({
    title: 'Redis Client Saturation per Node',
    appliesTo: ['redis', 'redis-sidekiq', 'redis-cache'],
    description: |||
      Redis client saturation per node.

      A redis server has a maximum number of clients that can connect. When this resource is saturated,
      new clients may fail to connect.

      More details at https://redis.io/topics/clients#maximum-number-of-clients
    |||,
    grafana_dashboard_uid: 'sat_redis_clients',
    resourceLabels: ['fqdn'],
    query: |||
      max_over_time(redis_connected_clients{%(selector)s}[%(rangeInterval)s])
      /
      redis_config_maxclients{%(selector)s}
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  redis_memory: resourceSaturationPoint({
    title: 'Redis Memory Saturation per Node',
    appliesTo: ['redis', 'redis-sidekiq', 'redis-cache'],
    description: |||
      Redis memory saturation per node.

      As Redis memory saturates node memory, the likelyhood of OOM kills, possibly to the Redis process,
      become more likely.

      For caches, consider lowering the `maxmemory` setting in Redis. For non-caching Redis instances,
      this has been caused in the past by credential stuffing, leading to large numbers of web sessions.
    |||,
    grafana_dashboard_uid: 'sat_redis_memory',
    resourceLabels: ['fqdn'],
    query: |||
      max by (%(aggregationLabels)s) (
        label_replace(redis_memory_used_rss_bytes{%(selector)s}, "memtype", "rss","","")
        or
        label_replace(redis_memory_used_bytes{%(selector)s}, "memtype", "used","","")
      )
      /
      avg by (%(aggregationLabels)s) (
        node_memory_MemTotal_bytes{%(selector)s}
      )
    |||,
    slos: {
      soft: 0.65,
      hard: 0.75,
    },
  }),

  shared_runners: resourceSaturationPoint({
    title: 'Shared Runner Saturation',
    appliesTo: ['ci-runners'],
    description: |||
      Shared runner saturation per instance.

      Each runner manager has a maximum number of runners that it can coordinate at any single moment.

      When this metric is exceeded, new CI jobs will queue. When this occurs we should consider adding more runner managers,
      or scaling the runner managers vertically and increasing their maximum runner capacity.
    |||,
    grafana_dashboard_uid: 'sat_shared_runners',
    resourceLabels: ['instance'],
    staticLabels: {
      type: 'ci-runners',
      tier: 'runners',
      stage: 'main',
    },
    // TODO: remove relabelling silliness once
    // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/8456
    // is completed
    query: |||
      label_replace(
        sum without(executor_stage, exported_stage, state) (max_over_time(gitlab_runner_jobs{job="shared-runners"}[%(rangeInterval)s]))
        /
        gitlab_runner_limit{job="shared-runners"} > 0,
        "environment", "gprd", "environment", ""
      )
    |||,
    slos: {
      soft: 0.90,
      hard: 0.95,
    },
  }),

  shared_runners_gitlab: resourceSaturationPoint({
    title: 'Shared Runner GitLab Saturation',
    appliesTo: ['ci-runners'],
    description: |||
      Shared runners saturation per instance.

      Each runner manager has a maximum number of runners that it can coordinate at any single moment.

      When this metric is exceeded, new CI jobs will queue. When this occurs we should consider adding more runner managers,
      or scaling the runner managers vertically and increasing their maximum runner capacity.
    |||,
    grafana_dashboard_uid: 'sat_shared_runners_gitlab',
    resourceLabels: ['instance'],
    // TODO: remove relabelling silliness once
    // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/8456
    // is completed
    query: |||
      label_replace(
        sum without(executor_stage, exported_stage, state) (max_over_time(gitlab_runner_jobs{job="shared-runners-gitlab-org"}[%(rangeInterval)s]))
        /
        gitlab_runner_limit{job="shared-runners-gitlab-org"} > 0,
        "environment", "gprd", "environment", ""
      )
    |||,
    slos: {
      soft: 0.90,
      hard: 0.95,
    },
  }),

  sidekiq_workers: resourceSaturationPoint({
    title: 'Sidekiq Worker Saturation per Node',
    appliesTo: ['sidekiq'],
    description: |||
      Sidekiq worker saturation per node.

      This metric represents the percentage of available threads*workers that are utilized actively processing jobs.

      When this metric is saturated, new Sidekiq jobs will queue. Depending on whether or not the jobs are latency sensitive,
      this could impact user experience.
    |||,
    grafana_dashboard_uid: 'sat_sidekiq_workers',
    resourceLabels: ['fqdn', 'instance', 'pod'],
    query: |||
      sum by (%(aggregationLabels)s) (sidekiq_running_jobs{shard!~"export|elasticsearch|memory-bound", %(selector)s})
      /
      sum by (%(aggregationLabels)s) (sidekiq_concurrency{shard!~"export|elasticsearch|memory-bound", %(selector)s})
    |||,
    slos: {
      soft: 0.90,
      hard: 0.95,
      alert_trigger_duration: 'long',
    },
  }),

  single_node_cpu: resourceSaturationPoint({
    title: 'Average CPU Saturation per Node',
    appliesTo: { allExcept: ['waf', 'console-node', 'deploy-node'] },
    description: |||
      Average CPU per Node.

      If average CPU is satured, it may indicate that a fleet is in need to horizontal or vertical scaling. It may also indicate
      imbalances in load in a fleet.
    |||,
    grafana_dashboard_uid: 'sat_single_node_cpu',
    resourceLabels: ['fqdn'],
    query: |||
      avg without(cpu, mode) (1 - rate(node_cpu_seconds_total{mode="idle", %(selector)s}[%(rangeInterval)s]))
    |||,
    slos: {
      soft: 0.90,
      hard: 0.95,
    },
  }),

  single_node_puma_workers: resourceSaturationPoint({
    title: 'Puma Worker Saturation per Node',
    appliesTo: ['web', 'api', 'git', 'sidekiq'],
    description: |||
      Puma worker saturation per node.

      Each concurrent HTTP request being handled in the application needs a dedicated puma worker. When this resource is saturated,
      we will see puma queuing taking place. Leading to slowdowns across the application.

      Puma saturation is usually caused by latency problems in downstream services: usually Gitaly or Postgres, but possibly also Redis.
      Puma saturation can also be caused by traffic spikes.
    |||,
    grafana_dashboard_uid: 'sat_single_node_puma_workers',
    resourceLabels: ['fqdn'],
    query: |||
      sum by(%(aggregationLabels)s) (avg_over_time(puma_active_connections{%(selector)s}[%(rangeInterval)s]))
      /
      sum by(%(aggregationLabels)s) (puma_max_threads{pid="puma_master", %(selector)s})
    |||,
    slos: {
      soft: 0.85,
      hard: 0.90,
    },
  }),

  single_threaded_cpu: resourceSaturationPoint({
    title: 'Redis CPU Saturation per Node',
    appliesTo: ['redis', 'redis-sidekiq', 'redis-cache'],
    description: |||
      Redis CPU per node.

      Redis is single-threaded. A single Redis server is only able to scale as far as a single CPU on a single host.
      When this resource is saturated, major slowdowns should be expected across the application, so avoid if at all
      possible.
    |||,
    grafana_dashboard_uid: 'sat_single_threaded_cpu',
    resourceLabels: ['fqdn'],
    query: |||
      instance:redis_cpu_usage:rate1m{%(selector)s}
    |||,
    slos: {
      soft: 0.70,
      hard: 0.90,
    },
  }),

  // TODO: figure out how k8s management falls into out environment/tier/type/stage/shard labelling
  // taxonomy. These saturation metrics rely on this in order to work
  // See https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10249 for more details
  // pod_count: resourceSaturationPoint({
  //   title: 'Pod Count Saturation',
  //   description: |||
  //     This measures the HPA that manages our Deployments. If we are running low on
  //     ability to scale up by hitting our maximum HPA Pod allowance, we will have
  //     fully saturated this service.
  //   |||,
  //   grafana_dashboard_uid: 'sat_pod_count',
  //   resourceLabels: ['hpa'],
  //   query: |||
  //     avg_over_time(kube_hpa_status_current_replicas[%(rangeInterval)s])
  //     /
  //     avg_over_time(kube_hpa_spec_max_replicas[%(rangeInterval)s])
  //   |||,
  //   slos: {
  //     soft: 0.70,
  //     hard: 0.90,
  //   },
  // }),

  // Add some helpers. Note that these use :: to "hide" then:
  listApplicableServicesFor(type)::
    std.filter(function(k) self[k].appliesToService(type), std.objectFields(self)),


}
