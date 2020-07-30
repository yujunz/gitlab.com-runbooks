local multiburnFactors = import 'mwmbr/multiburn_factors.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';

local descriptionMappings = [
  /* 0 */
  {
    name: 'Healthy',
    color: 'black',
  },
  /* 1 */
  {
    name: 'Warning 🔥',
    color: 'orange',
  },
  /* 2 */
  {
    name: 'Warning 🔥',
    color: 'orange',
  },
  /* 3 */
  {
    name: 'Degraded 🔥',
    color: 'red',
  },
  /* 4 */
  {
    name: 'Warning 🥵',
    color: 'orange',
  },
  /* 5 */
  {
    name: 'Warning 🔥🥵',
    color: 'orange',
  },
  /* 6 */
  {
    name: 'Warning 🔥🥵',
    color: 'orange',
  },
  /* 7 */
  {
    name: 'Degraded 🔥🥵',
    color: 'red',
  },
  /* 8 */
  {
    name: 'Warning 🥵',
    color: 'orange',
  },
  /* 9 */
  {
    name: 'Warning 🔥🥵',
    color: 'orange',
  },
  /* 10 */
  {
    name: 'Warning 🔥🥵',
    color: 'orange',
  },
  /* 11 */
  {
    name: 'Degraded 🔥🥵',
    color: 'red',
  },
  /* 12 */
  {
    name: 'Degraded 🥵',
    color: 'red',
  },
  /* 13 */
  {
    name: 'Degraded 🔥🥵',
    color: 'red',
  },
  /* 14 */
  {
    name: 'Degraded 🔥🥵',
    color: 'red',
  },
  /* 15 */
  {
    name: 'Degraded 🔥🥵',
    color: 'red',
  },
];

local apdexStatusQuery(selectorHash, type, prefix) =
  |||
    sum(
      label_replace(
        vector(0) and on() (%(prefix)s:ratio_1h{%(selector)s}),
        "period", "na", "", ""
      )
      or
      label_replace(
        vector(1) and on () (%(prefix)s:ratio_5m{%(selector)s} < on(tier, type) group_left() (1 - (%(burnrate_1h)g * (1 - slo:min:events:gitlab_service_apdex:ratio{%(slaSelector)s})))),
        "period", "5m", "", ""
      )
      or
      label_replace(
        vector(2) and on () (%(prefix)s:ratio_1h{%(selector)s} < on(tier, type) group_left() (1 - (%(burnrate_1h)g * (1 - slo:min:events:gitlab_service_apdex:ratio{%(slaSelector)s})))),
        "period", "1h", "", ""
      )
      or
      label_replace(
        vector(4) and on () (%(prefix)s:ratio_30m{%(selector)s} < on(tier, type) group_left() (1 - (%(burnrate_6h)g * (1 - slo:min:events:gitlab_service_apdex:ratio{%(slaSelector)s})))),
        "period", "30m", "", ""
      )
      or
      label_replace(
        vector(8) and on () (%(prefix)s:ratio_6h{%(selector)s} < on(tier, type) group_left() (1 - (%(burnrate_6h)g * (1 - slo:min:events:gitlab_service_apdex:ratio{%(slaSelector)s})))),
        "period", "6h", "", ""
      )
    )
  ||| % ({
           selector: selectors.serializeHash(selectorHash),
           slaSelector: selectors.serializeHash({ monitor: 'global', type: type }),
           prefix: prefix,
         } + multiburnFactors);

local errorRateStatusQuery(selectorHash, type, prefix) =
  |||
    sum (
      label_replace(
        vector(0) and on() (%(prefix)s:ratio_1h{%(selector)s}),
        "period", "na", "", ""
      )
      or
      label_replace(
        vector(1) and on() (%(prefix)s:ratio_5m{%(selector)s} > on(tier, type) group_left() (%(burnrate_1h)g * slo:max:events:gitlab_service_errors:ratio{%(slaSelector)s})),
        "period", "5m", "", ""
      )
      or
      label_replace(
        vector(2) and on() (%(prefix)s:ratio_1h{%(selector)s} > on(tier, type) group_left() (%(burnrate_1h)g * slo:max:events:gitlab_service_errors:ratio{%(slaSelector)s})),
        "period", "1h", "", ""
      )
      or
      label_replace(
        vector(4) and on() (%(prefix)s:ratio_30m{%(selector)s} > on(tier, type) group_left() (%(burnrate_6h)g * slo:max:events:gitlab_service_errors:ratio{%(slaSelector)s})),
        "period", "30m", "", ""
      )
      or
      label_replace(
        vector(8) and on() (%(prefix)s:ratio_6h{%(selector)s} > on(tier, type) group_left() (%(burnrate_6h)g * slo:max:events:gitlab_service_errors:ratio{%(slaSelector)s})),
        "period", "6h", "", ""
      )
    )
  ||| % ({
           selector: selectors.serializeHash(selectorHash),
           slaSelector: selectors.serializeHash({ monitor: 'global', type: type }),
           prefix: prefix,
         } + multiburnFactors);


local statusDescriptionPanel(legendFormat, query) =
  {
    type: 'stat',
    title: '',
    targets: [promQuery.target(query, legendFormat=legendFormat, instant=true)],
    pluginVersion: '6.6.1',
    links: [],
    options: {
      graphMode: 'none',
      colorMode: 'background',
      justifyMode: 'auto',
      fieldOptions: {
        values: false,
        calcs: [
          'lastNotNull',
        ],
        defaults: {
          thresholds: {
            mode: 'absolute',
            steps: std.mapWithIndex(
              function(index, v)
                {
                  value: index,
                  color: v.color,
                },
              descriptionMappings
            ),
          },
          mappings: std.mapWithIndex(
            function(index, v)
              {
                from: '' + index,
                id: index,
                op: '=',
                text: v.name,
                to: '' + index,
                type: 2,
                value: '' + index,
              }, descriptionMappings
          ),
          unit: 'none',
          nullValueMode: 'connected',
          title: 'Status',
          links: [],
        },
        overrides: [],
      },
      orientation: 'vertical',
    },
  };

{
  componentApdexStatusDescriptionPanel(selectorHash)::
    local query = apdexStatusQuery(selectorHash, selectorHash.type, 'gitlab_component_apdex');
    statusDescriptionPanel(legendFormat=selectorHash.component + ' | Latency/Apdex', query=query),

  serviceApdexStatusDescriptionPanel(selectorHash)::
    local query = apdexStatusQuery(selectorHash, selectorHash.type, 'gitlab_service_apdex');
    statusDescriptionPanel(legendFormat=selectorHash.type + ' | Latency/Apdex', query=query),

  componentErrorRateStatusDescriptionPanel(selectorHash)::
    local query = errorRateStatusQuery(selectorHash, selectorHash.type, 'gitlab_component_errors');
    statusDescriptionPanel(legendFormat=selectorHash.component + ' | Errors', query=query),

  serviceErrorStatusDescriptionPanel(selectorHash)::
    local query = errorRateStatusQuery(selectorHash, selectorHash.type, 'gitlab_service_errors');
    statusDescriptionPanel(legendFormat=selectorHash.type + ' | Errors', query=query),

  componentNodeApdexStatusDescriptionPanel(selectorHash)::
    local query = apdexStatusQuery(selectorHash, selectorHash.type, 'gitlab_component_node_apdex');
    statusDescriptionPanel(legendFormat=selectorHash.component + '/' + selectorHash.fqdn + ' | Latency/Apdex', query=query),

  componentNodeErrorRateStatusDescriptionPanel(selectorHash)::
    local query = errorRateStatusQuery(selectorHash, selectorHash.type, 'gitlab_component_node_errors');
    statusDescriptionPanel(legendFormat=selectorHash.component + '/' + selectorHash.fqdn + ' | Errors', query=query),

}
