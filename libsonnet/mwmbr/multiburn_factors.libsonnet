// For details of how these factors are calculated,
// read https://landing.google.com/sre/workbook/chapters/alerting-on-slos/
local hoursPerMonth = 24 * 30;

local burnrate(errorConsumptionRate, windowHours) =
  (errorConsumptionRate * hoursPerMonth) / windowHours;

{
  allWindowIntervals: ['5m', '30m', '1h', '6h'],
  burnrate_1h: burnrate(0.02, 1),  // Burning 2% of error budget in 1h window
  burnrate_6h: burnrate(0.05, 6),  // Burning 5% of error budget in 6h window

  /**
   * Given an SLA, returns a max 1h error threshold
   *
   * @param sla an SLA expressed as a fraction from 0 to 1. Eg 0.9995 = 99.95%
   * @return a threshold maximum error percentage for a 1 hour burn rate
   */
  errorRatioThreshold1h(sla)::
    self.burnrate_1h * (1 - sla),

  /**
   * Given an SLA, returns a max 6h error threshold
   *
   * @param sla an SLA expressed as a fraction from 0 to 1. Eg 0.9995 = 99.95%
   * @return a threshold maximum error percentage for a 6 hour burn rate
   */
  errorRatioThreshold6h(sla)::
    self.burnrate_6h * (1 - sla),

  /**
   * Given an SLA, returns a min 1h apdex threshold
   *
   * @param sla an SLA expressed as a fraction from 0 to 1. Eg 0.9995 = 99.95%
   * @return a threshold minimum apdex percentage for a 1 hour burn rate
   */
  apdexRatioThreshold1h(sla)::
    1 - self.burnrate_1h * (1 - sla),

  /**
   * Given an SLA, returns a min 6h apdex threshold
   *
   * @param sla an SLA expressed as a fraction from 0 to 1. Eg 0.9995 = 99.95%
   * @return a threshold minimum apdex percentage for a 6 hour burn rate
   */
  apdexRatioThreshold6h(sla)::
    1 - self.burnrate_6h * (1 - sla),

}
