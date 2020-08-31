local componentDefinition = import 'component_definition.libsonnet';

// For now we assume that services are provisioned on vms and not kubernetes
local provisioningDefaults = { vms: true, kubernetes: false };
local serviceDefaults = {
  autogenerateRecordingRules: true,
  disableOpsRatePrediction: false,
  nodeLevelMonitoring: false,  // By default we do not use node-level monitoring
};

// Convience method, will wrap a raw definition in a componentDefinition if needed
local prepareComponent(definition) =
  if std.objectHasAll(definition, 'initComponentWithName') then
    // Already prepared
    definition
  else
    // Wrap class as a component definition
    componentDefinition.componentDefinition(definition);

local validateAndApplyServiceDefaults(service) =
  local serviceWithProvisioningDefaults = ({ provisioning: provisioningDefaults } + service);

  serviceDefaults + serviceWithProvisioningDefaults {
    components: {
      [componentName]: prepareComponent(service.components[componentName]).initComponentWithName(componentName)
      for componentName in std.objectFields(service.components)
    },
  };

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

    // Returns an array of components for this service
    getComponentsList()::
      [
        service.components[componentName]
        for componentName in std.objectFields(service.components)
      ],
  };

{
  serviceDefinition(service)::
    serviceDefinition(validateAndApplyServiceDefaults(service)),
}
