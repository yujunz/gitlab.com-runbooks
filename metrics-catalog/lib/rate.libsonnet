local recordingRules = import './recording_rules.libsonnet';
local selectors = import './selectors.libsonnet';

local generateQuery(rate, counterFunction, aggregationLabels, additionalSelectors, duration) =
  local selector = selectors.join([rate.selector, additionalSelectors]);

  |||
    sum by (%(aggregationLabels)s) (
      %(counterFunction)s(%(counter)s{%(selector)s}[%(duration)s])
    )
  ||| % {
    counterFunction: counterFunction,
    aggregationLabels: aggregationLabels,
    counter: rate.counter,
    selector: selector,
    duration: duration,
  };

{
  rateMetric(
    counter,
    selector='',
  ):: {
    counter: counter,
    selector: selector,

    requestRateRecordingRules(aggregationLabels, labels)::
      local s = self;
      [
        recordingRules.requestRate(
          labels=labels,
          expr=generateQuery(s, 'rate', aggregationLabels, '', '1m'),
        ),
      ],

    errorRateRecordingRules(aggregationLabels, labels)::
      local s = self;
      [
        recordingRules.errorRate(
          labels=labels,
          expr=generateQuery(s, 'rate', aggregationLabels, '', '1m'),
        ),
      ],

    rateQuery(aggregationLabels, selector, rangeInterval)::
      generateQuery(self, 'rate', aggregationLabels, selector, rangeInterval),

    changesQuery(aggregationLabels, selector, rangeInterval)::
      generateQuery(self, 'changes', aggregationLabels, selector, rangeInterval),
  },
}
