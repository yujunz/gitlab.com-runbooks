local services = import './services/all.jsonnet';
local serviceMap = std.foldl(function(running, service) running { [service.type]: service }, services, {});
local saturationResource = import './saturation-resources.libsonnet';

local serviceHasComponentWith(service, keymetricName) =
  std.foldl(
    function(memo, componentName) memo || std.objectHas(service.components[componentName], keymetricName),
    std.objectFields(service.components),
    false
  );

local serviceApplicableSaturationTypes(service)
      = saturationResource.listApplicableServicesFor(service.type);

{
  services:: services,
  getService(serviceType)::
    local service = serviceMap[serviceType];

    service {
      hasApdex():: serviceHasComponentWith(service, 'apdex'),
      hasRequestRate():: serviceHasComponentWith(service, 'requestRate'),
      hasErrorRate():: serviceHasComponentWith(service, 'errorRate'),
      applicableSaturationTypes():: serviceApplicableSaturationTypes(service),

      getProvisioning()::
        local provisioning = ({ provisioning: {} } + service).provisioning;
        { vms: true, kubernetes: false } + provisioning,
    },

}
