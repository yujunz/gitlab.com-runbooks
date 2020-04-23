local selectors = import 'lib/selectors.libsonnet';

local globalSelector = { monitor: 'global' };
local nonGlobalSelector = { monitor: { nre: 'global|' } };

local formatConfigForSelectorHash(selectorHash) =
  {
    globalSelector: selectors.serializeHash(selectorHash + globalSelector + { env: selectorHash.environment }),
    selector: selectors.serializeHash(selectorHash + nonGlobalSelector),
  };

{
  apdex:: {
    serviceApdexQuery(selectorHash, range)::
      |||
        min by (type) (min_over_time(gitlab_service_apdex:ratio{%(globalSelector)s}[%(range)s]))
        or
        min by (type) (gitlab_service_apdex:ratio{%(selector)s})
      ||| % formatConfigForSelectorHash(selectorHash) { range: range },

    serviceApdexDegradationSLOQuery(environment, type, stage)::
      |||
        avg(slo:min:gitlab_service_apdex:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s"}) or avg(slo:min:gitlab_service_apdex:ratio{type="%(type)s"})
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
      },

    serviceApdexOutageSLOQuery(environment, type, stage)::
      |||
        2 * (avg(slo:min:gitlab_service_apdex:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s"}) or avg(slo:min:gitlab_service_apdex:ratio{type="%(type)s"})) - 1
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
      },

    serviceApdexQueryWithOffset(selectorHash, offset)::
      |||
        min by (type) (gitlab_service_apdex:ratio{%(globalSelector)s} offset %(offset)s)
        or
        min by (type) (gitlab_service_apdex:ratio{%(selector)s} offset %(offset)s)
      ||| % formatConfigForSelectorHash(selectorHash) { offset: offset },

    componentApdexQuery(selectorHash, range)::
      |||
        sum by (component, type) (
          (avg_over_time(gitlab_component_apdex:ratio{%(selector)s}[%(range)s]) >= 0)
          *
          (avg_over_time(gitlab_component_apdex:weight:score{%(selector)s}[10m]) >= 0)
        )
        /
        sum by (component, type) (
          (avg_over_time(gitlab_component_apdex:weight:score{%(selector)s}[10m]) >= 0)
        )
      ||| % formatConfigForSelectorHash(selectorHash) { range: range },
  },

  opsRate:: {
    serviceOpsRateQuery(selectorHash, range)::
      |||
        avg by (type) (avg_over_time(gitlab_service_ops:rate{%(globalSelector)s}[%(range)s]))
        or
        sum by (type) (gitlab_service_ops:rate{%(selector)s})
      ||| % formatConfigForSelectorHash(selectorHash) { range: range },

    serviceOpsRateQueryWithOffset(selectorHash, offset)::
      |||
        avg by (type) (gitlab_service_ops:rate{%(globalSelector)s} offset %(offset)s)
        or
        sum by (type) (gitlab_service_ops:rate{%(selector)s} offset %(offset)s)
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
  },

  errorRate:: {
    serviceErrorRateQuery(selectorHash, range, clampMax=1.0)::
      |||
        clamp_max(
          max by (type) (max_over_time(gitlab_service_errors:ratio{%(globalSelector)s}[$__interval]))
          or
          sum by (type) (gitlab_service_errors:ratio{%(selector)s}),
          %(clampMax)g
        )
      ||| % formatConfigForSelectorHash(selectorHash) { range: range, clampMax: clampMax },

    serviceErrorRateDegradationSLOQuery(environment, type, stage)::
      |||
        avg(slo:max:gitlab_service_errors:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s"}) or avg(slo:max:gitlab_service_errors:ratio{type="%(type)s"})
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
      },

    serviceErrorRateOutageSLOQuery(environment, type, stage)::
      |||
        2 * (avg(slo:max:gitlab_service_errors:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s"}) or avg(slo:max:gitlab_service_errors:ratio{type="%(type)s"}))
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
      },

    serviceErrorRateQueryWithOffset(selectorHash, offset)::
      |||
        max by (type) (gitlab_service_errors:ratio{%(globalSelector)s} offset %(offset)s)
        or
        sum by (type) (gitlab_service_errors:ratio{%(selector)s} offset %(offset)s)
      ||| % formatConfigForSelectorHash(selectorHash) { offset: offset },
  },


}
