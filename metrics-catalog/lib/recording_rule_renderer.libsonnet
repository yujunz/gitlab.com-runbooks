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
    apdexRatio: 'gitlab_component_apdex:ratio_5m',
    apdexWeight: 'gitlab_component_apdex:weight:score_5m',
    requestRate: 'gitlab_component_ops:rate_5m',
    errorRate: 'gitlab_component_errors:rate_5m',
  },
  '30m': {
    apdexRatio: 'gitlab_component_apdex:ratio_30m',
    apdexWeight: 'gitlab_component_apdex:weight:score_30m',
    requestRate: 'gitlab_component_ops:rate_30m',
    errorRate: 'gitlab_component_errors:rate_30m',
  },
  '1h': {
    apdexRatio: 'gitlab_component_apdex:ratio_1h',
    apdexWeight: 'gitlab_component_apdex:weight:score_1h',
    requestRate: 'gitlab_component_ops:rate_1h',
    errorRate: 'gitlab_component_errors:rate_1h',
  },
  '6h': {
    apdexRatio: 'gitlab_component_apdex:ratio_6h',
    apdexWeight: 'gitlab_component_apdex:weight:score_6h',
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

local multiburnrateSuffixes = [
  '',  // For historical reasons, no suffix implies 1m
  '_5m',
  '_30m',
  '_1h',
  '_6h',
];

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
  local hasMonitoringThresholds = std.objectHas(serviceDefinition, 'monitoringThresholds');
  local hasEventBasedSLOTargets = std.objectHas(serviceDefinition, 'eventBasedSLOTargets');

  local triggerDurationLabels = if hasMonitoringThresholds && std.objectHas(serviceDefinition.monitoringThresholds, 'alertTriggerDuration') then
    {
      alert_trigger_duration: serviceDefinition.monitoringThresholds.alertTriggerDuration,
    }
  else {};

  local labels = {
    type: serviceDefinition.type,
    tier: serviceDefinition.tier,
  };

  local labelsWithTriggerDurations = labels + triggerDurationLabels;

  std.prune([
    if hasMonitoringThresholds && std.objectHas(serviceDefinition.monitoringThresholds, 'apdexRatio') then
      recordingRules.minApdexSLO(
        labels=labelsWithTriggerDurations,
        expr='%f' % [serviceDefinition.monitoringThresholds.apdexRatio]
      )
    else null,

    if hasMonitoringThresholds && std.objectHas(serviceDefinition.monitoringThresholds, 'errorRatio') then
      recordingRules.maxErrorsSLO(
        labels=labelsWithTriggerDurations,
        expr='%f' % [serviceDefinition.monitoringThresholds.errorRatio],
      )
    else null,

    // Min apdex SLO (multiburn)
    if hasEventBasedSLOTargets && std.objectHas(serviceDefinition.eventBasedSLOTargets, 'apdexScore') then
      recordingRules.minApdexTargetSLO(
        labels=labels,
        expr='%f' % [serviceDefinition.eventBasedSLOTargets.apdexScore],
      )
    else null,

    // Note: the max error rate is `1 - sla` (multiburn)
    if hasEventBasedSLOTargets && std.objectHas(serviceDefinition.eventBasedSLOTargets, 'errorRatio') then
      recordingRules.maxErrorsEventRateSLO(
        labels=labels,
        expr='%f' % [1 - serviceDefinition.eventBasedSLOTargets.errorRatio],
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

local componentErrorRatioTemplate = |||
  gitlab_component_errors:rate%(prefix)s
  /
  gitlab_component_ops:rate%(prefix)s
|||;

local serviceErrorRatioTemplate = |||
  sum by (environment, tier, type, stage) (gitlab_component_errors:rate%(prefix)s >= 0)
  /
  sum by (environment, tier, type, stage) (gitlab_component_ops:rate%(prefix)s > 0)
|||;

local serviceNodeErrorRatioTemplate = |||
  sum by (environment, tier, type, stage, shard, fqdn) (gitlab_component_node_errors:rate%(prefix)s >= 0)
  /
  sum by (environment, tier, type, stage, shard, fqdn) (gitlab_component_node_ops:rate%(prefix)s > 0)
|||;

local generateServiceErrorRatiosForPrefix(prefix) =
  local format = { prefix: prefix };
  [
    {
      record: 'gitlab_service_errors:ratio%(prefix)s' % format,
      expr: serviceErrorRatioTemplate % format,
    },
    {
      record: 'gitlab_service_node_errors:ratio%(prefix)s' % format,
      expr: serviceNodeErrorRatioTemplate % format,
    },
  ];

local generateComponentErrorRatiosForPrefix(prefix) =
  local format = { prefix: prefix };

  [
    {
      record: 'gitlab_component_errors:ratio%(prefix)s' % format,
      expr: componentErrorRatioTemplate % format,
    },
  ]
  + generateServiceErrorRatiosForPrefix(prefix);  // TODO: remove service level aggregations once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689 is complete

// generateMultiWindowErrorRatios generates a set of multiwindow error ratio
// recording rules for the given set of prefixes
local generateMultiWindowErrorRatios(prefixes, generator) =
  std.flattenArrays(
    std.map(
      generator,
      prefixes
    )
  );

local serviceComponentMapping(service) =
  [
    {
      record: 'gitlab_component_service:mapping',
      labels: {
        type: service.type,
        tier: service.tier,
        component: component,
      },
      expr: '1',
    }
    for component in std.objectFields(service.components)
  ];

{
  keyMetrics(services)::
    std.flattenArrays(std.map(generateComponentRecordingRules, services)),

  serviceSLOs(services)::
    std.flattenArrays(std.map(generateServiceSLORules, services)),

  nodeMetrics(services)::
    std.flattenArrays(std.map(generateNodeRecordingRules, services)),

  serviceComponentMapping(service):: serviceComponentMapping(service),

  multiwindowComponentErrorRatios()::
    generateMultiWindowErrorRatios(multiburnrateSuffixes, generateComponentErrorRatiosForPrefix),

  multiwindowServiceErrorRatios()::
    generateMultiWindowErrorRatios(multiburnrateSuffixes, generateServiceErrorRatiosForPrefix),
}
