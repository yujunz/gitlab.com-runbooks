local selectors = import 'promql/selectors.libsonnet';

// For now we assume that services are provisioned on vms and not kubernetes
local componentDefaults = {
  staticLabels: {},  // by default, no static labels
  aggregateRequestRate: true,  // by default, requestRate is aggregated up to the service level
};

local validateHasField(object, field, message) =
  if std.objectHas(object, field) then
    object
  else
    std.assertEqual(object, { __assert: message });

local validateAndApplyComponentDefaults(componentName, component) =
  // All components must have a requestRate measurement, since
  // we filter out low-RPS alerts for apdex monitoring and require the RPS for error ratios
  componentDefaults
  +
  validateHasField(component, 'requestRate', '%s component requires a requestRate measurement' % [componentName])
  +
  validateHasField(component, 'significantLabels', '%s component requires a significantLabels attribute' % [componentName])
  {
    name: componentName,
  };

// Given an array of labels to aggregate by, filters out those that exist in the staticLabels hash
local filterStaticLabelsFromAggregationLabels(aggregationLabels, staticLabelsHash) =
  std.filter(function(label) !std.objectHas(staticLabelsHash, label), aggregationLabels);

// Definition of a component
local componentDefinition(componentName, component) =
  component {
    // Returns true if this component allows detailed breakdowns
    // this is not the case for combined component definitions
    supportsDetails(): true,

    hasApdex():: std.objectHas(component, 'apdex'),
    hasRequestRate():: true,  // requestRate is mandatory
    hasAggregatableRequestRate():: std.objectHasAll(component.requestRate, 'aggregatedRateQuery'),
    hasErrorRate():: std.objectHas(component, 'errorRate'),

    hasToolingLinks()::
      std.objectHasAll(component, 'toolingLinks'),

    getToolingLinks()::
      if self.hasToolingLinks() then
        std.flatMap(function(toolingLinkDefinition) toolingLinkDefinition, self.toolingLinks)
      else
        [],

    // Generate recording rules for apdex weight
    generateApdexWeightRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels)::
      local allStaticLabels = recordingRuleStaticLabels + component.staticLabels;

      if self.hasApdex() then
        [{
          record: recordingRuleName,
          labels: allStaticLabels,
          expr: component.apdex.apdexWeightQuery(
            aggregationLabels=filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels),
            selector={},
            rangeInterval=burnRate
          ),
        }]
      else
        [],

    // Generate recording rules for apdex score
    generateApdexScoreRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels, substituteWeightWithRecordingRuleName)::
      local allStaticLabels = recordingRuleStaticLabels + component.staticLabels;

      local substituteWeightWithRecordingRuleExpression = if substituteWeightWithRecordingRuleName != null then
        '%(recordingRule)s{%(selector)s}' % {
          recordingRule: substituteWeightWithRecordingRuleName,
          selector: selectors.serializeHash(allStaticLabels),
        }
      else
        null;

      if self.hasApdex() then
        [{
          record: recordingRuleName,
          labels: allStaticLabels,
          expr: component.apdex.apdexQuery(
            aggregationLabels=filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels),
            selector={},
            rangeInterval=burnRate,
            substituteWeightWithRecordingRule=substituteWeightWithRecordingRuleExpression,
          ),
        }]
      else
        [],

    // Generate recording rules for request rate
    generateRequestRateRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels)::
      local allStaticLabels = recordingRuleStaticLabels + component.staticLabels;

      [{
        record: recordingRuleName,
        labels: allStaticLabels,
        expr: component.requestRate.aggregatedRateQuery(
          aggregationLabels=filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels),
          selector={},
          rangeInterval=burnRate
        ),
      }],

    // Generate recording rules for error rate
    generateErrorRateRecordingRules(burnRate, recordingRuleName, aggregationLabels, recordingRuleStaticLabels)::
      local allStaticLabels = recordingRuleStaticLabels + component.staticLabels;

      if self.hasErrorRate() then
        [{
          record: recordingRuleName,
          labels: allStaticLabels,
          expr: component.errorRate.aggregatedRateQuery(
            aggregationLabels=filterStaticLabelsFromAggregationLabels(aggregationLabels, allStaticLabels),
            selector={},
            rangeInterval=burnRate
          ),
        }]
      else
        [],
  };

{
  componentDefinition(component)::
    {
      initComponentWithName(componentName)::
        componentDefinition(componentName, validateAndApplyComponentDefaults(componentName, component)),
    },
}
