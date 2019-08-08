local serviceCatalog = import 'service_catalog.json';
local grafana = import 'grafonnet/grafana.libsonnet';
local link = grafana.link;

local serviceMap = {
  [x.name]: x, for x in serviceCatalog.services
};

local safeMap(fn, v) = if std.isArray(v) then std.map(fn, v) else [];

{
  lookupService(name):: serviceMap[name],
  getLoggingLinks(name):: safeMap(function(log) link.dashboards('Logs: ' + log.name, '', type='link', keepTime=false, targetBlank=true, url=log.permalink), serviceMap[name].technical.logging),
  getRunbooksLinks(name):: safeMap(function(url) link.dashboards('Runbook', '', type='link', keepTime=false, targetBlank=true, url=url), serviceMap[name].operations.runbooks),
  getPlaybooksLinks(name):: safeMap(function(url) link.dashboards('Playbook', '', type='link', keepTime=false, targetBlank=true, url=url), serviceMap[name].operations.playbooks),
  getServiceLinks(name)::
    self.getLoggingLinks(name) +
    self.getRunbooksLinks(name) +
    self.getPlaybooksLinks(name)
}
