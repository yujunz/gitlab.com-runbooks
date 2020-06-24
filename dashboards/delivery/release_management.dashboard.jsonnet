local grafana = import 'grafonnet/grafana.libsonnet';

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

grafana.dashboard.new(
  'Release Management',
  tags=['release'],
  editable=true,
)
.addAnnotations(annotations)
.addRow(
  row.new(
    title='Summary',
  )
)
.addRow(
  row.new(
    title='%s gprd' % icons.gprd
  )
)
.addRow(
  row.new(
    title='%s gprd-cny' % icons.cny
  )
)
.addRow(
  row.new(
    title='%s gstg' % icons.gstg,
    collapse=true,
  )
)
