local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;

{
  gkeCluster::
    template.new(
      'cluster',
      '$PROMETHEUS_DS',
      'label_values(kube_pod_container_info{environment="$environment"}, cluster)',
      current='gprd-gitlab-gke ',
      refresh='load',
      sort=1,
    ),
  namespace::
    template.new(
      'namespace',
      '$PROMETHEUS_DS',
      'label_values(kube_pod_container_info{environment="$environment"}, namespace)',
      refresh='load',
    ),
  namespaceGitlab::
    template.custom(
      'namespace',
      'gitlab,',
      'gitlab',
      hide='variable',
    ),
  ds::
    template.datasource(
      'PROMETHEUS_DS',
      'prometheus',
      'Prometheus',
      regex='/(.*-gprd|Global|gprd-.*)/',
    ),
  environment::
    template.new(
      'environment',
      '$PROMETHEUS_DS',
      'label_values(gitlab_service_ops:rate, environment)',
      current='gprd',
      refresh='load',
      sort=1,
    ),
  defaultEnvironment::
    {
      current: {
        text: 'gprd',
        value: 'gprd',
      },
      hide: 1,
      label: null,
      name: 'environment',
      options: [
        {
          selected: true,
          text: 'gprd',
          value: 'gprd',
        },
      ],
      query: 'gprd',
      skipUrlSync: false,
      type: 'constant',
    },
  Node::
    template.new(
      'Node',
      '$PROMETHEUS_DS',
      'query_result(count(count_over_time(kube_node_labels{environment="$environment", cluster="$cluster"}[1w])) by (label_kubernetes_io_hostname))',
      allValues='.*',
      current='NewMergeRequestWorker',
      includeAll=true,
      refresh='time',
      regex='/.*="(.*)".*/',
      sort=0,
    ),
  type::
    template.new(
      'type',
      '$PROMETHEUS_DS',
      'label_values(gitlab_service_ops:rate{environment="$environment"}, type)',
      current='web',
      refresh='load',
      sort=1,
    ),
  sigma::
    template.custom(
      'sigma',
      '0.5,1,1.5,2,2.5,3',
      '2',
    ),
  component::
    template.new(
      'component',
      '$PROMETHEUS_DS',
      'label_values(gitlab_component_ops:rate{environment="$environment", type="$type", stage="$stage"}, component)',
      current='',
      refresh='load',
      sort=1,
    ),
  // Once the stage change is fully rolled out, change the default to main
  stage::
    template.custom(
      'stage',
      'main,cny,',
      'main',
    ),
  saturationComponent::
    template.new(
      'component',
      '$PROMETHEUS_DS',
      'label_values(gitlab_component_saturation:ratio{environment="$environment", type="$type"}, component)',
      current='cpu',
      refresh='load',
      sort=1,
    ),
  sidekiqQueue::
    template.new(
      'queue',
      '$PROMETHEUS_DS',
      'label_values(sidekiq_jobs_completion_seconds_bucket{environment="$environment"}, queue)',
      current='new_merge_request',
      refresh='load',
      sort=1,
    ),
  fqdn(
    query,
    current='',
    multi=false)::
    template.new(
      'fqdn',
      '$PROMETHEUS_DS',
      'label_values(' + query + ', fqdn)',
      current=current,
      multi=multi,
      refresh='load',
      sort=1,
    ),

}