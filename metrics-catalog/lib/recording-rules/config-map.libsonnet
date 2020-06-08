local componentMetricsRuleSet = (import 'component-metrics-rule-set.libsonnet').componentMetricsRuleSet;
local componentMappingRuleSet = (import 'component-mapping-rule-set.libsonnet').componentMappingRuleSet;
local serviceMappingRuleSet = (import 'service-mapping-rule-set.libsonnet').serviceMappingRuleSet;
local serviceSLORuleSet = (import 'service-slo-rule-set.libsonnet').serviceSLORuleSet;
local componentErrorRatioRuleSet = (import 'component-error-ratio-rule-set.libsonnet').componentErrorRatioRuleSet;
local serviceErrorRatioRuleSet = (import 'service-error-ratio-rule-set.libsonnet').serviceErrorRatioRuleSet;
local serviceNodeErrorRatioRuleSet = (import 'service-node-error-ratio-rule-set.libsonnet').serviceNodeErrorRatioRuleSet;

local COMPONENT_LEVEL_AGGREGATION_LABELS = ['environment', 'tier', 'type', 'stage'];
local NODE_LEVEL_AGGREGATION_LABELS = ['environment', 'tier', 'type', 'stage', 'shard', 'fqdn'];

local MULTI_BURN_RATE_SUFFIXES = [
  '',  // For historical reasons, no suffix implies 1m
  '_5m',
  '_30m',
  '_1h',
  '_6h',
];

local ruleSetIterator(ruleSets) = {
  generateRecordingRulesForService(serviceDefinition)::
    std.flatMap(function(ruleSet) ruleSet.generateRecordingRulesForService(serviceDefinition), ruleSets),

  generateRecordingRulesForServices(services)::
    std.flatMap(function(serviceDefinition) self.generateRecordingRulesForService(serviceDefinition), services),

  generateRecordingRules()::
    std.flatMap(function(ruleSet) ruleSet.generateRecordingRules(), ruleSets),
};

{
  // Recording rules that get evaluated in Prometheus
  // should be contained within this stanza
  prometheus: {

    // Component metrics are the key metrics for each component.
    // Each burn-rate is a separate ruleset.
    componentMetrics: ruleSetIterator([
      componentMetricsRuleSet(
        burnRate='1m',
        // TODO: consider renaming the 1m rates for consistency
        apdexRatio='gitlab_component_apdex:ratio',
        apdexWeight='gitlab_component_apdex:weight:score',
        requestRate='gitlab_component_ops:rate',
        errorRate='gitlab_component_errors:rate',
        aggregationLabels=COMPONENT_LEVEL_AGGREGATION_LABELS,
      ),
      componentMetricsRuleSet(
        burnRate='5m',
        apdexRatio='gitlab_component_apdex:ratio_5m',
        apdexWeight='gitlab_component_apdex:weight:score_5m',
        requestRate='gitlab_component_ops:rate_5m',
        errorRate='gitlab_component_errors:rate_5m',
        aggregationLabels=COMPONENT_LEVEL_AGGREGATION_LABELS,
      ),
      componentMetricsRuleSet(
        burnRate='30m',
        apdexRatio='gitlab_component_apdex:ratio_30m',
        apdexWeight='gitlab_component_apdex:weight:score_30m',
        requestRate='gitlab_component_ops:rate_30m',
        errorRate='gitlab_component_errors:rate_30m',
        aggregationLabels=COMPONENT_LEVEL_AGGREGATION_LABELS,
      ),
      componentMetricsRuleSet(
        burnRate='1h',
        apdexRatio='gitlab_component_apdex:ratio_1h',
        apdexWeight='gitlab_component_apdex:weight:score_1h',
        requestRate='gitlab_component_ops:rate_1h',
        errorRate='gitlab_component_errors:rate_1h',
        aggregationLabels=COMPONENT_LEVEL_AGGREGATION_LABELS,
      ),
      componentMetricsRuleSet(
        burnRate='6h',
        apdexRatio='gitlab_component_apdex:ratio_6h',
        apdexWeight='gitlab_component_apdex:weight:score_6h',
        requestRate='gitlab_component_ops:rate_6h',
        errorRate='gitlab_component_errors:rate_6h',
        aggregationLabels=COMPONENT_LEVEL_AGGREGATION_LABELS,
      ),
    ]),

    // Nodes metrics are the key metrics for each component, aggregated to the
    // node level.
    //
    // Each burn-rate is a separate ruleset.
    nodeMetrics: ruleSetIterator([
      componentMetricsRuleSet(
        burnRate='1m',
        // TODO: consider renaming the 1m rates for consistency
        apdexRatio='gitlab_component_node_apdex:ratio',
        apdexWeight='gitlab_component_node_apdex:weight:score',
        requestRate='gitlab_component_node_ops:rate',
        errorRate='gitlab_component_node_errors:rate',
        aggregationLabels=NODE_LEVEL_AGGREGATION_LABELS,
      ),
      componentMetricsRuleSet(
        burnRate='5m',
        requestRate='gitlab_component_node_ops:rate_5m',
        errorRate='gitlab_component_node_errors:rate_5m',
        aggregationLabels=NODE_LEVEL_AGGREGATION_LABELS,
      ),
      componentMetricsRuleSet(
        burnRate='30m',
        requestRate='gitlab_component_node_ops:rate_30m',
        errorRate='gitlab_component_node_errors:rate_30m',
        aggregationLabels=NODE_LEVEL_AGGREGATION_LABELS,
      ),
      componentMetricsRuleSet(
        burnRate='1h',
        requestRate='gitlab_component_node_ops:rate_1h',
        errorRate='gitlab_component_node_errors:rate_1h',
        aggregationLabels=NODE_LEVEL_AGGREGATION_LABELS,
      ),
      componentMetricsRuleSet(
        burnRate='6h',
        requestRate='gitlab_component_node_ops:rate_6h',
        errorRate='gitlab_component_node_errors:rate_6h',
        aggregationLabels=NODE_LEVEL_AGGREGATION_LABELS,
      ),
    ]),

    // Component mappings are static recording rules which help
    // determine whether a component is being monitored. This helps
    // prevent spurious alerts when a component is decommissioned.
    componentMapping: ruleSetIterator([
      componentMappingRuleSet(),
    ]),
  },

  // Recording rules that get evaluated in Thanos
  thanos: {
    // The service SLO rules map SLOs to static recording rules,
    // for use in alerting, dashboards, etc
    serviceSLOs: ruleSetIterator([
      serviceSLORuleSet(),
    ]),

    // Component-level ratios, aggregated at the Thanos level, to
    // prevent split-brain aggregation prometheus issues and
    // spurious alerts.
    componentErrorRatios: ruleSetIterator(std.flatMap(
      function(suffix)
        [
          componentErrorRatioRuleSet(suffix=suffix),
        ],
      MULTI_BURN_RATE_SUFFIXES
    )),

    // This rolls the component-level error ratios up to the service-level,
    // as a Thanos aggregation
    serviceErrorRatios: ruleSetIterator(std.flatMap(
      function(suffix)
        [
          serviceErrorRatioRuleSet(suffix=suffix),
          serviceNodeErrorRatioRuleSet(suffix=suffix),
        ],
      MULTI_BURN_RATE_SUFFIXES
    )),

    // Component mappings are static recording rules which help
    // determine whether a component is being monitored. This helps
    // prevent spurious alerts when a component is decommissioned.
    serviceMapping: ruleSetIterator([
      serviceMappingRuleSet(),
    ]),

  },
}
