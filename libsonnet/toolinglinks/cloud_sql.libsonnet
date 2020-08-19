local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition;

{
  cloudSQL(
    instanceId,
    project='gitlab-production',
  )::
    [
      toolingLinkDefinition({
        title: 'Cloud SQL',
        url: 'https://console.cloud.google.com/sql/instances/%(instanceId)s/overview?project=%(project)s' % {
          instanceId: instanceId,
          project: project,
        },
      }),
    ],
}
