local recordingRules = import './recording_rules.libsonnet';
local selectors = import './selectors.libsonnet';

local generateRateQuery(c, aggregationLabels, selector, rangeInterval) =
  local rateQueries = std.map(function(i) i.rateQuery(aggregationLabels, selector, rangeInterval), c.metrics);
  std.join('+\n', rateQueries);

local generateChangesQuery(c, aggregationLabels, selector, rangeInterval) =
  local rateQueries = std.map(function(i) i.changesQuery(aggregationLabels, selector, rangeInterval), c.metrics);
  std.join('+\n', rateQueries);


// "combined" allows two counter metrics to be added together
// to generate a new metric value
{
  combined(
    metrics
  ):: {
    metrics: metrics,

    requestRateRecordingRules(aggregationLabels, labels)::
      local s = self;
      [
        recordingRules.requestRate(
          labels=labels,
          expr=generateRateQuery(s, aggregationLabels, '', '1m'),
        ),
      ],

    errorRateRecordingRules(aggregationLabels, labels)::
      local s = self;
      [
        recordingRules.errorRate(
          labels=labels,
          expr=generateRateQuery(s, aggregationLabels, '', '1m'),
        ),
      ],

    rateQuery(aggregationLabels, selector, rangeInterval)::
      generateRateQuery(self, aggregationLabels, selector, rangeInterval),

    changesQuery(aggregationLabels, selector, rangeInterval)::
      generateChangesQuery(self, aggregationLabels, selector, rangeInterval),
  },
}
