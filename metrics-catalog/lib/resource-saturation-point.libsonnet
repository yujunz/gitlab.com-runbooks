local strings = import 'strings.libsonnet';

local environmentLabels = ['environment', 'tier', 'type', 'stage'];

local resourceSaturationPoint = function(definition)
  definition {
    getQuery(selector, rangeInterval, maxAggregationLabels=[])::
      local staticLabels = self.getStaticLabels();
      local queryAggregationLabels = environmentLabels + definition.resourceLabels;
      local allMaxAggregationLabels = environmentLabels + maxAggregationLabels;
      local queryAggregationLabelsExcludingStaticLabels = std.filter(function(label) !std.objectHas(staticLabels, label), queryAggregationLabels);
      local maxAggregationLabelsExcludingStaticLabels = std.filter(function(label) !std.objectHas(staticLabels, label), allMaxAggregationLabels);

      local preaggregation = definition.query % {
        rangeInterval: rangeInterval,
        selector: selector,
        aggregationLabels: std.join(', ', queryAggregationLabelsExcludingStaticLabels),
      };

      |||
        max by(%(maxAggregationLabels)s) (
          clamp_min(
            clamp_max(
              %(query)s
              ,
              1)
          ,
          0)
        )
      ||| % {
        query: strings.indent(preaggregation, 6),
        maxAggregationLabels: std.join(', ', maxAggregationLabelsExcludingStaticLabels),
      },

    getLegendFormat()::
      if std.length(definition.resourceLabels) > 0 then
        std.join(' ', std.map(function(f) '{{ ' + f + ' }}', definition.resourceLabels))
      else
        '{{ type }}',

    getStaticLabels()::
      ({ staticLabels: {} } + definition).staticLabels,

    getRecordingRuleDefinition(componentName)::
      local definition = self;
      local query = definition.getQuery('environment!="", type!=""', '1m');

      {
        record: 'gitlab_component_saturation:ratio',
        labels: {
          component: componentName,
        } + definition.getStaticLabels(),
        expr: query,
      },

    getSLORecordingRuleDefinition(componentName)::
      local definition = self;
      local labels = {
        component: componentName,
      } + (
        if std.objectHas(definition.slos, 'alert_trigger_duration') then
          { alert_trigger_duration: definition.slos.alert_trigger_duration }
        else
          {}
      );

      [{
        record: 'slo:max:soft:gitlab_component_saturation:ratio',
        labels: labels,
        expr: '%g' % [definition.slos.soft],
      }, {
        record: 'slo:max:hard:gitlab_component_saturation:ratio',
        labels: labels,
        expr: '%g' % [definition.slos.hard],
      }],

  };

{
  resourceSaturationPoint(definition):: resourceSaturationPoint(definition),
}
