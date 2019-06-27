local grafana = import 'grafonnet/grafana.libsonnet';
local link = grafana.link;

{
  triage:: [
    link.dashboards('Platform Triage', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/XufqmIGWk/platform-triage?orgId=1'),
  ],
  services:: [
    link.dashboards('api service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=api'),
    link.dashboards('git service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=git'),
    link.dashboards('gitaly service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=gitaly'),
    link.dashboards('haproxy service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=haproxy'),
    link.dashboards('pages service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=pages'),
    link.dashboards('patroni service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=patroni'),
    link.dashboards('pgbouncer service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=pgbouncer'),
    link.dashboards('redis service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=redis'),
    link.dashboards('redis-cache service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=redis-cache'),
    link.dashboards('registry service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=registry'),
    link.dashboards('web service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?orgId=1&var-type=web'),
  ]
}
