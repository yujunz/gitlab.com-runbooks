// Generates apdex weight recording rules for a component definition
local generateApdexWeightRules(burnRate, recordingRuleNames, aggregationLabels, componentDefinition, recordingRuleStaticLabels) =
  if recordingRuleNames.apdexWeight != null then
    componentDefinition.generateApdexWeightRecordingRules(
      burnRate=burnRate,
      recordingRuleName=recordingRuleNames.apdexWeight,
      aggregationLabels=aggregationLabels,
      recordingRuleStaticLabels=recordingRuleStaticLabels
    )
  else
    [];

// Generates a curryable function to apdex score recording rules for a component definition
local generateApdexScoreRulesCurry(substituteWeightWithRecordingRule) =
  function(burnRate, recordingRuleNames, aggregationLabels, componentDefinition, recordingRuleStaticLabels)
    if recordingRuleNames.apdexRatio != null then
      componentDefinition.generateApdexScoreRecordingRules(
        burnRate=burnRate,
        recordingRuleName=recordingRuleNames.apdexRatio,
        aggregationLabels=aggregationLabels,
        recordingRuleStaticLabels=recordingRuleStaticLabels,
        substituteWeightWithRecordingRuleName=if substituteWeightWithRecordingRule then recordingRuleNames.apdexWeight else null
      )
    else
      [];

local generateRequestRateRules(burnRate, recordingRuleNames, aggregationLabels, componentDefinition, recordingRuleStaticLabels) =
  // All components have a requestRate metric
  if recordingRuleNames.requestRate != null then
    componentDefinition.generateRequestRateRecordingRules(
      burnRate=burnRate,
      recordingRuleName=recordingRuleNames.requestRate,
      aggregationLabels=aggregationLabels,
      recordingRuleStaticLabels=recordingRuleStaticLabels
    )
  else
    [];

local generateErrorRateRules(burnRate, recordingRuleNames, aggregationLabels, componentDefinition, recordingRuleStaticLabels) =
  if recordingRuleNames.errorRate != null then
    componentDefinition.generateErrorRateRecordingRules(
      burnRate=burnRate,
      recordingRuleName=recordingRuleNames.errorRate,
      aggregationLabels=aggregationLabels,
      recordingRuleStaticLabels=recordingRuleStaticLabels
    )
  else
    [];

// Generates the recording rules given a component definition
local generateRecordingRulesForComponent(burnRate, recordingRuleNames, serviceDefinition, componentDefinition, aggregationLabels, substituteWeightWithRecordingRule) =
  local recordingRuleStaticLabels = {
    tier: serviceDefinition.tier,
    type: serviceDefinition.type,
    component: componentDefinition.name,
  };

  std.flatMap(
    function(generator) generator(burnRate=burnRate, recordingRuleNames=recordingRuleNames, aggregationLabels=aggregationLabels, componentDefinition=componentDefinition, recordingRuleStaticLabels=recordingRuleStaticLabels),
    [
      generateApdexWeightRules,
      generateApdexScoreRulesCurry(substituteWeightWithRecordingRule),
      generateRequestRateRules,
      generateErrorRateRules,
    ]
  );

{
  // This component metrics ruleset applies the key metrics recording rules for
  // each component in the metrics catalog
  componentMetricsRuleSet(
    burnRate,
    apdexRatio=null,
    apdexWeight=null,
    requestRate=null,
    errorRate=null,
    aggregationLabels=[],
    substituteWeightWithRecordingRule=false,
  )::
    local recordingRuleNames = {
      apdexRatio: apdexRatio,
      apdexWeight: apdexWeight,
      requestRate: requestRate,
      errorRate: errorRate,
    };

    {
      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        local components = serviceDefinition.components;

        std.flatMap(
          function(componentDefinition) generateRecordingRulesForComponent(
            burnRate=burnRate,
            recordingRuleNames=recordingRuleNames,
            serviceDefinition=serviceDefinition,
            componentDefinition=componentDefinition,
            aggregationLabels=aggregationLabels,
            substituteWeightWithRecordingRule=substituteWeightWithRecordingRule
          ),
          serviceDefinition.getComponentsList()
        ),
    },

}
