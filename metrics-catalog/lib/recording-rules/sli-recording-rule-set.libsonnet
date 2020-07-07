local recordingRuleRegistry = import '../recording-rule-registry.libsonnet';

local generateRecordingRulesForMetric(recordingRuleMetric, burnRate) =
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
    burnRate
  )::
    {
      burnRate: burnRate,

      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        local components = serviceDefinition.components;
        if std.objectHas(serviceDefinition, 'recordingRuleMetrics') then
          [
            generateRecordingRulesForMetric(recordingRuleMetric, burnRate)
            for recordingRuleMetric in serviceDefinition.recordingRuleMetrics
          ]
        else
          [],
    },

}
