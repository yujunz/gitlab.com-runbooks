local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition;

{
  sentry(slug)::
    function(options)
      local formatConfig = {
        slug: slug,
      };

      [
        // Note: once https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/532 arrives
        // we will be to put together a smart exception search.
        toolingLinkDefinition({
          title: 'Sentry Releases: %(slug)s' % formatConfig,
          url: 'https://sentry.gitlab.net/%(slug)s/releases/' % formatConfig,
        }),
      ],
}
