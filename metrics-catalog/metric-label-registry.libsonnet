local selectors = import 'promql/selectors.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';

// Merge two hashes of the form { key: set },
local merge(h1, h2) =
  local folderFunc = function(memo, k)
    if std.objectHas(memo, k) then
      memo {
        [k]: std.setUnion(memo[k], h2[k]),
      }
    else
      memo {
        [k]: h2[k],
      };

  std.foldl(folderFunc, std.objectFields(h2), h1);

local mergeFoldl(fn, array) =
  std.foldl(function(memo, item) merge(memo, fn(item)), array, {});

local applySignificantLabels(metricNamesAndLabels, significantLabels) =
  std.foldl(
    function(memo, metricName) memo {
      [metricName]: std.setUnion(significantLabels, metricNamesAndLabels[metricName]),
    },
    std.objectFields(metricNamesAndLabels),
    {}
  );

local collectMetricsAndLabelsForKeyMetric(component, keyMetricAttribute, significantLabels) =
  // Check the component supports the key metric
  if std.objectHas(component, keyMetricAttribute) then
    local keyMetric = component[keyMetricAttribute];

    // Does the key metric support reflection?
    if std.objectHasAll(keyMetric, 'supportsReflection') then
      local reflection = component[keyMetricAttribute].supportsReflection();
      applySignificantLabels(reflection.getMetricNamesAndLabels(), significantLabels)
    else
      {}
  else
    {};

// Return a hash of { metric: set(labels) } for a component
local collectMetricsAndLabelsForComponent(component) =
  local significantLabels = std.set(component.significantLabels);

  mergeFoldl(function(keyMetricAttribute)
               collectMetricsAndLabelsForKeyMetric(component, keyMetricAttribute, significantLabels),
             ['apdex', 'requestRate', 'errorRate']);

// Return a hash of { metric: set(labels) } for a service
local collectMetricsAndLabelsForService(service) =
  local foldFunc = function(memo, componentName)
    local component = service.components[componentName];
    merge(memo, collectMetricsAndLabelsForComponent(component));
  std.foldl(foldFunc, std.objectFields(service.components), {});

// Return a hash of metrics and dimensions, for use in composing recording rules
local collectMetricsAndLabels() =
  local foldFunc = function(memo, service)
    merge(memo, collectMetricsAndLabelsForService(service));
  std.foldl(foldFunc, metricsCatalog.services, {});

local labelsForMetricNames = collectMetricsAndLabels();

{
  // Returns a set of label names used for the given metric name
  lookupLabelsForMetricName(metricName)::
    if std.objectHas(labelsForMetricNames, metricName) then
      labelsForMetricNames[metricName]
    else
      [],
}
