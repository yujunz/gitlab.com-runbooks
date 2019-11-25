local grafana = import 'grafonnet/grafana.libsonnet';
local link = grafana.link;
local serviceCatalog = import 'service_catalog.libsonnet';

local GRAFANA_BASE_URL = 'https://dashboards.gitlab.net/d/';

// These services do not yet have their own dashboards, remove from this list as they get their own dashboards
local USES_GENERIC_DASHBOARD = {
  pages: true,
  'web-pages': true,
};

local LINKED_SERVICES = std.sort([
  'api',
  'ci-runners',
  'frontend',
  'git',
  'gitaly',
  'monitoring',
  'pages',
  'patroni',
  'pgbouncer',
  'redis',
  'redis-cache',
  'redis-sidekiq',
  'registry',
  'sidekiq',
  'web',
  'web-pages',
]);

local getServiceLink(serviceType) =
  if std.objectHas(USES_GENERIC_DASHBOARD, serviceType) then
    'https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=' + serviceType
  else
    GRAFANA_BASE_URL + serviceCatalog.lookupService(serviceType).observability.monitors.primary_grafana_dashboard + '?orgId=1';

{
  triage:: [
    link.dashboards('Platform Triage', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-triage/platform-triage?orgId=1'),
  ] + self.capacityPlanning,
  capacityPlanning:: [
    link.dashboards('Capacity Planning', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-capacity-planning/general-capacity-planning?orgId=1'),
  ],
  services:: [
    link.dashboards(type + ' service', '', icon='dashboard', type='link', keepTime=true, url=getServiceLink(type))
    for type in LINKED_SERVICES
  ],
  parameterizedServiceLink: [
    link.dashboards('$type service', '', type='link', keepTime=true, url='https://dashboards.gitlab.net/d/general-service/service-platform-metrics?orgId=1&var-type=$type'),
  ],
  serviceLink(type):: [
    link.dashboards(type + ' service', '', type='link', keepTime=true, url=getServiceLink(type)),
  ],
  dynamicLinks(title, tags, asDropdown=true, icon='dashboard', includeVars=true, keepTime=true)::
    link.dashboards(
      title,
      tags,
      asDropdown=asDropdown,
      includeVars=includeVars,
      keepTime=keepTime,
      icon=icon,
    ),
}
