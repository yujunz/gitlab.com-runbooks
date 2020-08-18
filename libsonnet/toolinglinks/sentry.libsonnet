local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition;

{
  sentry(slug)::
    [
      toolingLinkDefinition({
        title: 'Sentry Exceptions',
        url: 'https://sentry.gitlab.net/%(slug)s' % {
          slug: slug,
        },
      }),
    ],
}
