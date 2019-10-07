local grafana = import 'grafonnet/grafana.libsonnet';
local link = grafana.link;

local SERVICE_LINKS = {
  'api': 'https://dashboards.gitlab.net/d/api-main/api-overview?orgId=1',
  'ci-runners':'https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=ci-runners',
  'git':'https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=git',
  'frontend':'https://dashboards.gitlab.net/d/frontend-main/frontend-overview?orgId=1',
  'gitaly':'https://dashboards.gitlab.net/d/gitaly-main/gitaly-overview?orgId=1',
  'monitoring':'https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=monitoring',
  'pages':'https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=pages',
  'patroni':'https://dashboards.gitlab.net/d/patroni-main/patroni-overview?orgId=1',
  'pgbouncer':'https://dashboards.gitlab.net/d/pgbouncer-main/pgbouncer-overview?orgId=1',
  'redis':'https://dashboards.gitlab.net/d/redis-main/redis-overview?orgId=1',
  'redis-cache':'https://dashboards.gitlab.net/d/redis-cache-main/redis-cache-overview?orgId=1',
  'redis-sidekiq':'https://dashboards.gitlab.net/d/redis-sidekiq-main/redis-sidekiq-overview',
  'registry':'https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=registry',
  'sidekiq':'https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview?orgId=1',
  'web':'https://dashboards.gitlab.net/d/web-main/web-overview?orgId=1',
  'web-pages':'https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=web-pages',
};

{
  triage:: [
    link.dashboards('Platform Triage', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-triage/platform-triage?orgId=1'),
  ],
  services:: [
    link.dashboards('api service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['api']),
    link.dashboards('ci-runners service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['ci-runners']),
    link.dashboards('frontend service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['frontend']),
    link.dashboards('git service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['git']),
    link.dashboards('gitaly service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['gitaly']),
    link.dashboards('monitoring service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['monitoring']),
    link.dashboards('pages (haproxy) service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['pages']),
    link.dashboards('patroni service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['patroni']),
    link.dashboards('pgbouncer service', '', icon='dashboard', type='link', keepTime=true, includeVars=true, url=SERVICE_LINKS['pgbouncer']),
    link.dashboards('redis service', '', icon='dashboard', type='link', keepTime=true, includeVars=true, url=SERVICE_LINKS['redis']),
    link.dashboards('redis-cache service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['redis-cache']),
    link.dashboards('redis-sidekiq service', '', icon='dashboard', type='link', keepTime=true, includeVars=true, url=SERVICE_LINKS['redis-sidekiq']),
    link.dashboards('registry service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['registry']),
    link.dashboards('sidekiq service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['sidekiq']),
    link.dashboards('web service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['web']),
    link.dashboards('web-pages (pages) service', '', icon='dashboard', type='link', keepTime=true, url=SERVICE_LINKS['web-pages']),
  ],
  parameterizedServiceLink: [
    link.dashboards('$type service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=$type'),
  ],
  serviceLink(type):: [
    link.dashboards(type + ' service', '', type='link', keepTime=true, url=SERVICE_LINKS[type]),
  ],
  dynamicLinks(title, tags, asDropdown=true, icon='dashboard')::
    link.dashboards(
        title,
        tags,
        asDropdown=asDropdown,
        includeVars=true,
        keepTime=true,
        icon=icon,
      )
}
