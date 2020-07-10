local combined = import './combined.libsonnet';
local customApdex = import './custom_apdex.libsonnet';
local customRateQuery = import './custom_rate_query.libsonnet';
local histogramApdex = import './histogram_apdex.libsonnet';
local rateMetrics = import './rate.libsonnet';
local serviceDefinition = import './service-definition.libsonnet';

{
  // Metric definitions
  histogramApdex:: histogramApdex.histogramApdex,
  combined:: combined.combined,
  customApdex:: customApdex.customApdex,
  rateMetric:: rateMetrics.rateMetric,
  derivMetric:: rateMetrics.derivMetric,
  customRateQuery:: customRateQuery.customRateQuery,

  // Service definition
  serviceDefinition:: serviceDefinition.serviceDefinition,
}
