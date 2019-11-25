local services = import './services/all.jsonnet';
local serviceMap = std.foldl(function(running, service) running { [service.type]: service }, services, {});

{
  getService(serviceType)::
    serviceMap[serviceType],
}
