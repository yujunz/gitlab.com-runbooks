local dependencies = import './lib/dependencies.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local row = grafana.row;
local layout = import 'layout.libsonnet';
local sliPromQL = import 'sli_promql.libsonnet';

local MERMAID_DIAGRAM_TEMPLATE =
  |||
    graph TD
      %(subgraphs)s

      %(dependencyList)s
  |||;

local generateMermaidSubgraphsForTier(tier, services) =
  |||
    subgraph %(tier)s
      %(serviceList)s
    end
  ||| % {
    tier: tier,
    serviceList: std.join('\n  ', services),
  };

local generateMermaidSubgraphs(services) =
  local servicesByTier = std.foldl(function(memo, service) std.mergePatch(memo, { [service.tier]: { [service.type]: true } }), services, {});
  local tiers = std.map(function(tier) generateMermaidSubgraphsForTier(tier, std.objectFields(servicesByTier[tier])), std.objectFields(servicesByTier));
  std.join('\n', tiers);

local generateMermaidDependencyForService(service) =
  if std.objectHas(service, 'serviceDependencies') then
    std.map(function(dep) '%s --> %s' % [service.type, dep], std.objectFields(service.serviceDependencies))
  else
    [];

local generateMermaidDependencyList(services) =
  local lines = std.flattenArrays(std.map(generateMermaidDependencyForService, services));
  std.join('\n', lines);

local generateMermaidDiagram(services) =
  MERMAID_DIAGRAM_TEMPLATE % {
    subgraphs: generateMermaidSubgraphs(services),
    dependencyList: generateMermaidDependencyList(services),
  };

local systemDiagram(title, target, colors, thresholds, graphId, services) = {
  datasource: '$PROMETHEUS_DS',
  colors: colors,
  composites: [],
  content: generateMermaidDiagram(services),
  decimals: 3,
  format: 'percentunit',
  graphId: graphId,
  gridPos: {
    h: 21,
    w: 24,
    x: 0,
    y: 21,
  },
  init: {
    arrowMarkerAbsolute: true,
    cloneCssStyles: true,
    flowchart: {
      htmlLabels: true,
      useMaxWidth: true,
    },
    gantt: {
      barGap: 4,
      barHeight: 20,
      fontFamily: '"Open-Sans", "sans-serif"',
      fontSize: 11,
      gridLineStartPadding: 35,
      leftPadding: 75,
      numberSectionStyles: 3,
      titleTopMargin: 25,
      topPadding: 50,
    },
    logLevel: 3,
    sequenceDiagram: {
      actorMargin: 50,
      bottomMarginAdj: 1,
      boxMargin: 10,
      boxTextMargin: 5,
      diagramMarginX: 50,
      diagramMarginY: 10,
      height: 65,
      messageMargin: 35,
      mirrorActors: true,
      noteMargin: 10,
      useMaxWidth: true,
      width: 150,
    },
    startOnLoad: false,
  },
  interval: '',
  legend: {
    avg: true,
    current: true,
    gradient: {
      enabled: true,
      show: true,
    },
    max: true,
    min: true,
    show: false,
    total: true,
  },
  mappingType: 1,
  mappingTypes: [],
  maxDataPoints: 100,
  maxWidth: false,
  mermaidServiceUrl: '',
  metricCharacterReplacements: [],
  moddedSeriesVal: 0,
  mode: 'content',
  nullPointMode: 'connected',
  options: {},
  seriesOverrides: [],
  style: '',
  targets: [target],
  thresholds: thresholds,
  title: title,
  type: 'jdbranham-diagram-panel',
  valueMaps: [],
  valueName: 'current',
  valueOptions: [
    'avg',
    'min',
    'max',
    'total',
    'current',
  ],
};

local errorDiagram(services) =
  systemDiagram(
    title='System Diagram (Keyed by Error Rates)',
    colors=[
      'rgba(50, 172, 45, 0.97)',
      'rgba(237, 129, 40, 0.89)',
      'rgba(245, 54, 54, 0.9)',
    ],
    services=services,
    graphId='diagram_errors',
    thresholds='0,0.001',
    target=promQuery.target(
      sliPromQL.errorRate.serviceErrorRateQuery({ environment: '$environment', stage: '$stage' }, range='$__range'),
      legendFormat='{{ type }}',
      instant=true
    )
  );

local apdexDiagram(services) =
  systemDiagram(
    title='System Diagram (Keyed by Apdex/Latency Scores)',
    colors=[
      'rgba(245, 54, 54, 0.9)',
      '#FF9830',
      '#73BF69',
    ],
    services=services,
    graphId='diagram_apdex',
    thresholds='0.99,0.995,0.999',
    target=promQuery.target(
      sliPromQL.apdex.serviceApdexQuery({ environment: '$environment', stage: '$stage' }, range='$__range'),
      legendFormat='{{ type }}',
      instant=true
    )
  );

local getServicesFor(serviceName) =
  local serviceNames = dependencies.listDownstreamServices(serviceName);
  [
    metricsCatalog.getService(serviceName)
    for serviceName in serviceNames
  ];

{
  systemDiagramRowForService(serviceName)::
    local services = getServicesFor(serviceName);

    row.new(title='🗺️ System Diagrams', collapse=true)
    .addPanels(layout.grid([
      errorDiagram(services),
      apdexDiagram(services),
    ], cols=2, rowHeight=10)),
}
