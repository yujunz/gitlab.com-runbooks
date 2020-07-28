local multiburnFactors = import 'mwmbr/multiburn_factors.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local globalSelector = { monitor: 'global' };
local nonGlobalSelector = { monitor: { nre: 'global|' } };

local formatConfigForSelectorHash(selectorHash) =
  {
    globalSelector: selectors.serializeHash(selectorHash + globalSelector + { env: selectorHash.environment }),
    selector: selectors.serializeHash(selectorHash + nonGlobalSelector),
  };

{
  apdex:: {
    serviceApdexQuery(selectorHash, range, worstCase=true)::
      if worstCase then
        /* Min apdex case */
        |||
          min by (type) (min_over_time(gitlab_service_apdex:ratio_5m{%(globalSelector)s}[%(range)s]))
          or
          min by (type) (min_over_time(gitlab_service_apdex:ratio{%(globalSelector)s}[%(range)s]))
        ||| % formatConfigForSelectorHash(selectorHash) { range: range }
      else
        /* Avg apdex case */
        |||
          avg by (type) (avg_over_time(gitlab_service_apdex:ratio_5m{%(globalSelector)s}[%(range)s]))
          or
          avg by (type) (avg_over_time(gitlab_service_apdex:ratio{%(globalSelector)s}[%(range)s]))
        ||| % formatConfigForSelectorHash(selectorHash) { range: range },

    // TODO: remove deprecated slo:max:gitlab_service_errors:ratio value after 2021-01-01
    serviceApdexDegradationSLOQuery(environmentSelectorHash, type, stage)::
      |||
        (1 - %(burnrate_6h)g * (1 - avg(slo:min:events:gitlab_service_apdex:ratio{type="%(type)s"})))
        or
        avg(slo:min:gitlab_service_apdex:ratio{type="%(type)s"})
      ||| % {
        type: type,
        burnrate_6h: multiburnFactors.burnrate_6h,
      },

    // TODO: remove deprecated slo:max:gitlab_service_errors:ratio value after 2021-01-01
    serviceApdexOutageSLOQuery(environmentSelectorHash, type, stage)::
      |||
        (1 - %(burnrate_1h)g * (1 - avg(slo:min:events:gitlab_service_apdex:ratio{type="%(type)s"})))
        or
        (2 * avg(slo:min:gitlab_service_apdex:ratio{type="%(type)s"}) - 1)
      ||| % {
        type: type,
        burnrate_1h: multiburnFactors.burnrate_1h,
      },

    serviceApdexQueryWithOffset(selectorHash, offset)::
      |||
        min by (type) (gitlab_service_apdex:ratio_5m{%(globalSelector)s} offset %(offset)s)
        or
        min by (type) (gitlab_service_apdex:ratio{%(globalSelector)s} offset %(offset)s)
      ||| % formatConfigForSelectorHash(selectorHash) { offset: offset },

    // Fallback to non-aggregated, non-global query for backwards
    // compatability, remove after 1 Jan 2021
    componentApdexQuery(selectorHash, range)::
      |||
        avg_over_time(gitlab_component_apdex:ratio_5m{%(globalSelector)s}[%(range)s])
        or on(component, type)
        (
          sum by (component, type) (
            (avg_over_time(gitlab_component_apdex:ratio{%(selector)s}[%(range)s]) >= 0)
            *
            (avg_over_time(gitlab_component_apdex:weight:score{%(selector)s}[10m]) >= 0)
          )
          /
          sum by (component, type) (
            (avg_over_time(gitlab_component_apdex:weight:score{%(selector)s}[10m]) >= 0)
          )
        )
      ||| % formatConfigForSelectorHash(selectorHash) { range: range },

    componentNodeApdexQuery(selectorHash, range)::
      |||
        gitlab_component_node_apdex:ratio_5m{%(selector)s}
      ||| % formatConfigForSelectorHash(selectorHash) { range: range },
  },

  opsRate:: {
    serviceOpsRateQuery(selectorHash, range)::
      |||
        avg by (type)
        (avg_over_time(gitlab_service_ops:rate_5m{%(globalSelector)s}[%(range)s]) or avg_over_time(gitlab_service_ops:rate{%(globalSelector)s}[%(range)s]))
        or
        sum by (type) (gitlab_service_ops:rate_5m{%(selector)s} or gitlab_service_ops:rate{%(selector)s})
      ||| % formatConfigForSelectorHash(selectorHash) { range: range },

    serviceOpsRateQueryWithOffset(selectorHash, offset)::
      |||
        avg by (type) (
          gitlab_service_ops:rate_5m{%(globalSelector)s} offset %(offset)s
          or
          gitlab_service_ops:rate{%(globalSelector)s} offset %(offset)s
        )
        or
        sum by (type) (
          gitlab_service_ops:rate_5m{%(selector)s} offset %(offset)s
          or
          gitlab_service_ops:rate{%(selector)s} offset %(offset)s
        )
      ||| % formatConfigForSelectorHash(selectorHash) { offset: offset },

    serviceOpsRatePrediction(selectorHash, sigma)::
      |||
        clamp_min(
          avg by (type) (
            gitlab_service_ops:rate:prediction{%(globalSelector)s}
            + (%(sigma)g) *
            gitlab_service_ops:rate:stddev_over_time_1w{%(globalSelector)s}
          )
          or
          (
              sum by (type) (gitlab_service_ops:rate:prediction{%(selector)s})
              + (%(sigma)g) *
              sum by (type) (gitlab_service_ops:rate:stddev_over_time_1w{%(selector)s})
          ),
          0
        )
      ||| % formatConfigForSelectorHash(selectorHash) { sigma: sigma },

    componentOpsRateQuery(selectorHash, range)::
      |||
        sum(
          avg_over_time(
            gitlab_component_ops:rate_5m{%(selector)s}[%(range)s]
          )
        ) by (component)
      ||| % formatConfigForSelectorHash(selectorHash) { range: range },

    componentNodeOpsRateQuery(selectorHash, range)::
      |||
        gitlab_component_node_ops:rate_5m{%(selector)s}
      ||| % formatConfigForSelectorHash(selectorHash) { range: range },
  },

  errorRate:: {
    serviceErrorRateQuery(selectorHash, range, clampMax=1.0, worstCase=true)::
      if worstCase then
        /* Max case */
        |||
          clamp_max(
            max by (type) (max_over_time(gitlab_service_errors:ratio_5m{%(globalSelector)s}[$__interval]))
            or
            sum by (type) (gitlab_service_errors:ratio_5m{%(selector)s}),
            %(clampMax)g
          )
        ||| % formatConfigForSelectorHash(selectorHash) { range: range, clampMax: clampMax }
      else
        /* Avg case */
        |||
          clamp_max(
            avg by (type) (avg_over_time(gitlab_service_errors:ratio_5m{%(globalSelector)s}[$__interval])),
            %(clampMax)g
          )
        ||| % formatConfigForSelectorHash(selectorHash) { range: range, clampMax: clampMax },

    // TODO: remove deprecated slo:max:gitlab_service_errors:ratio value after 2021-01-01
    serviceErrorRateDegradationSLOQuery(environmentSelectorHash, type, stage)::
      |||
        (%(burnrate_6h)g * avg(slo:max:events:gitlab_service_errors:ratio{type="%(type)s"}))
        or
        avg(slo:max:gitlab_service_errors:ratio{type="%(type)s"})
      ||| % {
        type: type,
        burnrate_6h: multiburnFactors.burnrate_6h,
      },

    // TODO: remove deprecated slo:max:gitlab_service_errors:ratio value after 2021-01-01
    serviceErrorRateOutageSLOQuery(environmentSelectorHash, type, stage)::
      |||
        (%(burnrate_1h)g * avg(slo:max:events:gitlab_service_errors:ratio{type="%(type)s"}))
        or
        (2 * avg(slo:max:gitlab_service_errors:ratio{type="%(type)s"}))
      ||| % {
        type: type,
        burnrate_1h: multiburnFactors.burnrate_1h,
      },

    serviceErrorRateQueryWithOffset(selectorHash, offset)::
      |||
        max by (type) (gitlab_service_errors:ratio_5m{%(globalSelector)s} offset %(offset)s)
        or
        sum by (type) (gitlab_service_errors:ratio_5m{%(selector)s} offset %(offset)s)
      ||| % formatConfigForSelectorHash(selectorHash) { offset: offset },

    componentErrorRateQuery(selectorHash)::
      |||
        sum(
          gitlab_component_errors:rate_5m{%(selector)s}
        ) by (component)
        /
        sum(
          gitlab_component_ops:rate_5m{%(selector)s}
        ) by (component)
      ||| % formatConfigForSelectorHash(selectorHash) {},

    componentNodeErrorRateQuery(selectorHash)::
      |||
        gitlab_component_node_errors:rate_5m{%(selector)s}
      ||| % formatConfigForSelectorHash(selectorHash) {},
  },


}
