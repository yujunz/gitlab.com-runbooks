local multiburnFactors = import './multiburn_factors.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  // See https://landing.google.com/sre/workbook/chapters/alerting-on-slos/#5-multiple-burn-rate-alerts
  // for more details
  testBurnrate_1h: {
    actual: multiburnFactors.burnrate_1h,
    expect: 14.4,
  },
  testBurnrate_6h: {
    actual: multiburnFactors.burnrate_6h,
    expect: 6,
  },
  testErrorRatioThreshold1h: {
    actual: '%g' % [multiburnFactors.errorRatioThreshold1h(0.9995)],
    expect: '%g' % [0.0072],
  },
  testErrorRatioThreshold6h: {
    actual: '%g' % [multiburnFactors.errorRatioThreshold6h(0.9995)],
    expect: '%g' % [0.003],
  },
  testApdexRatioThreshold1h: {
    actual: '%g' % [multiburnFactors.apdexRatioThreshold1h(0.9995)],
    expect: '%g' % [0.9928],
  },
  testApdexRatioThreshold6h: {
    actual: '%g' % [multiburnFactors.apdexRatioThreshold6h(0.9995)],
    expect: '%g' % [0.997],
  },
})
