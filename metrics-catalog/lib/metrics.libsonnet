local customQuery = import './custom_query.libsonnet';
local histogramApdex = import './histogram_apdex.libsonnet';
local rateMetric = import './rate.libsonnet';

{
  histogramApdex:: histogramApdex.histogramApdex,
  rateMetric:: rateMetric.rateMetric,
  customQuery:: customQuery.customQuery,
}
