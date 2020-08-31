local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local singleHTTPComponent(stage, selector, definition) =

  local backends = definition.backends;
  local toolingLinks = definition.toolingLinks;
  local baseSelector = selector {
    backend: if std.length(backends) == 1 then backends[0] else { re: std.join('|', backends) },
  };

  metricsCatalog.componentDefinition({
    staticLabels: {
      stage: stage,
    },

    requestRate: rateMetric(
      counter='haproxy_backend_http_responses_total',
      selector=baseSelector
    ),

    errorRate: rateMetric(
      counter='haproxy_backend_http_responses_total',
      selector=baseSelector { code: '5xx' }
    ),

    significantLabels: [],

    toolingLinks: toolingLinks,
  });

// This is for opaque HTTPS-to-HTTPS or SSH proxying, specifically for pages/git etc
local singleL4Component(stage, selector, definition) =
  local backends = definition.backends;
  local toolingLinks = definition.toolingLinks;

  local baseSelector = selector {
    backend: if std.length(backends) == 1 then backends[0] else { re: std.join('|', backends) },
  };

  metricsCatalog.componentDefinition({
    staticLabels: {
      stage: stage,
    },

    requestRate: rateMetric(
      counter='haproxy_server_sessions_total',
      selector=baseSelector
    ),

    errorRate: rateMetric(
      counter='haproxy_server_connection_errors_total',
      selector=baseSelector
    ),

    significantLabels: [],

    toolingLinks: toolingLinks,
  });

local combinedBackendCurry(generator) =
  function(stageMappings, selector)
    metricsCatalog.combinedComponentDefinition(
      components=[
        generator(stage=stage, selector=selector, definition=stageMappings[stage])
        for stage in std.objectFields(stageMappings)
      ],
      // Don't double-up RPS by including loadbalancer again
      aggregateRequestRate=false,
    );


{
  // This returns a combined component mapping, one for each stage (main, cny etc)
  // The mapping is as follows:
  // stageMappings={
  //   main: { backends: ["backend_1", "backend_2"], toolingLinks: [...] },
  //   cny: { backends: ["backend_3", "backend_4"], toolingLinks: [...] },
  // },
  haproxyHTTPLoadBalancer:: combinedBackendCurry(singleHTTPComponent),

  // This returns a combined component mapping, one for each stage (main, cny etc)
  // The mapping is as follows:
  // stageMappings={
  //   main: { backends: ["backend_1", "backend_2"], toolingLinks: [...] },
  //   cny: { backends: ["backend_3", "backend_4"], toolingLinks: [...] },
  // },
  haproxyL4LoadBalancer:: combinedBackendCurry(singleL4Component),
}
