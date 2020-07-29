// For now we assume that services are provisioned on vms and not kubernetes
local provisioningDefaults = { vms: true, kubernetes: false };
local serviceDefaults = {
  autogenerateRecordingRules: true,
  disableOpsRatePrediction: false,
  nodeLevelMonitoring: false,  // By default we do not use node-level monitoring
};
local componentDefaults = {
  aggregateRequestRate: true // by default, requestRate is aggregated up to the service level
};

local validateHasField(object, field, message) =
  if std.objectHas(object, field) then
    object
  else
    std.assertEqual(object, { __assert: message });

local validateAndApplyComponentDefaults(service, componentName, component) =
  // All components must have a requestRate measurement, since
  // we filter out low-RPS alerts for apdex monitoring and require the RPS for error ratios
  local v1 = validateHasField(component, 'requestRate', '%s component requires a requestRate measurement' % [componentName]);

  componentDefaults + v1;

// Definition of a component
local componentDefinition(component) =
  component {
    hasApdex():: std.objectHas(component, 'apdex'),
    hasRequestRate():: true,  // requestRate is mandatory
    hasAggregatableRequestRate():: std.objectHasAll(component.requestRate, 'aggregatedRateQuery'),
    hasErrorRate():: std.objectHas(component, 'errorRate'),
  };

local validateAndApplyServiceDefaults(service) =
  local serviceWithProvisioningDefaults = ({ provisioning: provisioningDefaults } + service);

  local serviceWithComponentDefaults = serviceWithProvisioningDefaults {
    components: {
      [componentName]: componentDefinition(validateAndApplyComponentDefaults(service, componentName, service.components[componentName]))
      for componentName in std.objectFields(service.components)
    },
  };

  serviceDefaults + serviceWithComponentDefaults;

local serviceDefinition(service) =
  // Private functions
  local private = {
    serviceHasComponentWith(keymetricName)::
      std.foldl(
        function(memo, componentName) memo || std.objectHas(service.components[componentName], keymetricName),
        std.objectFields(service.components),
        false
      ),
  };

  service {
    hasApdex():: private.serviceHasComponentWith('apdex'),
    hasRequestRate():: true,  // requestRate is mandatory
    hasErrorRate():: private.serviceHasComponentWith('errorRate'),

    getProvisioning()::
      service.provisioning,
  };

{
  serviceDefinition(service)::
    serviceDefinition(validateAndApplyServiceDefaults(service)),
}
