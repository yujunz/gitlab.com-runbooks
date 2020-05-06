{
  // The Component Mapping ruleset is used to generate a simple series of
  // static recording rules which are used in alert evaluation to determine whether
  // a component is still being monitored (and should therefore be alerted on)
  //
  // One recording rule is created per component
  componentMappingRuleSet()::
    {
      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        [
          {
            record: 'gitlab_component_service:mapping',
            labels: {
              type: serviceDefinition.type,
              tier: serviceDefinition.tier,
              component: component,
            },
            expr: '1',
          }
          for component in std.objectFields(serviceDefinition.components)
        ],

    },

}
