// Generates apdex score recording rules for a component definition
local generateApdexScoreRules(ruleSet, aggregationLabels, componentDefinition, recordingRuleStaticLabels) =
  if ruleSet.recordingRuleNames.apdexRatio != null && std.objectHas(componentDefinition, 'apdex') then
    [{
      record: ruleSet.recordingRuleNames.apdexRatio,
      labels: recordingRuleStaticLabels,
      expr: componentDefinition.apdex.apdexQuery(aggregationLabels, selector={}, rangeInterval=ruleSet.burnRate),
    }]
  else
    [];

// Generates apdex weight recording rules for a component definition
local generateApdexWeightRules(ruleSet, aggregationLabels, componentDefinition, recordingRuleStaticLabels) =
  if ruleSet.recordingRuleNames.apdexWeight != null && std.objectHas(componentDefinition, 'apdex') then
    [{
      record: ruleSet.recordingRuleNames.apdexWeight,
      labels: recordingRuleStaticLabels,
      expr: componentDefinition.apdex.apdexWeightQuery(aggregationLabels, selector={}, rangeInterval=ruleSet.burnRate),
    }]
  else
    [];

local generateRequestRateRules(ruleSet, aggregationLabels, componentDefinition, recordingRuleStaticLabels) =
  if ruleSet.recordingRuleNames.requestRate != null && std.objectHas(componentDefinition, 'requestRate') then
    [{
      record: ruleSet.recordingRuleNames.requestRate,
      labels: recordingRuleStaticLabels,
      expr: componentDefinition.requestRate.aggregatedRateQuery(aggregationLabels, selector={}, rangeInterval=ruleSet.burnRate),
    }]
  else
    [];

local generateErrorRateRules(ruleSet, aggregationLabels, componentDefinition, recordingRuleStaticLabels) =
  if ruleSet.recordingRuleNames.errorRate != null && std.objectHas(componentDefinition, 'errorRate') then
    [{
      record: ruleSet.recordingRuleNames.errorRate,
      labels: recordingRuleStaticLabels,
      expr: componentDefinition.errorRate.aggregatedRateQuery(aggregationLabels, selector={}, rangeInterval=ruleSet.burnRate),
    }]
  else
    [];

// Generates the recording rules given a component definition
local generateRecordingRulesForComponent(ruleSet, serviceDefinition, componentName, componentDefinition, aggregationLabels) =
  local staticLabels =
    if std.objectHas(componentDefinition, 'staticLabels') then
      componentDefinition.staticLabels
    else
      {};

  local labels = {
    tier: serviceDefinition.tier,
    type: serviceDefinition.type,
    component: componentName,
  } + staticLabels;

  // Remove any fixed labels from the aggregation labels
  local aggregationLabelsArray = std.filter(function(label) !std.objectHas(labels, label), aggregationLabels);

  std.flatMap(
    function(generator) generator(ruleSet, aggregationLabelsArray, componentDefinition, labels),
    [
      generateApdexScoreRules,
      generateApdexWeightRules,
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
  )::
    {
      burnRate: burnRate,
      aggregationLabels: aggregationLabels,
      recordingRuleNames: {
        apdexRatio: apdexRatio,
        apdexWeight: apdexWeight,
        requestRate: requestRate,
        errorRate: errorRate,
      },

      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        local components = serviceDefinition.components;

        std.flatMap(
          function(componentName) generateRecordingRulesForComponent(self, serviceDefinition, componentName, components[componentName], aggregationLabels),
          std.objectFields(components)
        ),
    },

}
