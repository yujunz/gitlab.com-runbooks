local grafana = import 'grafonnet/grafana.libsonnet';
local template = grafana.template;

{
  ds:: template.datasource(
    'PROMETHEUS_DS',
    'prometheus',
    'Prometheus',
    regex= "/(.*-gprd|Global)/",
  ),
  environment:: template.new(
    "environment",
    "$PROMETHEUS_DS",
    "label_values(up, environment)",
    current="gprd",
    refresh='load',
    sort=1,
  ),
  type:: template.new(
    "type",
    "$PROMETHEUS_DS",
    'label_values(gitlab_service_availability:ratio{environment="$environment"}, type)',
    current="web",
    refresh='load',
    sort=1,
  ),
  sigma:: template.custom(
    "sigma",
    "0.5,1,1.5,2,2.5,3",
    "2",
  )
}
