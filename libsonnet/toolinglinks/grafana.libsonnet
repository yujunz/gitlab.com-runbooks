local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition;

{
  grafana(title, dashboardUid, vars={})::
    local varsMapped = [
      'var-%(key)s=%(value)s' % { key: key, value: vars[key] }
      for key in std.objectFields(vars)
    ];

    [
      toolingLinkDefinition({
        title: 'Grafana: ' + title,
        url: '/d/%(dashboardUid)s?%(vars)s' % {
          dashboardUid: dashboardUid,
          vars: std.join('&', varsMapped),
        },
      }),
    ],
}
