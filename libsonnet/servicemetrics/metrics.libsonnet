{
  // Metric definitions
  histogramApdex:: (import './histogram_apdex.libsonnet').histogramApdex,
  combined:: (import './combined.libsonnet').combined,
  customApdex:: (import './custom_apdex.libsonnet').customApdex,
  rateMetric:: (import './rate.libsonnet').rateMetric,
  derivMetric:: (import './rate.libsonnet').derivMetric,
  customRateQuery:: (import './custom_rate_query.libsonnet').customRateQuery,

  // Service definition
  serviceDefinition:: (import './service-definition.libsonnet').serviceDefinition,

  // Resource Saturation & Utilization definition
  resourceSaturationPoint: (import './resource-saturation-point.libsonnet').resourceSaturationPoint,
}
