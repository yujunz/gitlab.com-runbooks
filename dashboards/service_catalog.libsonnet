local serviceCatalog = import 'service_catalog.json';
local grafana = import 'grafonnet/grafana.libsonnet';
local link = grafana.link;

local serviceMap = {
  [x.name]: x, for x in serviceCatalog.services
};

{
  lookupService(name):: serviceMap[name],
  getLoggingLinks(name):: std.map(function(log) link.dashboards('Logs: ' + log.name, '', type='link', keepTime=false, targetBlank=true, url=log.permalink), serviceMap[name].technical.logging),
  getRunbooksLinks(name):: std.map(function(url) link.dashboards('Runbook', '', type='link', keepTime=false, targetBlank=true, url=url), serviceMap[name].operations.runbooks),
  getPlaybooksLinks(name):: std.map(function(url) link.dashboards('Playbook', '', type='link', keepTime=false, targetBlank=true, url=url), serviceMap[name].operations.playbooks),
  getServiceLinks(name)::
    self.getLoggingLinks(name) +
    self.getRunbooksLinks(name) +
    self.getPlaybooksLinks(name)
}
