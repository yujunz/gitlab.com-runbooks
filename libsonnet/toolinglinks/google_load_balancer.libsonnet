local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition;

{
  googleLoadBalancer(
    instanceId,
    project='gitlab-production',
  )::
    [
      toolingLinkDefinition({
        title: 'Google Load Balancer',
        url: 'https://console.cloud.google.com/net-services/loadbalancing/details/http/%(instanceId)s?project=%(project)s' % {
          instanceId: instanceId,
          project: project,
        },
      }),
    ],
}
