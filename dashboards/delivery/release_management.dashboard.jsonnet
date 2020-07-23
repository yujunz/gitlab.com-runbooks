local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local timepickerlib = import 'github.com/grafana/grafonnet-lib/grafonnet/timepicker.libsonnet';
local prometheus = grafana.prometheus;
local promQuery = import 'prom_query.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local annotation = grafana.annotation;
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local singlestat = grafana.singlestat;

local environments = [
  {
    id: 'gprd',
    name: 'Production',
    role: 'gprd',
    stage: 'main',
    icon: '🚀',
  },
  {
    id: 'gprd-cny',
    name: 'Canary',
    role: 'gprd',
    stage: 'cny',
    icon: '🐤',
  },
  {
    id: 'gstg',
    name: 'Staging',
    role: 'gstg',
    stage: 'main',
    icon: '🏗',
  },
];

local annotations = [
  annotation.datasource(
    'Production deploys',
    '-- Grafana --',
    enable=true,
    iconColor='#19730E',
    tags=['deploy', 'gprd'],
  ),
  annotation.datasource(
    'Canary deploys',
    '-- Grafana --',
    enable=false,
    iconColor='#E08400',
    tags=['deploy', 'gprd-cny'],
  ),
  annotation.datasource(
    'Staging deploys',
    '-- Grafana --',
    enable=false,
    iconColor='#5794F2',
    tags=['deploy', 'gstg'],
  ),
];

local railsVersion(environment) =
  prometheus.target(
    |||
      label_replace(
        topk(1, count(
          gitlab_version_info{environment="%(env)s", stage="%(stage)s", component="gitlab-rails", tier="sv"}
        ) by (version)),
        "version", "$1",
        "version", "^([A-Fa-f0-9]{11}).*$"
      )
    ||| % { env: environment.role, stage: environment.stage },
    instant=true,
    format='table',
    legendFormat='{{version}}',
  );

local packageVersion(environment) =
  prometheus.target(
    |||
      topk(1, count(
        omnibus_build_info{environment="%(env)s", stage="%(stage)s", tier="sv"}
      ) by (version))
    ||| % { env: environment.role, stage: environment.stage },
    instant=true,
    format='table',
    legendFormat='{{version}}',
  );

local environmentPressurePanel(environment) =
  graphPanel.new(
    '%s Auto-deploy pressure' % [environment.icon],
    aliasColors={ Commits: 'semi-dark-purple' },
    decimals=0,
    labelY1='Commits',
    legend_show=false,
    min=0,
  )
  .addTarget(
    prometheus.target(
      'delivery_auto_deploy_pressure{job="auto-deploy-pressure", role="%(role)s"}' % { role: environment.role },
      legendFormat='Commits',
    )
  );

local environmentIssuesPanel(environment) =
  graphPanel.new(
    '%s New Sentry issues' % [environment.icon],
    aliasColors={ Issues: 'dark-orange' },
    decimals=0,
    labelY1='Issues',
    legend_show=false,
    min=0,
  )
  .addTarget(
    prometheus.target(
      'delivery_sentry_issues{job="sentry-issues", role="%(role)s"}' % { role: environment.role },
      legendFormat='Issues',
    )
  );

// Stat panel used by top-level Auto-deploy Pressure and New Sentry issues
local statPanel(
  title,
  description='',
  query='',
  legendFormat='',
  thresholds={},
  links=[]
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

// Bar Gauge panel used by top-level Release pressure
local bargaugePanel(
  title,
  description='',
  query='',
  legendFormat='',
  thresholds={},
  links=[],
  orientation='horizontal',
      ) =
  {
    description: description,
    fieldConfig: {
      values: false,
      defaults: {
        min: 0,
        max: 25,
        thresholds: thresholds,
      },
    },
    links: links,
    options: {
      displayMode: 'basic',
      orientation: orientation,
      showUnfilled: true,
    },
    pluginVersion: '7.0.3',
    targets: [promQuery.target(query, legendFormat=legendFormat, instant=true)],
    title: title,
    type: 'bargauge',
  };

basic.dashboard(
  'Release Management',
  tags=['release'],
  editable=true,
  refresh='5m',
  timepicker=timepickerlib.new(refresh_intervals=['1m', '5m', '10m', '30m']),
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)
.addAnnotations(annotations)

// ----------------------------------------------------------------------------
// Summary
// ----------------------------------------------------------------------------

.addPanel(
  row.new(title='Summary'),
  gridPos={ x: 0, y: 0, w: 24, h: 12 },
)
.addPanels(
  layout.splitColumnGrid([
    // Column 1: rails versions
    [
      singlestat.new(
        '%s %s' % [environment.icon, environment.id],
        description='Rails revision on %s.' % [environment.name],
        valueFontSize='100%',
      )
      .addTarget(railsVersion(environment))
      for environment in environments
    ],
    // Column 2: package versions
    [
      singlestat.new(
        '%s %s' % [environment.icon, environment.id],
        description='Package running on %s.' % [environment.name],
        valueFontSize='50%',
      )
      .addTarget(packageVersion(environment))
      for environment in environments
    ],
    // Column 3: auto-deploy pressure
    [
      // Auto-deploy pressure
      statPanel(
        'Auto-deploy pressure',
        description='The number of commits in `master` not yet deployed to each environment.',
        query='max(delivery_auto_deploy_pressure{role!=""}) by (role)',
        legendFormat='{{role}}',
        thresholds={
          mode: 'absolute',
          steps: [
            { color: 'green', value: null },
            { color: '#EAB839', value: 50 },
            { color: '#EF843C', value: 100 },
            { color: 'red', value: 150 },
          ],
        },
        links=[
          {
            targetBlank: true,
            title: 'Latest commits',
            url: 'https://gitlab.com/gitlab-org/gitlab/commits/master',
          },
        ],
      ),
    ],
    // Column 4: new sentry issues
    [
      // New Sentry issues
      statPanel(
        'New Sentry issues',
        description='The number of new Sentry issues for each environment.',
        query='max(delivery_sentry_issues{role!=""}) by (role)',
        legendFormat='{{role}}',
        thresholds={
          mode: 'absolute',
          steps: [
            { color: 'green', value: null },
            { color: '#EAB839', value: 50 },
            { color: '#EF843C', value: 100 },
            { color: 'red', value: 150 },
          ],
        },
        links=[
          {
            targetBlank: true,
            title: 'Sentry releases',
            url: 'https://sentry.gitlab.net/gitlab/gitlabcom/releases/',
          },
        ],
      ),
    ],
    // Column 5: release pressure
    [
      bargaugePanel(
        'Release pressure',
        description='Number of `Pick into` merge requests for previous releases.',
        query=|||
          label_replace(
            max(delivery_release_pressure{state="merged"}) by (state, version),
            "version", "$1",
            "version", "Pick into (.*)"
          )
        |||,
        legendFormat='{{version}} ({{state}})',
        thresholds={
          mode: 'absolute',
          steps: [
            { color: 'green', value: null },
            { color: '#EAB839', value: 5 },
            { color: '#EF843C', value: 10 },
            { color: 'red', value: 15 },
          ],
        },
      ),
    ],
  ], cellHeights=[3, 3, 3], startRow=1)
)
.addPanels(
  std.flattenArrays(
    std.mapWithIndex(
      function(index, environment)
        local y = 1000 * (index + 1);
        [
          row.new(
            title='%s %s' % [environment.icon, environment.id]
          )
          { gridPos: { x: 0, y: y, w: 24, h: 12 } },
        ]
        +
        layout.grid(
          [
            environmentPressurePanel(environment),
            environmentIssuesPanel(environment),
          ],
          cols=2,
          startRow=y + 1
        ),
      environments
    )
  )
)
.trailer()
