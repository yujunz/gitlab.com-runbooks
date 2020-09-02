local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local timepickerlib = import 'github.com/grafana/grafonnet-lib/grafonnet/timepicker.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local row = grafana.row;
local templates = import 'grafana/templates.libsonnet';
local graphPanel = grafana.graphPanel;

local services = [
  'registry',
  'mailroom',
  'sidekiq-memory-bound',
  'sidekiq-elasticsearch',
  'sidekiq-low-urgency-cpu-bound',
  'sidekiq-urgent-other',
  'sidekiq-database-throttled',
  'sidekiq-gitaly-throttled',
  'sidekiq-urgent-cpu-bound',
];

local generalGraphPanel(
  title,
  fill=0,
  format=null,
  formatY1=null,
  formatY2=null,
  decimals=3,
  description=null,
  linewidth=2,
  sort=0,
      ) = graphPanel.new(
  title,
  linewidth=linewidth,
  fill=fill,
  format=format,
  formatY1=formatY1,
  formatY2=formatY2,
  datasource='$PROMETHEUS_DS',
  description=description,
  decimals=decimals,
  sort=sort,
  legend_show=false,
  legend_values=false,
  legend_min=false,
  legend_max=true,
  legend_current=true,
  legend_total=false,
  legend_avg=false,
  legend_alignAsTable=true,
  legend_hideEmpty=false,
  legend_rightSide=true,
);


local serviceRow(service) =
  [

    // replicas
    generalGraphPanel(
      '%(service)s: Replicas' % { service: service },
    )
    .addTarget(
      promQuery.target(
        'sum(kube_replicaset_spec_replicas{replicaset=~"^gitlab-%(service)s.*", cluster="$environment-gitlab-gke"})' % { service: service },
      )
    )
    .resetYaxes()
    .addYaxis(
      format='none',
      label='replicas',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

    // cpu
    generalGraphPanel(
      '%(service)s: CPUs' % { service: service },
    )
    .addTarget(
      promQuery.target(
        'sum(rate(container_cpu_usage_seconds_total{env=~"$environment", pod=~"gitlab-%(service)s.*"}[1m]))' % { service: service },
      )
    )
    .resetYaxes()
    .addYaxis(
      format='none',
      label='cpus',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

    // memory
    generalGraphPanel(
      '%(service)s: Memory' % { service: service },
    )
    .addTarget(
      promQuery.target(
        'sum(container_memory_working_set_bytes{env=~"gprd", node=~"^.*$", id!="", container!="POD", pod=~"^gitlab-%(service)s.*$", container!=""})' % { service: service },
      )
    )
    .resetYaxes()
    .addYaxis(
      format='bytes',
      label='memory',
    )
    .addYaxis(
      format='bytes',
      max=1,
      min=0,
      show=false,
    ),
  ];

local serviceRows = std.map(serviceRow, services);

// Stat panel used by top-level Auto-deploy Pressure and New Sentry issues
local statPanel(
  title,
  description='',
  query='',
  legendFormat='',
  max_value=10000,
  thresholds={
    mode: 'absolute',
    steps: [
      { color: 'green', value: null },
    ],
  },
  links=[],
  unit=''
      ) =
  {
    description: description,
    fieldConfig: {
      values: false,
      defaults: {
        decimals: 0,
        mappings: [],
        min: 0,
        thresholds: thresholds,
        unit: unit,
      },
    },
    links: links,
    options: {
      colorMode: 'value',
      graphMode: 'area',
      justifyMode: 'auto',
      orientation: 'horizontal',
      reduceOptions: { calcs: ['lastNotNull'] },
    },
    pluginVersion: '7.0.3',
    targets: [promQuery.target(query, legendFormat=legendFormat)],
    title: title,
    type: 'stat',
  };


local savingsStatPanel(
  title,
  query,
      ) =
  {
    links: [],
    options: {
      graphMode: 'none',
      colorMode: 'background',
      justifyMode: 'auto',

      fieldOptions: {
        calcs: [
          'lastNotNull',
        ],
        defaults: {
          thresholds: {
            mode: 'absolute',
            steps: [
              { color: 'orange', value: 0 },
              { color: 'green', value: 10 },
            ],
          },
          mappings: [],
          title: title,
          unit: '%',
          decimals: 2,
        },
        overrides: [],
      },
      orientation: 'vertical',
    },
    pluginVersion: '6.6.1',
    targets: [promQuery.target(query, legendFormat='')],
    title: title,
    type: 'stat',
  };

basic.dashboard(
  'Kubernetes Migration Overview',
  tags=['release'],
  editable=true,
  refresh='5m',
  timepicker=timepickerlib.new(refresh_intervals=['1m', '5m', '10m', '30m']),
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)

.addTemplate(templates.environment)

// ----------------------------------------------------------------------------
// Overview
// ----------------------------------------------------------------------------

.addPanels(
  layout.grid([
    grafana.text.new(
      title='Kubernetes Migration Summary Explainer',
      mode='markdown',
      content=|||
        This dashboard shows a summary of resource utilization between virtual machines and the Kubernetes clusters for GitLab.com.
        For a summary of the current migration status see [the tracking epic for the migration](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/112)
        This dashboard focuses on the following resources during the migration to help track utilization and cost as services are brought over into the cluster. This only includes services that will be migrated and excludes others that will remain on virtual machines.

        **It does not include the following services:**
          * Pages
          * Patroni
          * Redis
          * Gitaly
          * Praefect

      |||
    ),
  ], cols=1, rowHeight=7, startRow=1)
)


// ----------------------------------------------------------------------------
// Virtual Machines Summary
// ----------------------------------------------------------------------------

.addPanel(
  row.new(title='🖥 Virtual Machines'),
  gridPos={ x: 0, y: 1, w: 24, h: 12 },
)
.addPanels(
  layout.splitColumnGrid([
    [
      statPanel(
        'Available cores',
        description='Total number of cores',
        query='sum(instance:node_cpus:count{env="$environment", tier="sv",type!~"web-pages|praefect|camoproxy"})',
      ),
    ],
    // CPU utilization
    [
      basic.singlestat(
        title='CPU utilization',
        query='avg(instance:node_cpu_utilization:ratio{tier="sv",type!~"web-pages|praefect|camoproxy"})',
        gaugeMaxValue=1,
        gaugeShow=true,
      ),
    ],
    [
      // Memory total
      statPanel(
        'Available Memory',
        description='Total memory',
        query='sum(node_memory_MemTotal_bytes{tier="sv",type!~"web-pages|praefect|camoproxy", env="$environment"})',
        unit='bytes',
      ),
    ],
    // Memory utilization
    [
      basic.singlestat(
        title='Avg Memory Utilization',
        query='avg(instance:node_memory_utilization:ratio{tier="sv",type!~"web-pages|praefect|camoproxy", env="$environment"})',
        gaugeMaxValue=1,
        gaugeShow=true,
      ),
    ],

  ], cellHeights=[2, 2, 2], startRow=1)
)


// ----------------------------------------------------------------------------
// Cluster Summary
// ----------------------------------------------------------------------------

.addPanel(
  row.new(title='☸️Kubernetes Cluster'),
  gridPos={ x: 0, y: 2, w: 24, h: 12 },
)
.addPanels(
  layout.splitColumnGrid([
    [
      // Cores
      statPanel(
        'Available cores',
        description='Total number of cores',
        query='sum(instance:node_cpus:count{cluster!="", env="$environment"})',
      ),
    ],

    // CPU Utilization
    [
      basic.singlestat(
        title='Avg CPU utilization',
        query='avg(instance:node_cpu_utilization:ratio{cluster!="", env="$environment"})',
        gaugeMaxValue=1,
        gaugeShow=true,
      ),
    ],
    [
      // Memory total
      statPanel(
        'Available Memory',
        description='Total memory',
        query='sum(node_memory_MemTotal_bytes{cluster!="", env="$environment"})',
        unit='bytes',
      ),
    ],
    // Memory utilization
    [
      basic.singlestat(
        title='Avg Memory Utilization',
        query='avg(instance:node_memory_utilization:ratio{cluster!="", env="$environment"})',
        gaugeMaxValue=1,
        gaugeShow=true,
      ),
    ],


  ], cellHeights=[2, 2, 2], startRow=2)
)

// ----------------------------------------------------------------------------
// Services
// ----------------------------------------------------------------------------

.addPanel(
  row.new(title='☸️Pods: replicas, CPUs and Memory in use by Service'),
  gridPos={ x: 0, y: 3, w: 24, h: 1 }
)
.addPanels(
  layout.columnGrid(serviceRows, [8, 8, 8], rowHeight=5, startRow=3)
)
