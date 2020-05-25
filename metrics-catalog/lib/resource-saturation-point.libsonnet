local strings = import 'strings.libsonnet';

local environmentLabels = ['environment', 'tier', 'type', 'stage'];

local getAllowedServiceApplicator(allowedList) =
  local allowedSet = std.set(allowedList);
  function(type) std.setMember(type, allowedSet);

local getDisallowedServiceApplicator(disallowedList) =
  local disallowedSet = std.set(disallowedList);
  function(type) !std.setMember(type, disallowedSet);

// Returns a function that returns a boolean to indicate whether a service
// applies for the provided definition
local getServiceApplicator(appliesTo) =
  if std.isArray(appliesTo) then
    getAllowedServiceApplicator(appliesTo)
  else
    getDisallowedServiceApplicator(appliesTo.allExcept);


local resourceSaturationPoint = function(definition)
  local serviceApplicator = getServiceApplicator(definition.appliesTo);

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

    // This signifies the minimum period over which this resource is
    // evaluated. Defaults to 1m, which is the legacy value
    getBurnRatePeriod()::
      ({ burnRatePeriod: '1m' } + self).burnRatePeriod,

    getRecordingRuleDefinition(componentName)::
      local definition = self;

      local typeFilter =
        (
          if std.isArray(definition.appliesTo) then
            if std.length(definition.appliesTo) > 1 then
              'type=~"%s"' % [std.join('|', definition.appliesTo)]
            else
              'type="%s"' % [definition.appliesTo[0]]
          else
            if std.length(definition.appliesTo.allExcept) > 0 then
              'type!="", type!~"%s"' % [std.join('|', definition.appliesTo.allExcept)]
            else
              'type!=""'
        );

      local query = definition.getQuery('environment!="", %s' % [typeFilter], definition.getBurnRatePeriod());

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

    getSaturationAlerts(componentName)::
      local definition = self;

      local triggerDuration = if ({ alert_trigger_duration: '' } + definition.slos).alert_trigger_duration == 'long' then
        '15m'
      else
        '5m';

      local formatConfig = {
        triggerDuration: triggerDuration,
        componentName: componentName,
        description: definition.description,
        title: definition.title,
      };

      [{
        alert: 'component_saturation_slo_out_of_bounds',
        expr: |||
          gitlab_component_saturation:ratio{component="%(componentName)s"} > on(component) group_left
          slo:max:hard:gitlab_component_saturation:ratio{component="%(componentName)s"}
        ||| % formatConfig,
        'for': triggerDuration,
        labels: {
          rules_domain: 'general',
          metric: 'gitlab_component_saturation:ratio',
          severity: 's3',  // TODO: add a criticality indicator
          period: triggerDuration,
          bound: 'upper',
          alert_type: 'cause',
          burnRatePeriod: definition.getBurnRatePeriod(),
          // slo_alert: 'yes' Uncomment after trial period
          // pager: pagerduty Uncomment after trial period
        },
        annotations: {
          title: 'The %(title)s resource of the {{ $labels.type }} service ({{ $labels.stage }} stage), component has a saturation exceeding SLO and is close to its capacity limit.' % formatConfig,
          description: |||
            This means that this resource is running close to capacity and is at risk of exceeding its current capacity limit.

            Details of the %(title)s resource:
            ----------------------------------------------

            %(description)s
          ||| % formatConfig,
          runbook: 'docs/{{ $labels.type }}/service-{{ $labels.type }}.md',
          grafana_dashboard_id: 'alerts-' + definition.grafana_dashboard_uid,
          grafana_panel_id: '2',
          grafana_variables: 'environment,type,stage',
          grafana_min_zoom_hours: '6',
          promql_query: definition.getQuery('environment="{{ $labels.environment }}",stage="{{ $labels.stage }}",type="{{ $labels.type }}"', definition.getBurnRatePeriod(), definition.resourceLabels),
        },
      }],

    // Returns a boolean to indicate whether this saturation point applies to
    // a given service
    appliesToService(type)::
      serviceApplicator(type),

    // When a dashboard for this alert is opened without a type,
    // what should the default be?
    // For allowLists: always use the first item
    // For blockLists: use the default or web
    getDefaultGrafanaType()::
      if std.isArray(definition.appliesTo) then
        definition.appliesTo[0]
      else
        if std.objectHas(definition.appliesTo, 'default') then
          definition.appliesTo.default
        else
          'web',
  };

{
  resourceSaturationPoint(definition):: resourceSaturationPoint(definition),
}
