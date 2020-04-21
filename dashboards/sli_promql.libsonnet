{
  apdex:: {
    serviceApdexQuery(environment, type, stage, range)::
      |||
        min by (type) (min_over_time(gitlab_service_apdex:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor="", env="%(environment)s"}[$__interval]))
        or
        min by (type) (gitlab_service_apdex:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor!=""})
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
        range: range,
      },

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

    serviceApdexQueryWithOffset(environment, type, stage, offset)::
      |||
        min by (type) (gitlab_service_apdex:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor="", env="%(environment)s"} offset %(offset)s)
        or
        min by (type) (gitlab_service_apdex:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor!=""} offset %(offset)s)
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
        offset: offset,
      },
  },

  opsRate:: {
    serviceOpsRateQuery(environment, type, stage, range)::
      |||
        avg by (type) (avg_over_time(gitlab_service_ops:rate{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor="", env="%(environment)s"}[%(range)s]))
        or
        sum by (type) (gitlab_service_ops:rate{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor!=""})
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
        range: range,
      },

    serviceOpsRateQueryWithOffset(environment, type, stage, offset)::
      |||
        avg by (type) (gitlab_service_ops:rate{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor="", env="%(environment)s"} offset %(offset)s)
        or
        sum by (type) (gitlab_service_ops:rate{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor!=""} offset %(offset)s)
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
        offset: offset,
      },

    serviceOpsRatePrediction(environment, type, stage, sigma)::
      |||
        clamp_min(
          avg by (type) (
            gitlab_service_ops:rate:prediction{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor=""}
            + (%(sigma)g) *
            gitlab_service_ops:rate:stddev_over_time_1w{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor=""}
          )
          or
          (
              sum by (type) (gitlab_service_ops:rate:prediction{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor!=""})
              + (%(sigma)g) *
              sum by (type) (gitlab_service_ops:rate:stddev_over_time_1w{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor!=""})
          ),
          0
        )
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
        sigma: sigma,
      },
  },

  errorRate:: {
    serviceErrorRateQuery(environment, type, stage, range)::
      |||
        max by (type) (max_over_time(gitlab_service_errors:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor="", env="%(environment)s"}[$__interval]))
        or
        sum by (type) (gitlab_service_errors:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor!=""})
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
        range: range,
      },

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

    serviceErrorRateQueryWithOffset(environment, type, stage, offset)::
      |||
        max by (type) (gitlab_service_errors:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor="", env="%(environment)s"} offset %(offset)s)
        or
        sum by (type) (gitlab_service_errors:ratio{environment="%(environment)s", type="%(type)s", stage="%(stage)s", monitor!=""} offset %(offset)s)
      ||| % {
        environment: environment,
        type: type,
        stage: stage,
        offset: offset,
      },


  },


}
