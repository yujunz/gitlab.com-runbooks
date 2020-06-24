local grafana = import 'grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;

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

grafana.dashboard.new(
  'Release Management',
  tags=['release'],
  editable=true,
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

// ----------------------------------------------------------------------------
// gprd row
// ----------------------------------------------------------------------------

.addPanel(
  row.new(
    title='%s gprd' % icons.gprd
  ),
  gridPos={ x: 0, y: 12, w: 24, h: 12 },
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

// ----------------------------------------------------------------------------
// gstg row
// ----------------------------------------------------------------------------

.addPanel(
  row.new(
    title='%s gstg' % icons.gstg
  ),
  gridPos={ x: 0, y: 36, w: 24, h: 12 },
)
