local grafana = import 'grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;
local promQuery = import 'prom_query.libsonnet';

local timepickerlib = import 'grafonnet/timepicker.libsonnet';
local annotation = grafana.annotation;
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local row = grafana.row;
local singlestat = grafana.singlestat;

local icons = {
  gprd: '🚀',
  cny: '🐤',
  gstg: '🏗',
};

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

local railsVersion(env, stage='main') =
  prometheus.target(
    |||
      label_replace(
        topk(1, count(
          gitlab_version_info{environment="%(env)s", stage="%(stage)s", component="gitlab-rails", tier="sv"}
        ) by (version)),
        "version", "$1",
        "version", "^([A-Fa-f0-9]{11}).*$"
      )
    ||| % { env: env, stage: stage },
    instant=true,
    format='table',
    legendFormat='{{version}}',
  );

local packageVersion(env, stage='main') =
  prometheus.target(
    |||
      topk(1, count(
        omnibus_build_info{environment="%(env)s", stage="%(stage)s", tier="sv"}
      ) by (version))
    ||| % { env: env, stage: stage },
    instant=true,
    format='table',
    legendFormat='{{version}}',
  );

local environmentPressure(role) =
  prometheus.target(
    'delivery_auto_deploy_pressure{job="auto-deploy-pressure", role="%(role)s"}' % { role: role },
    legendFormat='Commits',
  );

local environmentSentry(role) =
  prometheus.target(
    'delivery_sentry_issues{job="sentry-issues", role="%(role)s"}' % { role: role },
    legendFormat='Issues',
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
      calcs: [
        'lastNotNull',
      ],
      defaults: {
        decimals: 0,
        mappings: [],
        min: 0,
        thresholds: thresholds,
      },
      overrides: [],
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

grafana.dashboard.new(
  'Release Management',
  tags=['release'],
  editable=true,
  refresh='5m',
  timezone='',
  timepicker=timepickerlib.new(refresh_intervals=['1m', '5m', '10m', '30m']),
)
.addAnnotations(annotations)

// ----------------------------------------------------------------------------
// Summary
// ----------------------------------------------------------------------------

.addPanel(
  row.new(title='Summary'),
  gridPos={ x: 0, y: 0, w: 24, h: 12 },
)

// gprd
.addPanel(
  singlestat.new(
    '%s gprd' % icons.gprd,
    description='Rails revision on Production.',
    valueFontSize='100%',
  )
  .addTarget(railsVersion('gprd')),
  gridPos={ x: 0, y: 0, w: 3, h: 3 },
)
.addPanel(
  singlestat.new(
    '%s gprd' % icons.gprd,
    description='Package running on Production.',
    valueFontSize='50%',
  )
  .addTarget(packageVersion('gprd')),
  gridPos={ x: 3, y: 0, w: 4, h: 3 },
)

// gprd-cny
.addPanel(
  singlestat.new(
    '%s gprd-cny' % icons.cny,
    description='Rails revision on Canary.',
    valueFontSize='100%',
  )
  .addTarget(railsVersion('gprd', 'cny')),
  gridPos={ x: 0, y: 4, w: 3, h: 3 },
)
.addPanel(
  singlestat.new(
    '%s gprd-cny' % icons.cny,
    description='Package running on Canary.',
    valueFontSize='50%',
  )
  .addTarget(packageVersion('gprd', 'cny')),
  gridPos={ x: 3, y: 4, w: 4, h: 3 },
)

// gstg
.addPanel(
  singlestat.new(
    '%s gstg' % icons.gstg,
    description='Rails revision on Staging.',
    valueFontSize='100%',
  )
  .addTarget(railsVersion('gstg')),
  gridPos={ x: 0, y: 7, w: 3, h: 3 },
)
.addPanel(
  singlestat.new(
    '%s gstg' % icons.gstg,
    description='Package running on Staging.',
    valueFontSize='50%',
  )
  .addTarget(packageVersion('gstg')),
  gridPos={ x: 3, y: 7, w: 4, h: 3 },
)

// Auto-deploy pressure
.addPanel(
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
  gridPos={ x: 7, y: 0, w: 6, h: 9 },
)

// New Sentry issues
.addPanel(
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
  gridPos={ x: 13, y: 0, w: 6, h: 9 },
)

// ----------------------------------------------------------------------------
// gprd row
// ----------------------------------------------------------------------------

.addPanel(
  row.new(
    title='%s gprd' % icons.gprd
  ),
  gridPos={ x: 0, y: 12, w: 24, h: 12 },
)
.addPanel(
  graphPanel.new(
    '%s Auto-deploy pressure' % icons.gprd,
    aliasColors={ Commits: 'semi-dark-purple' },
    decimals=0,
    labelY1='Commits',
    legend_show=false,
    min=0,
  )
  .addTarget(environmentPressure('gprd')),
  gridPos={ x: 0, y: 12, w: 10, h: 12 },
)
.addPanel(
  graphPanel.new(
    '%s New Sentry issues' % icons.gprd,
    aliasColors={ Issues: 'dark-orange' },
    decimals=0,
    labelY1='Issues',
    legend_show=false,
    min=0,
  )
  .addTarget(environmentSentry('gprd')),
  gridPos={ x: 10, y: 12, w: 10, h: 12 },
)

// ----------------------------------------------------------------------------
// gprd-cny row
// ----------------------------------------------------------------------------

.addPanel(
  row.new(
    title='%s gprd-cny' % icons.cny
  ),
  gridPos={ x: 0, y: 24, w: 24, h: 12 },
)
.addPanel(
  graphPanel.new(
    '%s Auto-deploy pressure' % icons.cny,
    aliasColors={ Commits: 'semi-dark-purple' },
    decimals=0,
    labelY1='Commits',
    legend_show=false,
    min=0,
  )
  .addTarget(environmentPressure('gprd-cny')),
  gridPos={ x: 0, y: 24, w: 10, h: 12 },
)
.addPanel(
  graphPanel.new(
    '%s New Sentry issues' % icons.cny,
    aliasColors={ Issues: 'dark-orange' },
    decimals=0,
    labelY1='Issues',
    legend_show=false,
    min=0,
  )
  .addTarget(environmentSentry('gprd-cny')),
  gridPos={ x: 10, y: 24, w: 10, h: 12 },
)

// ----------------------------------------------------------------------------
// gstg row
// ----------------------------------------------------------------------------

.addPanel(
  row.new(
    title='%s gstg' % icons.gstg
  ),
  gridPos={ x: 0, y: 36, w: 24, h: 12 },
)
.addPanel(
  graphPanel.new(
    '%s Auto-deploy pressure' % icons.gstg,
    aliasColors={ Commits: 'semi-dark-purple' },
    decimals=0,
    labelY1='Commits',
    legend_show=false,
    min=0,
  )
  .addTarget(environmentPressure('gstg')),
  gridPos={ x: 0, y: 36, w: 10, h: 12 },
)
.addPanel(
  graphPanel.new(
    '%s New Sentry issues' % icons.gstg,
    aliasColors={ Issues: 'dark-orange' },
    decimals=0,
    labelY1='Issues',
    legend_show=false,
    min=0,
  )
  .addTarget(environmentSentry('gstg')),
  gridPos={ x: 10, y: 36, w: 10, h: 12 },
)
