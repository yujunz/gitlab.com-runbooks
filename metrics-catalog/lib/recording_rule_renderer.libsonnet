local recordingRules = import './recording_rules.libsonnet';

local COMPONENT_LEVEL_AGGREGATION_LABELS = ['environment', 'tier', 'type', 'stage'];
local NODE_LEVEL_AGGREGATION_LABELS = ['environment', 'tier', 'type', 'stage', 'shard', 'fqdn'];

local COMPONENT_LEVEL_RECORDING_RULE_NAMES = {
  '1m': {
    // TODO: consider renaming the 1m rates for consistency
    apdexRatio: 'gitlab_component_apdex:ratio',
    apdexWeight: 'gitlab_component_apdex:weight:score',
    requestRate: 'gitlab_component_ops:rate',
    errorRate: 'gitlab_component_errors:rate',
  },
  '5m': {
    requestRate: 'gitlab_component_ops:rate_5m',
    errorRate: 'gitlab_component_errors:rate_5m',
  },
  '30m': {
    requestRate: 'gitlab_component_ops:rate_30m',
    errorRate: 'gitlab_component_errors:rate_30m',
  },
  '1h': {
    requestRate: 'gitlab_component_ops:rate_1h',
    errorRate: 'gitlab_component_errors:rate_1h',
  },
  '6h': {
    requestRate: 'gitlab_component_ops:rate_6h',
    errorRate: 'gitlab_component_errors:rate_6h',
  },
};

local NODE_LEVEL_RECORDING_RULE_NAMES = {
  '1m': {
    // TODO: consider renaming the 1m rates for consistency
    apdexRatio: 'gitlab_component_node_apdex:ratio',
    apdexWeight: 'gitlab_component_node_apdex:weight:score',
    requestRate: 'gitlab_component_node_ops:rate',
    errorRate: 'gitlab_component_node_errors:rate',
  },
  '5m': {
    requestRate: 'gitlab_component_node_ops:rate_5m',
    errorRate: 'gitlab_component_node_errors:rate_5m',
  },
  '30m': {
    requestRate: 'gitlab_component_node_ops:rate_30m',
    errorRate: 'gitlab_component_node_errors:rate_30m',
  },
  '1h': {
    requestRate: 'gitlab_component_node_ops:rate_1h',
    errorRate: 'gitlab_component_node_errors:rate_1h',
  },
  '6h': {
    requestRate: 'gitlab_component_node_ops:rate_6h',
    errorRate: 'gitlab_component_node_errors:rate_6h',
  },
};

// Generates apdex score recording rules for a component definition
local generateApdexRules(aggregationLabels, componentDefinition, recordingRuleStaticLabels, recordingRuleNames) =
  if std.objectHas(componentDefinition, 'apdex') then
    // We don't currently maintain multiburn, multiwindow apdex scores
    local rangeIntervals = std.filter(function(rangeInterval) std.objectHas(recordingRuleNames[rangeInterval], 'apdexRatio'), std.objectFields(recordingRuleNames));

    [
      recordingRules.apdex(
        name=recordingRuleNames[rangeInterval].apdexRatio,
        labels=recordingRuleStaticLabels,
        expr=componentDefinition.apdex.apdexQuery(aggregationLabels, selector='', rangeInterval=rangeInterval)
      )
      for rangeInterval in rangeIntervals
    ] +
    [
      recordingRules.apdexWeight(
        name=recordingRuleNames[rangeInterval].apdexWeight,
        labels=recordingRuleStaticLabels,
        expr=componentDefinition.apdex.apdexWeightQuery(aggregationLabels, selector='', rangeInterval=rangeInterval)
      )
      for rangeInterval in rangeIntervals
    ]
  else
    [];

// Generates an request rate recording rule for a component definition
local generateRequestRateRules(aggregationLabels, componentDefinition, recordingRuleStaticLabels, recordingRuleNames) =
  if std.objectHas(componentDefinition, 'requestRate') then
    [
      recordingRules.requestRate(
        name=recordingRuleNames[rangeInterval].requestRate,
        labels=recordingRuleStaticLabels,
        expr=componentDefinition.requestRate.aggregatedRateQuery(aggregationLabels, selector='', rangeInterval=rangeInterval),
      )
      for rangeInterval in std.objectFields(recordingRuleNames)
    ]
  else
    [];

// Generates an request rate recording rule for a component definition
local generateErrorRateRules(aggregationLabels, componentDefinition, recordingRuleStaticLabels, recordingRuleNames) =
  if std.objectHas(componentDefinition, 'errorRate') then
    [
      recordingRules.errorRate(
        name=recordingRuleNames[rangeInterval].errorRate,
        labels=recordingRuleStaticLabels,
        expr=componentDefinition.errorRate.aggregatedRateQuery(aggregationLabels, selector='', rangeInterval=rangeInterval),
      )
      for rangeInterval in std.objectFields(recordingRuleNames)
    ]
  else
    [];

local generateServiceSLORules(serviceDefinition) =
  local hasSlos = std.objectHas(serviceDefinition, 'slos');

  local triggerDurationLabels = if hasSlos && std.objectHas(serviceDefinition.slos, 'alertTriggerDuration') then
    {
      alert_trigger_duration: serviceDefinition.slos.alertTriggerDuration,
    }
  else {};

  local labels = {
    type: serviceDefinition.type,
    tier: serviceDefinition.tier,
  } + triggerDurationLabels;

  std.prune([
    if hasSlos && std.objectHas(serviceDefinition.slos, 'apdexRatio') then
      recordingRules.minApdexSLO(
        labels=labels,
        expr='%g' % [serviceDefinition.slos.apdexRatio]
      )
    else null,

    if hasSlos && std.objectHas(serviceDefinition.slos, 'errorRatio') then
      recordingRules.maxErrorsSLO(
        labels=labels,
        expr='%g' % [serviceDefinition.slos.errorRatio],
      )
    else null,
  ]);

local generateComponentRecordingRules(componentName, serviceDefinition, componentDefinition, recordingRuleNames, aggregationLabels) =
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
  local aggregationLabelsString = std.join(', ', aggregationLabelsArray);

  generateApdexRules(aggregationLabelsString, componentDefinition, labels, recordingRuleNames) +
  generateRequestRateRules(aggregationLabelsString, componentDefinition, labels, recordingRuleNames) +
  generateErrorRateRules(aggregationLabelsString, componentDefinition, labels, recordingRuleNames);

local generateComponentRecordingRulesForAggregations(serviceDefinition, recordingRuleNames, aggregationLabels) =
  local components = serviceDefinition.components;

  std.flattenArrays(
    std.map(
      function(componentName) generateComponentRecordingRules(componentName, serviceDefinition, components[componentName], recordingRuleNames, aggregationLabels),
      std.objectFields(components)
    )
  );

local generateComponentRecordingRules(serviceDefinition) =
  generateComponentRecordingRulesForAggregations(serviceDefinition, COMPONENT_LEVEL_RECORDING_RULE_NAMES, COMPONENT_LEVEL_AGGREGATION_LABELS);

local generateNodeRecordingRules(serviceDefinition) =
  generateComponentRecordingRulesForAggregations(serviceDefinition, NODE_LEVEL_RECORDING_RULE_NAMES, NODE_LEVEL_AGGREGATION_LABELS);

{
  keyMetrics(services)::
    std.flattenArrays(std.map(generateComponentRecordingRules, services)),

  serviceSLOs(services)::
    std.flattenArrays(std.map(generateServiceSLORules, services)),

  nodeMetrics(services)::
    std.flattenArrays(std.map(generateNodeRecordingRules, services)),

}
