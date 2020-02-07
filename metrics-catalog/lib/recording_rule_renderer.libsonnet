local recordingRules = import './recording_rules.libsonnet';

local COMPONENT_LEVEL_AGGREGATION_LABELS = ['environment', 'tier', 'type', 'stage'];
local NODE_LEVEL_AGGREGATION_LABELS = ['environment', 'tier', 'type', 'stage', 'shard', 'fqdn'];

local COMPONENT_LEVEL_RECORDING_RULE_NAMES = {
  apdexRatio: 'gitlab_component_apdex:ratio',
  apdexWeight: 'gitlab_component_apdex:weight:score',
  requestRate: 'gitlab_component_ops:rate',
  errorRate: 'gitlab_component_errors:rate',
};

local NODE_LEVEL_RECORDING_RULE_NAMES = {
  apdexRatio: 'gitlab_component_node_apdex:ratio',
  apdexWeight: 'gitlab_component_node_apdex:weight:score',
  requestRate: 'gitlab_component_node_ops:rate',
  errorRate: 'gitlab_component_node_errors:rate',
};

// Generates apdex score recording rules for a component definition
local generateApdexRules(aggregationLabels, componentDefinition, recordingRuleStaticLabels, recordingRuleNames) =
  if std.objectHas(componentDefinition, 'apdex') then
    [
      recordingRules.apdex(
        name=recordingRuleNames.apdexRatio,
        labels=recordingRuleStaticLabels,
        expr=componentDefinition.apdex.apdexQuery(aggregationLabels, selector='', rangeInterval='1m')
      ),
      recordingRules.apdexWeight(
        name=recordingRuleNames.apdexWeight,
        labels=recordingRuleStaticLabels,
        expr=componentDefinition.apdex.apdexWeightQuery(aggregationLabels, selector='', rangeInterval='1m')
      ),
    ]
  else
    [];

// Generates an request rate recording rule for a component definition
local generateRequestRateRules(aggregationLabels, componentDefinition, recordingRuleStaticLabels, recordingRuleNames) =
  if std.objectHas(componentDefinition, 'requestRate') then
    [
      recordingRules.requestRate(
        name=recordingRuleNames.requestRate,
        labels=recordingRuleStaticLabels,
        expr=componentDefinition.requestRate.aggregatedRateQuery(aggregationLabels, selector='', rangeInterval='1m'),
      ),
    ]
  else
    [];

// Generates an request rate recording rule for a component definition
local generateErrorRateRules(aggregationLabels, componentDefinition, recordingRuleStaticLabels, recordingRuleNames) =
  if std.objectHas(componentDefinition, 'errorRate') then
    [
      recordingRules.errorRate(
        name=recordingRuleNames.errorRate,
        labels=recordingRuleStaticLabels,
        expr=componentDefinition.errorRate.aggregatedRateQuery(aggregationLabels, selector='', rangeInterval='1m'),
      ),
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
  yaml(services)::
    // Select all services with `autogenerateRecordingRules` (default on)
    local selectedServices = std.filter(function(service) ({ autogenerateRecordingRules: true } + service).autogenerateRecordingRules, services);

    // Subselect services with `nodeLevelMonitoring` (default off)
    local servicesWithNodeLevelMonitoring = std.filter(function(service) ({ nodeLevelMonitoring: false } + service).nodeLevelMonitoring, selectedServices);

    std.manifestYamlDoc({
      groups: [
        {
          name: 'Autogenerated Service SLOs',
          interval: '5m',
          rules: std.flattenArrays(std.map(generateServiceSLORules, selectedServices)),
        },
        {
          name: 'Autogenerated Component-Level SLIs',
          interval: '1m',
          rules: std.flattenArrays(std.map(generateComponentRecordingRules, selectedServices)),
        },
        {
          name: 'Autogenerated Node-Level SLIs',
          interval: '1m',
          rules: std.flattenArrays(std.map(generateNodeRecordingRules, servicesWithNodeLevelMonitoring)),
        },
      ],
    }),

}
