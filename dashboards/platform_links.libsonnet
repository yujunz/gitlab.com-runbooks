local grafana = import 'grafonnet/grafana.libsonnet';
local link = grafana.link;

{
  triage:: [
    link.dashboards('Platform Triage', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-triage/platform-triage?orgId=1'),
  ],
  services:: [
    link.dashboards('api service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/api-main/api-overview?orgId=1'),
    link.dashboards('ci-runners service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=ci-runners'),
    link.dashboards('git service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=git'),
    link.dashboards('gitaly service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=gitaly'),
    link.dashboards('haproxy service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=haproxy'),
    link.dashboards('pages service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=pages'),
    link.dashboards('patroni service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=patroni'),
    link.dashboards('pgbouncer service', '', icon='dashboard', type='link', keepTime=true, includeVars=true, url='https://dashboards.gitlab.net/d/pgbouncer-main/pgbouncer-overview?orgId=1'),
    link.dashboards('redis service', '', icon='dashboard', type='link', keepTime=true, includeVars=true, url='https://dashboards.gitlab.net/d/redis-main/redis-overview?orgId=1'),
    link.dashboards('redis-cache service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=redis-cache'),
    link.dashboards('redis-sidekiq service', '', icon='dashboard', type='link', keepTime=true, includeVars=true, url='https://dashboards.gitlab.net/d/redis-sidekiq-main/redis-sidekiq-overview'),
    link.dashboards('registry service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=registry'),
    link.dashboards('sidekiq service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/sidekiq-main/sidekiq-overview?orgId=1'),
    link.dashboards('web service', '', icon='dashboard', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/web-main/web-overview?orgId=1'),
  ],
  parameterizedServiceLink: [
    link.dashboards('$type service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=$type'),
  ],
}
