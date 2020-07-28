local sliRecordingRulesSet = (import 'sli-recording-rule-set.libsonnet').sliRecordingRulesSet;
local componentMetricsRuleSet = (import 'component-metrics-rule-set.libsonnet').componentMetricsRuleSet;
local componentMappingRuleSet = (import 'component-mapping-rule-set.libsonnet').componentMappingRuleSet;
local componentNodeErrorRatioRuleSet = (import 'component-node-error-ratio-rule-set.libsonnet').componentNodeErrorRatioRuleSet;
local componentNodeSLORuleSet = (import 'component-node-slo-rule-set.libsonnet').componentNodeSLORuleSet;
local serviceMappingRuleSet = (import 'service-mapping-rule-set.libsonnet').serviceMappingRuleSet;
local serviceSLORuleSet = (import 'service-slo-rule-set.libsonnet').serviceSLORuleSet;
local aggregatedComponentErrorRatioRuleSet = (import 'aggregated-component-error-ratio-rule-set.libsonnet').aggregatedComponentErrorRatioRuleSet;
local aggregatedComponentApdexRatioRuleSet = (import 'aggregated-component-apdex-ratio-rule-set.libsonnet').aggregatedComponentApdexRatioRuleSet;
local serviceErrorRatioRuleSet = (import 'service-error-ratio-rule-set.libsonnet').serviceErrorRatioRuleSet;
local serviceNodeErrorRatioRuleSet = (import 'service-node-error-ratio-rule-set.libsonnet').serviceNodeErrorRatioRuleSet;
local serviceApdexRatioRuleSet = (import 'service-apdex-ratio-rule-set.libsonnet').serviceApdexRatioRuleSet;
local serviceNodeApdexRatioRuleSet = (import 'service-node-apdex-ratio-rule-set.libsonnet').serviceNodeApdexRatioRuleSet;
local extraRecordingRuleSet = (import 'extra-recording-rule-set.libsonnet').extraRecordingRuleSet;

local COMPONENT_LEVEL_AGGREGATION_LABELS = ['environment', 'tier', 'type', 'stage'];
local NODE_LEVEL_AGGREGATION_LABELS = ['environment', 'tier', 'type', 'stage', 'shard', 'fqdn'];

local multiburnFactors = import 'lib/multiburn_factors.libsonnet';

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
    // This should only be done at the Prometheus level
    // as the group_left may not work correctly in all
    // cases at the Thanos level
    local substituteWeightWithRecordingRule = true,

    // Component metrics are the key metrics for each component.
    // Each burn-rate is a separate ruleset.
    perBurnRateRecordingRules: [
      {
        /* note: 1m burn rate evaluations are deprecated to be removed */
        local burnRate = '1m',
        burnRate: burnRate,
        evaluationInterval: '1m',
        rules: ruleSetIterator([
          // 1m burn rate intermediate recording rules. This should always be first
          sliRecordingRulesSet(burnRate),
          componentMetricsRuleSet(
            burnRate=burnRate,
            // TODO: consider renaming the 1m rates for consistency
            apdexRatio='gitlab_component_apdex:ratio',
            apdexWeight='gitlab_component_apdex:weight:score',
            requestRate='gitlab_component_ops:rate',
            errorRate='gitlab_component_errors:rate',
            aggregationLabels=COMPONENT_LEVEL_AGGREGATION_LABELS,
            substituteWeightWithRecordingRule=false,  // Initially only use this for slow burns
          ),
          extraRecordingRuleSet(burnRate),
        ]),

        nodeLevelRules: ruleSetIterator([
          // No 1m metrics
        ]),
      },
      {
        local burnRate = '5m',
        burnRate: burnRate,
        evaluationInterval: '1m',  // 5m burn rate is part of fast burn rule, evaluate every minute
        rules: ruleSetIterator([
          // 5m burn rate intermediate recording rules. This should always be first
          sliRecordingRulesSet(burnRate),
          componentMetricsRuleSet(
            burnRate=burnRate,
            apdexRatio='gitlab_component_apdex:ratio_5m',
            apdexWeight='gitlab_component_apdex:weight:score_5m',
            requestRate='gitlab_component_ops:rate_5m',
            errorRate='gitlab_component_errors:rate_5m',
            aggregationLabels=COMPONENT_LEVEL_AGGREGATION_LABELS,
            substituteWeightWithRecordingRule=false,  // Initially only use this for slow burns
          ),
          extraRecordingRuleSet(burnRate),
        ]),

        nodeLevelRules: ruleSetIterator([
          // 5m node-level metrics
          componentMetricsRuleSet(
            burnRate=burnRate,
            apdexRatio='gitlab_component_node_apdex:ratio_5m',
            apdexWeight='gitlab_component_node_apdex:weight:score_5m',
            requestRate='gitlab_component_node_ops:rate_5m',
            errorRate='gitlab_component_node_errors:rate_5m',
            aggregationLabels=NODE_LEVEL_AGGREGATION_LABELS,
          ),
        ]),

      },
      {
        local burnRate = '30m',
        burnRate: burnRate,
        evaluationInterval: '2m',  // 30m burn rate is part of slow burn rule, evaluate every 2 minutes
        rules: ruleSetIterator([
          // 30m burn rate intermediate recording rules. This should always be first
          sliRecordingRulesSet(burnRate),
          componentMetricsRuleSet(
            burnRate=burnRate,
            apdexRatio='gitlab_component_apdex:ratio_30m',
            apdexWeight='gitlab_component_apdex:weight:score_30m',
            requestRate='gitlab_component_ops:rate_30m',
            errorRate='gitlab_component_errors:rate_30m',
            aggregationLabels=COMPONENT_LEVEL_AGGREGATION_LABELS,
            substituteWeightWithRecordingRule=substituteWeightWithRecordingRule,
          ),
          extraRecordingRuleSet(burnRate='30m'),
        ]),

        nodeLevelRules: ruleSetIterator([
          // 30m node-level metrics, (no apdex)
          componentMetricsRuleSet(
            burnRate=burnRate,
            requestRate='gitlab_component_node_ops:rate_30m',
            errorRate='gitlab_component_node_errors:rate_30m',
            aggregationLabels=NODE_LEVEL_AGGREGATION_LABELS,
          ),
        ]),
      },
      {
        local burnRate = '1h',
        burnRate: burnRate,
        evaluationInterval: '1m',  // 1h burn rate is part of fast burn rule, evaluate every minute
        rules: ruleSetIterator([
          // 1h burn rate intermediate recording rules. This should always be first
          sliRecordingRulesSet(burnRate),
          componentMetricsRuleSet(
            burnRate=burnRate,
            apdexRatio='gitlab_component_apdex:ratio_1h',
            apdexWeight='gitlab_component_apdex:weight:score_1h',
            requestRate='gitlab_component_ops:rate_1h',
            errorRate='gitlab_component_errors:rate_1h',
            aggregationLabels=COMPONENT_LEVEL_AGGREGATION_LABELS,
            substituteWeightWithRecordingRule=false,  // Initially only use this for slow burns
          ),
          extraRecordingRuleSet(burnRate),
        ]),

        nodeLevelRules: ruleSetIterator([
          // 1h node-level metrics (no apdex for now)
          componentMetricsRuleSet(
            burnRate=burnRate,
            apdexRatio='gitlab_component_node_apdex:ratio_1h',
            apdexWeight='gitlab_component_node_apdex:weight:score_1h',
            requestRate='gitlab_component_node_ops:rate_1h',
            errorRate='gitlab_component_node_errors:rate_1h',
            aggregationLabels=NODE_LEVEL_AGGREGATION_LABELS,
          ),
        ]),
      },
      {
        local burnRate = '6h',
        burnRate: burnRate,
        evaluationInterval: '2m',  // 6h burn rate is part of slow burn rule, evaluate every 2 minutes
        rules: ruleSetIterator([
          // 6h burn rate intermediate recording rules. This should always be first
          sliRecordingRulesSet(burnRate),
          componentMetricsRuleSet(
            burnRate=burnRate,
            apdexRatio='gitlab_component_apdex:ratio_6h',
            apdexWeight='gitlab_component_apdex:weight:score_6h',
            requestRate='gitlab_component_ops:rate_6h',
            errorRate='gitlab_component_errors:rate_6h',
            aggregationLabels=COMPONENT_LEVEL_AGGREGATION_LABELS,
            substituteWeightWithRecordingRule=substituteWeightWithRecordingRule,
          ),
          extraRecordingRuleSet(burnRate),
        ]),

        nodeLevelRules: ruleSetIterator([
          // 6h node-level metrics (no apdex)
          componentMetricsRuleSet(
            burnRate=burnRate,
            requestRate='gitlab_component_node_ops:rate_6h',
            errorRate='gitlab_component_node_errors:rate_6h',
            aggregationLabels=NODE_LEVEL_AGGREGATION_LABELS,
          ),
        ]),
      },
    ],

    componentErrorRatios: ruleSetIterator(std.flatMap(
      function(suffix)
        [
          componentNodeErrorRatioRuleSet(suffix=suffix),
        ],
      std.filter(function(f) f != '', MULTI_BURN_RATE_SUFFIXES)  // Exclude 1m burns
    )),

    // Component mappings are static recording rules which help
    // determine whether a component is being monitored. This helps
    // prevent spurious alerts when a component is decommissioned.
    componentMapping: ruleSetIterator([
      componentMappingRuleSet(),
      componentNodeSLORuleSet(),
    ]),

    recordingRuleGroupsForService(serviceDefinition)::
      local prometheusConfig = self;
      [
        {
          name: 'Component-Level SLIs: %s - %s burn-rate' % [serviceDefinition.type, perBurnRateRecordingRules.burnRate],
          interval: perBurnRateRecordingRules.evaluationInterval,
          rules:
            perBurnRateRecordingRules.rules.generateRecordingRulesForService(serviceDefinition)
            +
            (
              if serviceDefinition.nodeLevelMonitoring then
                perBurnRateRecordingRules.nodeLevelRules.generateRecordingRulesForService(serviceDefinition)
              else []
            ),
        }
        for perBurnRateRecordingRules in self.perBurnRateRecordingRules
      ]
      +
      [{
        name: 'Component mapping: %s' % [serviceDefinition.type],
        interval: '1m',  // TODO: we could probably extend this out to 5m
        rules: prometheusConfig.componentMapping.generateRecordingRulesForService(serviceDefinition),
      }],
  },

  // Recording rules that get evaluated in Thanos
  thanos: {
    // The service SLO rules map SLOs to static recording rules,
    // for use in alerting, dashboards, etc
    serviceSLOs: ruleSetIterator([
      serviceSLORuleSet(),
    ]),

    // Component-level apdex ratios, aggregated at the Thanos level, to
    // prevent split-brain aggregation prometheus issues and
    // spurious alerts.
    aggregatedComponentApdexRatios: ruleSetIterator(std.flatMap(
      function(suffix)
        [
          aggregatedComponentApdexRatioRuleSet(suffix=suffix),
        ],
      MULTI_BURN_RATE_SUFFIXES
    )),

    // Component-level error ratios, aggregated at the Thanos level, to
    // prevent split-brain aggregation prometheus issues and
    // spurious alerts.
    aggregatedComponentErrorRatios: ruleSetIterator(std.flatMap(
      function(suffix)
        [
          aggregatedComponentErrorRatioRuleSet(suffix=suffix),
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


    // This rolls the component-level error ratios up to the service-level,
    // as a Thanos aggregation
    serviceApdexRatios: ruleSetIterator(std.flatMap(
      function(suffix)
        [
          // 1m burn rates use 5m weight scores
          // All other burn rates use the same burn rate as the ratio
          serviceApdexRatioRuleSet(suffix=suffix, weightScoreSuffix=(if suffix == '' then '_5m' else suffix)),
        ],
      MULTI_BURN_RATE_SUFFIXES
    ) + [
      // We are only recording node-level apdex scores for 1m and 5m burn rates for now
      serviceNodeApdexRatioRuleSet(suffix='', weightScoreSuffix='_5m'),
      serviceNodeApdexRatioRuleSet(suffix='_5m', weightScoreSuffix='_5m'),
    ]),

    // Component mappings are static recording rules which help
    // determine whether a component is being monitored. This helps
    // prevent spurious alerts when a component is decommissioned.
    serviceMapping: ruleSetIterator([
      serviceMappingRuleSet(),
    ]),

  },
}
