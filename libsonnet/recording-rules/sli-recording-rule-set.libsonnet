
local generateRecordingRulesForMetric(recordingRuleMetric, burnRate, recordingRuleRegistry) =
  local expression = recordingRuleRegistry.recordingRuleExpressionFor(metricName=recordingRuleMetric, rangeInterval=burnRate);
  local recordingRuleName = recordingRuleRegistry.recordingRuleNameFor(metricName=recordingRuleMetric, rangeInterval=burnRate);

  {
    record: recordingRuleName,
    expr: expression,
  };

{
  // This generates recording rules for metrics with high-cardinality
  // that are specified in the service catalog under the
  // `recordingRuleMetrics` attribute.
  sliRecordingRulesSet(
    burnRate,
    recordingRuleRegistry,
  )::
    {
      burnRate: burnRate,

      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        local components = serviceDefinition.components;
        if std.objectHas(serviceDefinition, 'recordingRuleMetrics') then
          [
            generateRecordingRulesForMetric(recordingRuleMetric, burnRate, recordingRuleRegistry)
            for recordingRuleMetric in serviceDefinition.recordingRuleMetrics
          ]
        else
          [],
    },

}
