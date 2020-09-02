local expression = import './expression.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testErrorBurnWithoutMinimumRate: {
    actual: expression.multiburnRateErrorExpression(
      metric1h='error:rate_1h',
      metric5m='error:rate_5m',
      metric30m='error:rate_30m',
      metric6h='error:rate_6h',
      metricSelectorHash={ type: 'web' },
      sloMetric='sla:error:rate',
      sloMetricSelectorHash={ monitor: 'global' },
      sloMetricAggregationLabels=['type', 'tier'],
    ),
    expect: |||
      (
        error:rate_1h{type="web"}
        > on(type,tier) group_left()
        (
          14.4 * (
            avg by (type,tier) (sla:error:rate{monitor="global"})
          )
        )
      )
      and
      (
        error:rate_5m{type="web"}
        > on(type,tier) group_left()
        (
          14.4 * (
            avg by (type,tier) (sla:error:rate{monitor="global"})
          )
        )
      )
      or
      (
        error:rate_6h{type="web"}
        > on(type,tier) group_left()
        (
          6 * (
            avg by (type,tier) (sla:error:rate{monitor="global"})
          )
        )
      )
      and
      (
        error:rate_30m{type="web"}
        > on(type,tier) group_left()
        (
          6 * (
            avg by (type,tier) (sla:error:rate{monitor="global"})
          )
        )
      )
    |||,
  },

  testErrorBurnWithMinimumRate: {
    actual: expression.multiburnRateErrorExpression(
      metric1h='error:rate_1h',
      metric5m='error:rate_5m',
      metric30m='error:rate_30m',
      metric6h='error:rate_6h',
      metricSelectorHash={ type: 'web' },
      sloMetric='sla:error:rate',
      sloMetricSelectorHash={ monitor: 'global' },
      sloMetricAggregationLabels=['type', 'tier'],
      operationRateMetric='operation:rate_1h',
      minimumOperationRateForMonitoring=1,
    ),
    expect: |||
      (
        (
          error:rate_1h{type="web"}
          > on(type,tier) group_left()
          (
            14.4 * (
              avg by (type,tier) (sla:error:rate{monitor="global"})
            )
          )
        )
        and
        (
          error:rate_5m{type="web"}
          > on(type,tier) group_left()
          (
            14.4 * (
              avg by (type,tier) (sla:error:rate{monitor="global"})
            )
          )
        )
        or
        (
          error:rate_6h{type="web"}
          > on(type,tier) group_left()
          (
            6 * (
              avg by (type,tier) (sla:error:rate{monitor="global"})
            )
          )
        )
        and
        (
          error:rate_30m{type="web"}
          > on(type,tier) group_left()
          (
            6 * (
              avg by (type,tier) (sla:error:rate{monitor="global"})
            )
          )
        )
      )
      and
      (
        operation:rate_1h{} >= 1
      )
    |||,
  },

  testApdexBurnWithoutMinimumRate: {
    actual: expression.multiburnRateApdexExpression(
      metric1h='apdex:rate_1h',
      metric5m='apdex:rate_5m',
      metric30m='apdex:rate_30m',
      metric6h='apdex:rate_6h',
      metricSelectorHash={ type: 'web' },
      sloMetric='sla:apdex:rate',
      sloMetricSelectorHash={ monitor: 'global' },
      sloMetricAggregationLabels=['type', 'tier'],
    ),
    expect: |||
      (
        apdex:rate_1h{type="web"}
        < on(type,tier) group_left()
        (
          1 -
          (
            14.4 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
          )
        )
      )
      and
      (
        apdex:rate_5m{type="web"}
        < on(type,tier) group_left()
        (
          1 -
          (
            14.4 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
          )
        )
      )
      or
      (
        apdex:rate_6h{type="web"}
        < on(type,tier) group_left()
        (
          1 -
          (
            6 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
          )
        )
      )
      and
      (
        apdex:rate_30m{type="web"}
        < on(type,tier) group_left()
        (
          1 -
          (
            6 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
          )
        )
      )
    |||,
  },

  testApdexBurnWithMinimumRate: {
    actual: expression.multiburnRateApdexExpression(
      metric1h='apdex:rate_1h',
      metric5m='apdex:rate_5m',
      metric30m='apdex:rate_30m',
      metric6h='apdex:rate_6h',
      metricSelectorHash={ type: 'web' },
      sloMetric='sla:apdex:rate',
      sloMetricSelectorHash={ monitor: 'global' },
      sloMetricAggregationLabels=['type', 'tier'],
      operationRateMetric='operation:rate_1h',
      minimumOperationRateForMonitoring=1,
    ),
    expect: |||
      (
        (
          apdex:rate_1h{type="web"}
          < on(type,tier) group_left()
          (
            1 -
            (
              14.4 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        and
        (
          apdex:rate_5m{type="web"}
          < on(type,tier) group_left()
          (
            1 -
            (
              14.4 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        or
        (
          apdex:rate_6h{type="web"}
          < on(type,tier) group_left()
          (
            1 -
            (
              6 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        and
        (
          apdex:rate_30m{type="web"}
          < on(type,tier) group_left()
          (
            1 -
            (
              6 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
      )
      and
      (
        operation:rate_1h{} >= 1
      )
    |||,
  },

  testApdexBurnWithMinimumRateAndAggregation: {
    actual: expression.multiburnRateApdexExpression(
      metric1h='apdex:rate_1h',
      metric5m='apdex:rate_5m',
      metric30m='apdex:rate_30m',
      metric6h='apdex:rate_6h',
      metricSelectorHash={ type: 'web' },
      sloMetric='sla:apdex:rate',
      sloMetricSelectorHash={ monitor: 'global' },
      sloMetricAggregationLabels=['type', 'tier'],
      operationRateMetric='operation:rate_1h',
      operationRateAggregationLabels=['x', 'y', 'z'],
      operationRateSelectorHash={ x: '1' },
      minimumOperationRateForMonitoring=1
    ),
    expect: |||
      (
        (
          apdex:rate_1h{type="web"}
          < on(type,tier) group_left()
          (
            1 -
            (
              14.4 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        and
        (
          apdex:rate_5m{type="web"}
          < on(type,tier) group_left()
          (
            1 -
            (
              14.4 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        or
        (
          apdex:rate_6h{type="web"}
          < on(type,tier) group_left()
          (
            1 -
            (
              6 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
        and
        (
          apdex:rate_30m{type="web"}
          < on(type,tier) group_left()
          (
            1 -
            (
              6 * (1 - avg by (type,tier) (sla:apdex:rate{monitor="global"}))
            )
          )
        )
      )
      and on(x,y,z)
      (
        sum by(x,y,z) (operation:rate_1h{x="1"}) >= 1
      )
    |||,
  },
})
