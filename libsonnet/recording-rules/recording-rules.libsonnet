
{
  sliRecordingRulesSet: (import 'sli-recording-rule-set.libsonnet').sliRecordingRulesSet,
  componentMetricsRuleSet: (import 'component-metrics-rule-set.libsonnet').componentMetricsRuleSet,
  componentMappingRuleSet: (import 'component-mapping-rule-set.libsonnet').componentMappingRuleSet,
  componentNodeErrorRatioRuleSet: (import 'component-node-error-ratio-rule-set.libsonnet').componentNodeErrorRatioRuleSet,
  componentNodeSLORuleSet: (import 'component-node-slo-rule-set.libsonnet').componentNodeSLORuleSet,
  serviceMappingRuleSet: (import 'service-mapping-rule-set.libsonnet').serviceMappingRuleSet,
  serviceSLORuleSet: (import 'service-slo-rule-set.libsonnet').serviceSLORuleSet,
  aggregatedComponentErrorRatioRuleSet: (import 'aggregated-component-error-ratio-rule-set.libsonnet').aggregatedComponentErrorRatioRuleSet,
  aggregatedComponentApdexRatioRuleSet: (import 'aggregated-component-apdex-ratio-rule-set.libsonnet').aggregatedComponentApdexRatioRuleSet,
  serviceErrorRatioRuleSet: (import 'service-error-ratio-rule-set.libsonnet').serviceErrorRatioRuleSet,
  serviceNodeErrorRatioRuleSet: (import 'service-node-error-ratio-rule-set.libsonnet').serviceNodeErrorRatioRuleSet,
  serviceApdexRatioRuleSet: (import 'service-apdex-ratio-rule-set.libsonnet').serviceApdexRatioRuleSet,
  serviceNodeApdexRatioRuleSet: (import 'service-node-apdex-ratio-rule-set.libsonnet').serviceNodeApdexRatioRuleSet,
  extraRecordingRuleSet: (import 'extra-recording-rule-set.libsonnet').extraRecordingRuleSet,
}
