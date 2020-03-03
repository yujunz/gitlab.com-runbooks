local services = import './services/all.jsonnet';
local serviceMap = std.foldl(function(running, service) running { [service.type]: service }, services, {});

local serviceHasComponentWith(service, keymetricName) =
  std.foldl(
    function(memo, componentName) memo || std.objectHas(service.components[componentName], keymetricName),
    std.objectFields(service.components),
    false
  );

{
  getService(serviceType)::
    local service = serviceMap[serviceType];

    service {
      hasApdex():: serviceHasComponentWith(service, 'apdex'),
      hasRequestRate():: serviceHasComponentWith(service, 'requestRate'),
      hasErrorRate():: serviceHasComponentWith(service, 'errorRate'),
    },
}
