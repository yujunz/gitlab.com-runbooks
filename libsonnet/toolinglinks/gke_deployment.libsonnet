local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition;
local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';

{
  gkeDeployment(
    deployment,
    region='us-east1',
    cluster='gprd-gitlab-gke',
    namespace='gitlab',
    project='gitlab-production'
  )::
    local formatConfig = {
      deployment: deployment,
      region: region,
      cluster: cluster,
      namespace: namespace,
      project: project,
    };

    [
      toolingLinkDefinition({
        title: 'GKE Deployment: %(deployment)s' % formatConfig,
        url: 'https://console.cloud.google.com/kubernetes/deployment/%(region)s/%(cluster)s/%(namespace)s/%(deployment)s/overview?project=%(project)s' % formatConfig,
      }),
    ],
}
