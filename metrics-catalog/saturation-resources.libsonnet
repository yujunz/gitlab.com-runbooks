local resourceSaturationPoint = (import './lib/resource-saturation-point.libsonnet').resourceSaturationPoint;
local sidekiqHelpers = import './services/lib/sidekiq-helpers.libsonnet';

// throttledSidekiqShards is an array of Sidekiq `shard` labels for shards
// that are configured to run `urgency=throttled` jobs. Queues running on these
// shards will be saturated by-design, as we throttle jobs to protect backend
// resources.
//
// For this reason, we don't alert on sidekiq saturation on these nodes
local throttledSidekiqShards = [
  'export',
  'elasticsearch',
  'memory-bound'
];

// Disk utilisation metrics are currently reporting incorrectly for
// HDD volumes, see https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10248
// as such, we only record this utilisation metric on IO subset of the fleet for now.
local diskPerformanceSensitiveServices = ['patroni', 'gitaly', 'nfs'];

local pgbouncerAsyncPool(serviceType, role) =
  resourceSaturationPoint({
    title: 'Postgres Async (Sidekiq) %s Connection Pool Saturation per Node' % [role],
    severity: 's4',
    appliesTo: [serviceType],
    description: |||
      pgbouncer async connection pool saturation per database node, for %(role)s database connections.

      Sidekiq maintains it's own pgbouncer connection pool. When this resource is saturated,
      database operations may queue, leading to additional latency in background processing.
    ||| % { role: role },
    grafana_dashboard_uid: 'sat_pgbouncer_async_pool_' + role,
    resourceLabels: ['fqdn', 'instance'],
    burnRatePeriod: '5m',
    query: |||
      (
        avg_over_time(pgbouncer_pools_server_active_connections{user="gitlab", database="gitlabhq_production_sidekiq", %(selector)s}[%(rangeInterval)s]) +
        avg_over_time(pgbouncer_pools_server_testing_connections{user="gitlab", database="gitlabhq_production_sidekiq", %(selector)s}[%(rangeInterval)s]) +
        avg_over_time(pgbouncer_pools_server_used_connections{user="gitlab", database="gitlabhq_production_sidekiq", %(selector)s}[%(rangeInterval)s]) +
        avg_over_time(pgbouncer_pools_server_login_connections{user="gitlab", database="gitlabhq_production_sidekiq", %(selector)s}[%(rangeInterval)s])
      )
      / on(%(aggregationLabels)s) group_left()
      sum by (%(aggregationLabels)s) (
        avg_over_time(pgbouncer_databases_pool_size{name="gitlabhq_production_sidekiq", %(selector)s}[%(rangeInterval)s])
      )
    |||,
    slos: {
      soft: 0.90,
      hard: 0.95,
      alertTriggerDuration: '10m',
    },
  });

local pgbouncerSyncPool(serviceType, role) =
  resourceSaturationPoint({
    title: 'Postgres Sync (Web/API/Git) %s Connection Pool Saturation per Node' % [role],
    severity: 's3',
    appliesTo: [serviceType],
    description: |||
      pgbouncer sync connection pool saturation per database node, for %(role)s database connections.

      Web/api/git applications use a separate connection pool to sidekiq.

      When this resource is saturated, web/api database operations may queue, leading to unicorn/puma
      saturation and 503 errors in the web.
    ||| % { role: role },
    grafana_dashboard_uid: 'sat_pgbouncer_sync_pool_' + role,
    resourceLabels: ['fqdn', 'instance'],
    burnRatePeriod: '5m',
    query: |||
      (
        avg_over_time(pgbouncer_pools_server_active_connections{user="gitlab", database="gitlabhq_production", %(selector)s}[%(rangeInterval)s]) +
        avg_over_time(pgbouncer_pools_server_testing_connections{user="gitlab", database="gitlabhq_production", %(selector)s}[%(rangeInterval)s]) +
        avg_over_time(pgbouncer_pools_server_used_connections{user="gitlab", database="gitlabhq_production", %(selector)s}[%(rangeInterval)s]) +
        avg_over_time(pgbouncer_pools_server_login_connections{user="gitlab", database="gitlabhq_production", %(selector)s}[%(rangeInterval)s])
      )
      / on(%(aggregationLabels)s) group_left()
      sum by (%(aggregationLabels)s) (
        avg_over_time(pgbouncer_databases_pool_size{name="gitlabhq_production", %(selector)s}[%(rangeInterval)s])
      )
    |||,
    slos: {
      soft: 0.85,
      hard: 0.95,
      alertTriggerDuration: '10m',
    },
  });

{
  pg_active_db_connections_primary: resourceSaturationPoint({
    title: 'Active Primary DB Connection Saturation',
    severity: 's3',
    appliesTo: ['patroni'],
    description: |||
      Active db connection saturation on the primary node.

      Postgres is configured to use a maximum number of connections.
      When this resource is saturated, connections may queue.
    |||,
    grafana_dashboard_uid: 'sat_active_db_connections_primary',
    resourceLabels: ['fqdn'],
    query: |||
      sum without (state) (
        pg_stat_activity_count{datname="gitlabhq_production", state!="idle", %(selector)s} unless on(instance) (pg_replication_is_replica == 1)
      )
      / on (%(aggregationLabels)s)
      pg_settings_max_connections{%(selector)s}
    |||,
    slos: {
      soft: 0.70,
      hard: 0.80,
    },
  }),

  pg_active_db_connections_replica: resourceSaturationPoint({
    title: 'Active Secondary DB Connection Saturation',
    severity: 's3',
    appliesTo: ['patroni'],
    description: |||
      Active db connection saturation per replica node

      Postgres is configured to use a maximum number of connections.
      When this resource is saturated, connections may queue.
    |||,
    grafana_dashboard_uid: 'sat_active_db_connections_replica',
    resourceLabels: ['fqdn'],
    query: |||
      sum without (state) (
        pg_stat_activity_count{datname="gitlabhq_production", state!="idle", %(selector)s} and on(instance) (pg_replication_is_replica == 1)
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
    severity: 's4',
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
      alertTriggerDuration: '15m',
    },
  }),

  cgroup_memory: resourceSaturationPoint({
    title: 'Cgroup Memory Saturation per Node',
    severity: 's4',
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
    severity: 's3',
    appliesTo: { allExcept: ['waf', 'console-node', 'deploy-node'] },
    description: |||
      This resource measures average CPU across an all cores in a service fleet.
      If it is becoming saturated, it may indicate that the fleet needs
      horizontal or vertical scaling.
    |||,
    grafana_dashboard_uid: 'sat_cpu',
    resourceLabels: [],
    burnRatePeriod: '5m',
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
    severity: 's3',
    appliesTo: { allExcept: ['waf', 'console-node', 'deploy-node'], default: 'sidekiq' },
    description: |||
      This resource measures average CPU across an all cores in a shard of a
      service fleet. If it is becoming saturated, it may indicate that the
      shard needs horizontal or vertical scaling.
    |||,
    grafana_dashboard_uid: 'sat_shard_cpu',
    resourceLabels: ['shard'],
    burnRatePeriod: '5m',
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
    severity: 's2',
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
    severity: 's3',
    appliesTo: diskPerformanceSensitiveServices,
    description: |||
      Disk sustained read IOPS saturation per node.
    |||,
    grafana_dashboard_uid: 'sat_disk_sus_read_iops',
    resourceLabels: ['fqdn', 'device'],
    query: |||
      rate(node_disk_reads_completed_total{device!="sda", %(selector)s}[%(rangeInterval)s])
      /
      node_disk_max_read_iops{device!="sda", %(selector)s}
    |||,
    burnRatePeriod: '20m',
    slos: {
      soft: 0.80,
      hard: 0.90,
      alertTriggerDuration: '25m',
    },
  }),

  disk_sustained_read_throughput: resourceSaturationPoint({
    title: 'Disk Sustained Read Throughput Saturation per Node',
    severity: 's3',
    appliesTo: diskPerformanceSensitiveServices,
    description: |||
      Disk sustained read throughput saturation per node.
    |||,
    grafana_dashboard_uid: 'sat_disk_sus_read_throughput',
    resourceLabels: ['fqdn', 'device'],
    query: |||
      rate(node_disk_read_bytes_total{device!="sda", %(selector)s}[%(rangeInterval)s])
      /
      node_disk_max_read_bytes_seconds{device!="sda", %(selector)s}
    |||,
    burnRatePeriod: '20m',
    slos: {
      soft: 0.70,
      hard: 0.80,
      alertTriggerDuration: '25m',
    },
  }),

  disk_sustained_write_iops: resourceSaturationPoint({
    title: 'Disk Sustained Write IOPS Saturation per Node',
    severity: 's3',
    appliesTo: diskPerformanceSensitiveServices,
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
      rate(node_disk_writes_completed_total{device!="sda", %(selector)s}[%(rangeInterval)s])
      /
      node_disk_max_write_iops{device!="sda", %(selector)s}
    |||,
    burnRatePeriod: '20m',
    slos: {
      soft: 0.80,
      hard: 0.90,
      alertTriggerDuration: '25m',
    },
  }),

  disk_sustained_write_throughput: resourceSaturationPoint({
    title: 'Disk Sustained Write Throughput Saturation per Node',
    severity: 's3',
    appliesTo: diskPerformanceSensitiveServices,
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
      rate(node_disk_written_bytes_total{device!="sda", %(selector)s}[%(rangeInterval)s])
      /
      node_disk_max_write_bytes_seconds{device!="sda", %(selector)s}
    |||,
    burnRatePeriod: '20m',
    slos: {
      soft: 0.70,
      hard: 0.80,
      alertTriggerDuration: '25m',
    },
  }),

  elastic_cpu: resourceSaturationPoint({
    title: 'Average CPU Saturation per Node',
    severity: 's4',
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
    severity: 's3',
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
    severity: 's4',
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
    severity: 's4',
    appliesTo: ['logging', 'search'],
    description: |||
      Average CPU per Node.

      This resource measures all CPU across a fleet. If it is becoming saturated, it may indicate that the fleet needs horizontal or
      vertical scaling. The metrics are coming from elasticsearch_exporter.
    |||,
    grafana_dashboard_uid: 'sat_elastic_single_node_cpu',
    resourceLabels: ['name'],
    burnRatePeriod: '5m',
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
    severity: 's4',
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
    severity: 's4',
    appliesTo: ['logging', 'search'],
    description: |||
      Saturation of each thread pool on each node.

      Descriptions of the threadpool types can be found at
      https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-threadpool.html.
    |||,
    grafana_dashboard_uid: 'sat_elastic_thread_pools',
    resourceLabels: ['name', 'exported_type'],
    burnRatePeriod: '5m',
    query: |||
      (
        avg_over_time(elasticsearch_thread_pool_active_count{exported_type!="snapshot", %(selector)s}[%(rangeInterval)s])
        /
        (avg_over_time(elasticsearch_thread_pool_threads_count{exported_type!="snapshot", %(selector)s}[%(rangeInterval)s]) > 0)
      )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),

  go_memory: resourceSaturationPoint({
    title: 'Go Memory Saturation per Node',
    severity: 's4',
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
    severity: 's4',
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
    severity: 's2',
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

  pgbouncer_async_primary_pool: pgbouncerAsyncPool('pgbouncer', 'primary'),

  // Note that this pool is currently not used, but may be added in the medium
  // term
  // pgbouncer_async_replica_pool: pgbouncerAsyncPool('patroni', 'replica'),
  pgbouncer_sync_primary_pool: pgbouncerSyncPool('pgbouncer', 'primary'),
  pgbouncer_sync_replica_pool: pgbouncerSyncPool('patroni', 'replica'),

  pgbouncer_single_core: resourceSaturationPoint({
    title: 'PGBouncer Single Core per Node',
    severity: 's2',
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

  private_runners: resourceSaturationPoint({
    title: 'Private Runners Saturation',
    severity: 's4',
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
    query: |||
      sum without(executor_stage, exported_stage, state) (max_over_time(gitlab_runner_jobs{job="private-runners"}[%(rangeInterval)s]))
      /
      gitlab_runner_limit{job="private-runners"} > 0
    |||,
    slos: {
      soft: 0.85,
      hard: 0.95,
    },
  }),

  redis_clients: resourceSaturationPoint({
    title: 'Redis Client Saturation per Node',
    severity: 's3',
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
    severity: 's2',
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
    severity: 's4',
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
    query: |||
      sum without(executor_stage, exported_stage, state) (max_over_time(gitlab_runner_jobs{job="shared-runners"}[%(rangeInterval)s]))
      /
      gitlab_runner_limit{job="shared-runners"} > 0
    |||,
    slos: {
      soft: 0.90,
      hard: 0.95,
    },
  }),

  shared_runners_gitlab: resourceSaturationPoint({
    title: 'Shared Runner GitLab Saturation',
    severity: 's4',
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
      sum without(executor_stage, exported_stage, state) (max_over_time(gitlab_runner_jobs{job="shared-runners-gitlab-org"}[%(rangeInterval)s]))
      /
      gitlab_runner_limit{job="shared-runners-gitlab-org"} > 0
    |||,
    slos: {
      soft: 0.90,
      hard: 0.95,
    },
  }),

  sidekiq_shard_workers: resourceSaturationPoint({
    title: 'Sidekiq Worker Saturation per shard',
    severity: 's4',
    appliesTo: ['sidekiq'],
    description: |||
      Sidekiq worker saturation per shard.

      This metric represents the percentage of available threads*workers that are utilized actively processing jobs.

      When this metric is saturated, new Sidekiq jobs will queue. Depending on whether or not the jobs are latency sensitive,
      this could impact user experience.
    |||,
    grafana_dashboard_uid: 'sat_sidekiq_shard_workers',
    resourceLabels: ['shard'],
    burnRatePeriod: '5m',
    query: |||
      sum by (%(aggregationLabels)s) (
        avg_over_time(sidekiq_running_jobs{shard!~"%(throttledSidekiqShardsRegexp)s", %(selector)s}[%(rangeInterval)s])
      )
      /
      sum by (%(aggregationLabels)s) (
        avg_over_time(sidekiq_concurrency{shard!~"%(throttledSidekiqShardsRegexp)s", %(selector)s}[%(rangeInterval)s])
      )
    |||,
    queryFormatConfig: {
      throttledSidekiqShardsRegexp: std.join('|', throttledSidekiqShards)
    },
    slos: {
      soft: 0.85,
      hard: 0.90,
      alertTriggerDuration: '10m',
    },
  }),

  single_node_cpu: resourceSaturationPoint({
    title: 'Average CPU Saturation per Node',
    severity: 's4',
    appliesTo: { allExcept: ['waf', 'console-node', 'deploy-node'] },
    description: |||
      Average CPU per Node.

      If average CPU is satured, it may indicate that a fleet is in need to horizontal or vertical scaling. It may also indicate
      imbalances in load in a fleet.
    |||,
    grafana_dashboard_uid: 'sat_single_node_cpu',
    resourceLabels: ['fqdn'],
    burnRatePeriod: '5m',
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
    severity: 's2',
    appliesTo: ['web', 'api', 'git', 'sidekiq'],
    description: |||
      Puma thread utilization per node.

      Puma uses a fixed size thread pool to handle HTTP requests. This metric shows how many threads are busy handling requests. When this resource is saturated,
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

  redis_primary_cpu: resourceSaturationPoint({
    title: 'Redis Primary CPU Saturation per Node',
    severity: 's1',
    appliesTo: ['redis', 'redis-sidekiq', 'redis-cache'],
    description: |||
      Redis Primary CPU Saturation per Node.

      Redis is single-threaded. A single Redis server is only able to scale as far as a single CPU on a single host.
      When the primary Redis service is saturated, major slowdowns should be expected across the application, so avoid if at all
      possible.
    |||,
    grafana_dashboard_uid: 'sat_redis_primary_cpu',
    resourceLabels: ['fqdn'],
    burnRate: '5m',
    query: |||
      (
        rate(redis_cpu_user_seconds_total{%(selector)s}[%(rangeInterval)s])
        +
        rate(redis_cpu_sys_seconds_total{%(selector)s}[%(rangeInterval)s])
      )
      and on (instance) redis_instance_info{role="master"}
    |||,
    slos: {
      soft: 0.70,
      hard: 0.90,
    },
  }),

  redis_secondary_cpu: resourceSaturationPoint({
    title: 'Redis Secondary CPU Saturation per Node',
    severity: 's4',
    appliesTo: ['redis', 'redis-sidekiq', 'redis-cache'],
    description: |||
      Redis Secondary CPU Saturation per Node.

      Redis is single-threaded. A single Redis server is only able to scale as far as a single CPU on a single host.
      CPU saturation on a secondary is not as serious as critical as saturation on a primary, but could lead to
      replication delays.
    |||,
    grafana_dashboard_uid: 'sat_redis_secondary_cpu',
    resourceLabels: ['fqdn'],
    burnRate: '5m',
    query: |||
      (
        rate(redis_cpu_user_seconds_total{%(selector)s}[%(rangeInterval)s])
        +
        rate(redis_cpu_sys_seconds_total{%(selector)s}[%(rangeInterval)s])
      )
      and on (instance) redis_instance_info{role!="master"}
    |||,
    slos: {
      soft: 0.85,
      hard: 0.95,
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


  // TODO: figure out how k8s management falls into out environment/tier/type/stage/shard labelling
  // taxonomy. These saturation metrics rely on this in order to work
  // See https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10249 for more details
  kube_hpa_instances: resourceSaturationPoint({
    title: 'HPA Instances',
    severity: 's2',
    appliesTo: ['kube'],
    description: |||
      This measures the HPA that manages our Deployments. If we are running low on
      ability to scale up by hitting our maximum HPA Pod allowance, we will have
      fully saturated this service.
    |||,
    runbook: 'docs/uncategorized/kubernetes.md#hpascalecapability',
    grafana_dashboard_uid: 'sat_kube_hpa_instances',
    resourceLabels: ['hpa'],
    // TODO: keep these resources with the services they're managing, once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10249 is resolved
    // do not apply static labels
    staticLabels: {
      type: 'kube',
      tier: 'inf',
      stage: 'main',
    },
    // TODO: remove label-replace ugliness once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10249 is resolved
    // TODO: add %(selector)s once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10249 is resolved
    query: |||
      label_replace(
        label_replace(
          kube_hpa_status_desired_replicas{%(selector)s, hpa!~"gitlab-sidekiq-(%(ignored_sidekiq_shards)s)-v1"}
          /
          kube_hpa_spec_max_replicas,
          "stage", "cny", "hpa", "gitlab-cny-.*"
        ),
        "type", "$1", "hpa", "gitlab-(?:cny-)?(\\w+)"
      )
    |||,
    queryFormatConfig: {
      // Ignore non-autoscaled shards and throttled shards
      ignored_sidekiq_shards: std.join('|', sidekiqHelpers.shards.listFiltered(function(shard) !shard.autoScaling || shard.throttled)),
    },
    slos: {
      soft: 0.95,
      hard: 0.90,
      alertTriggerDuration: '25m',
    },
  }),

  // Add some helpers. Note that these use :: to "hide" then:
  listApplicableServicesFor(type)::
    std.filter(function(k) self[k].appliesToService(type), std.objectFields(self)),

  // Iterate over resources, calling the mapping function with (name, definition)
  mapResources(mapFunc)::
    std.map(function(saturationName) mapFunc(saturationName, self[saturationName]), std.objectFields(self)),
}
