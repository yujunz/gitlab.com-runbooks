local combined = import './combined.libsonnet';
local customApdex = import './custom_apdex.libsonnet';
local customRateQuery = import './custom_rate_query.libsonnet';
local histogramApdex = import './histogram_apdex.libsonnet';
local rateMetric = import './rate.libsonnet';

{
  histogramApdex:: histogramApdex.histogramApdex,
  combined:: combined.combined,
  customApdex:: customApdex.customApdex,
  rateMetric:: rateMetric.rateMetric,
  customRateQuery:: customRateQuery.customRateQuery,
}
