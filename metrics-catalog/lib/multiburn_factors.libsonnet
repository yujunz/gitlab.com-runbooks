// For details of how these factors are calculated,
// read https://landing.google.com/sre/workbook/chapters/alerting-on-slos/
local hoursPerMonth = 24 * 30;

local burnrate(errorConsumptionRate, windowHours) =
  (errorConsumptionRate * hoursPerMonth) / windowHours;

{
  allWindowIntervals: ['5m', '30m', '1h', '6h'],
  burnrate_1h: burnrate(0.02, 1),  // Burning 2% of error budget in 1h window
  burnrate_6h: burnrate(0.05, 6),  // Burning 5% of error budget in 6h window
}
