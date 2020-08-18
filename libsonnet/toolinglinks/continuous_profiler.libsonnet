local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition;

{
  continuousProfiler(service)::
    [
      toolingLinkDefinition({
        title: 'Google Stackdriver Continuous Profiling',
        url: 'https://console.cloud.google.com/profiler;timespan=4h/%(service)s;type=CPU/cpu?project=gitlab-production' % {
          service: service,
        },
      }),
    ],
}
