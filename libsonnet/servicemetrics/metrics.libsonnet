{
  // Metric definitions
  histogramApdex:: (import './histogram_apdex.libsonnet').histogramApdex,
  combined:: (import './combined.libsonnet').combined,
  customApdex:: (import './custom_apdex.libsonnet').customApdex,
  rateMetric:: (import './rate.libsonnet').rateMetric,
  derivMetric:: (import './rate.libsonnet').derivMetric,
  customRateQuery:: (import './custom_rate_query.libsonnet').customRateQuery,
  gaugeMetric:: (import './gauge_metric.libsonnet').gaugeMetric,

  // Service definition
  serviceDefinition:: (import './service_definition.libsonnet').serviceDefinition,
  componentDefinition:: (import './component_definition.libsonnet').componentDefinition,

  combinedComponentDefinition:: (import './combined_component_definition.libsonnet').combinedComponentDefinition,

  // Resource Saturation & Utilization definition
  resourceSaturationPoint: (import './resource_saturation_point.libsonnet').resourceSaturationPoint,
}
