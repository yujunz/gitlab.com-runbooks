local grafana = import 'grafonnet/grafana.libsonnet';
local template = grafana.template;

{
  gkeCluster:: template.new(
    'cluster',
    '$PROMETHEUS_DS',
    'label_values(kube_pod_container_info{environment="$environment"}, cluster)',
    current='gprd-gitlab-gke ',
    refresh='load',
    sort=1,
  ),
  projectId:: template.new(
    'project_id',
    '$PROMETHEUS_DS',
    'label_values(stackdriver_gke_container_logging_googleapis_com_log_entry_count{environment="$environment"}, project_id)',
    current='gitlab-production',
    refresh='load',
    sort=1,
  ),
  ds:: template.datasource(
    'PROMETHEUS_DS',
    'prometheus',
    'Prometheus',
    regex= "/(.*-gprd|Global)/",
  ),
  environment:: template.new(
    "environment",
    "$PROMETHEUS_DS",
    "label_values(gitlab_service_ops:rate, environment)",
    current="gprd",
    refresh='load',
    sort=1,
  ),
  type:: template.new(
    "type",
    "$PROMETHEUS_DS",
    'label_values(gitlab_service_ops:rate{environment="$environment"}, type)',
    current="web",
    refresh='load',
    sort=1,
  ),
  sigma:: template.custom(
    "sigma",
    "0.5,1,1.5,2,2.5,3",
    "2",
  ),
  // Once the stage change is fully rolled out, change the default to main
  stage:: template.custom(
    "stage",
    "main,cny,",
    "main",
  ),
  saturationComponent:: template.new(
    "component",
    "$PROMETHEUS_DS",
    'label_values(gitlab_component_saturation:ratio{environment="$environment", type="$type"}, component)',
    current="cpu",
    refresh='load',
    sort=1,
  ),
  sidekiqWorker:: template.new(
    "worker",
    "$PROMETHEUS_DS",
    'label_values(gitlab_background_worker_queue_duration_apdex:ratio{environment="$environment"}, worker)',
    current="NewMergeRequestWorker",
    refresh='load',
    sort=1,
  ),

}
