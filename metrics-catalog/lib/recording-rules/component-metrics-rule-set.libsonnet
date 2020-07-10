local selectors = import './lib/selectors.libsonnet';

// Generates apdex weight recording rules for a component definition
local generateApdexWeightRules(ruleSet, aggregationLabels, componentDefinition, recordingRuleStaticLabels) =
  if ruleSet.recordingRuleNames.apdexWeight != null && componentDefinition.hasApdex() then
    [{
      record: ruleSet.recordingRuleNames.apdexWeight,
      labels: recordingRuleStaticLabels,
      expr: componentDefinition.apdex.apdexWeightQuery(aggregationLabels, selector={}, rangeInterval=ruleSet.burnRate),
    }]
  else
    [];

// Generates a curryable function to apdex score recording rules for a component definition
local generateApdexScoreRulesCurry(substituteWeightWithRecordingRule) =
  function(ruleSet, aggregationLabels, componentDefinition, recordingRuleStaticLabels)
    local weightRecordingRule = if substituteWeightWithRecordingRule then
      '%(recordingRule)s{%(selector)s}' % {
        recordingRule: ruleSet.recordingRuleNames.apdexWeight,
        selector: selectors.serializeHash(recordingRuleStaticLabels),
      }
    else
      null;

    if ruleSet.recordingRuleNames.apdexRatio != null && componentDefinition.hasApdex() then
      [{
        record: ruleSet.recordingRuleNames.apdexRatio,
        labels: recordingRuleStaticLabels,
        expr: componentDefinition.apdex.apdexQuery(
          aggregationLabels,
          selector={},
          rangeInterval=ruleSet.burnRate,
          substituteWeightWithRecordingRule=weightRecordingRule,
        ),
      }]
    else
      [];

local generateRequestRateRules(ruleSet, aggregationLabels, componentDefinition, recordingRuleStaticLabels) =
  // All components has a requestRate metric
  if ruleSet.recordingRuleNames.requestRate != null then
    [{
      record: ruleSet.recordingRuleNames.requestRate,
      labels: recordingRuleStaticLabels,
      expr: componentDefinition.requestRate.aggregatedRateQuery(aggregationLabels, selector={}, rangeInterval=ruleSet.burnRate),
    }]
  else
    [];

local generateErrorRateRules(ruleSet, aggregationLabels, componentDefinition, recordingRuleStaticLabels) =
  if ruleSet.recordingRuleNames.errorRate != null && componentDefinition.hasErrorRate() then
    [{
      record: ruleSet.recordingRuleNames.errorRate,
      labels: recordingRuleStaticLabels,
      expr: componentDefinition.errorRate.aggregatedRateQuery(aggregationLabels, selector={}, rangeInterval=ruleSet.burnRate),
    }]
  else
    [];

// Generates the recording rules given a component definition
local generateRecordingRulesForComponent(ruleSet, serviceDefinition, componentName, componentDefinition, aggregationLabels, substituteWeightWithRecordingRule) =
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
    {
      burnRate: burnRate,
      aggregationLabels: aggregationLabels,
      recordingRuleNames: {
        apdexRatio: apdexRatio,
        apdexWeight: apdexWeight,
        requestRate: requestRate,
        errorRate: errorRate,
      },
      substituteWeightWithRecordingRule: substituteWeightWithRecordingRule,

      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        local components = serviceDefinition.components;

        std.flatMap(
          function(componentName) generateRecordingRulesForComponent(self, serviceDefinition, componentName, components[componentName], aggregationLabels, substituteWeightWithRecordingRule),
          std.objectFields(components)
        ),
    },

}
