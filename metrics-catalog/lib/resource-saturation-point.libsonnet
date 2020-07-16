local selectors = import './selectors.libsonnet';
local alerts = import 'alerts.libsonnet';
local stableIds = import 'lib/stable-ids.libsonnet';
local strings = import 'strings.libsonnet';

// The severity labels that we allow on resources
local severities = std.set(['s1', 's2', 's3', 's4']);

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

local validateAndApplyDefaults(definition) =
  local validated =
    std.isString(definition.title) &&
    std.setMember(definition.severity, severities) &&
    (std.isArray(definition.appliesTo) || std.isObject(definition.appliesTo)) &&
    std.isString(definition.description) &&
    std.isString(definition.grafana_dashboard_uid) &&
    std.isArray(definition.resourceLabels) &&
    std.isString(definition.query) &&
    std.isNumber(definition.slos.soft) && definition.slos.soft > 0 && definition.slos.soft <= 1 &&
    std.isNumber(definition.slos.hard) && definition.slos.hard > 0 && definition.slos.hard <= 1;

  // Apply defaults
  if validated then
    {
      queryFormatConfig: {},
    } + definition + {
      // slo defaults
      slos: {
        alertTriggerDuration: '5m',
      } + definition.slos,
    }
  else
    std.assertEqual(definition, { __assert__: 'Resource definition is invalid' });

local resourceSaturationPoint = function(options)
  local definition = validateAndApplyDefaults(options);
  local serviceApplicator = getServiceApplicator(definition.appliesTo);

  definition {
    getQuery(selectorHash, rangeInterval, maxAggregationLabels=[])::
      local staticLabels = self.getStaticLabels();
      local queryAggregationLabels = environmentLabels + self.resourceLabels;
      local allMaxAggregationLabels = environmentLabels + maxAggregationLabels;
      local queryAggregationLabelsExcludingStaticLabels = std.filter(function(label) !std.objectHas(staticLabels, label), queryAggregationLabels);
      local maxAggregationLabelsExcludingStaticLabels = std.filter(function(label) !std.objectHas(staticLabels, label), allMaxAggregationLabels);
      local queryFormatConfig = self.queryFormatConfig;

      // Remove any statically defined labels from the selectors, if they are defined
      local selectorWithoutStaticLabels = if staticLabels == {} then selectorHash else selectors.without(selectorHash, staticLabels);

      local preaggregation = self.query % queryFormatConfig {
        rangeInterval: rangeInterval,
        selector: selectors.serializeHash(selectorWithoutStaticLabels),
        aggregationLabels: std.join(', ', queryAggregationLabelsExcludingStaticLabels),
      };

      local clampedPreaggregation = |||
        clamp_min(
          clamp_max(
            %(query)s
            ,
            1)
        ,
        0)
      ||| % {
        query: strings.indent(preaggregation, 4),
      };

      |||
        max by(%(maxAggregationLabels)s) (
          %(quantileOverTimeQuery)s
        )
      ||| % {
        quantileOverTimeQuery: strings.indent(clampedPreaggregation, 2),
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
              { type: { re: std.join('|', definition.appliesTo) } }
            else
              { type: definition.appliesTo[0] }
          else
            if std.length(definition.appliesTo.allExcept) > 0 then
              { type: [{ ne: '' }, { nre: std.join('|', definition.appliesTo.allExcept) }] }
            else
              { type: { ne: '' } }
        );

      local query = definition.getQuery({ environment: { ne: '' } } + typeFilter, definition.getBurnRatePeriod());

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
      };

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

      local triggerDuration = definition.slos.alertTriggerDuration;

      local formatConfig = {
        triggerDuration: triggerDuration,
        componentName: componentName,
        description: definition.description,
        title: definition.title,
      };

      local severityLabels =
        { severity: definition.severity } +
        if definition.severity == 's1' || definition.severity == 's2' then
          { pager: 'pagerduty' }
        else
          {};

      [alerts.processAlertRule({
        alert: 'component_saturation_slo_out_of_bounds',
        expr: |||
          gitlab_component_saturation:ratio{component="%(componentName)s"} > on(component) group_left
          slo:max:hard:gitlab_component_saturation:ratio{component="%(componentName)s"}
        ||| % formatConfig,
        'for': triggerDuration,
        labels: {
          rules_domain: 'general',
          metric: 'gitlab_component_saturation:ratio',
          period: triggerDuration,
          bound: 'upper',
          alert_type: 'cause',
          alert_trigger_duration: triggerDuration,
          burn_rate_period: definition.getBurnRatePeriod(),
        } + severityLabels,
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
          grafana_panel_id: stableIds.hashStableId('saturation-' + componentName),
          grafana_variables: 'environment,type,stage',
          grafana_min_zoom_hours: '6',
          promql_query: definition.getQuery({
            environment: '{{ $labels.environment }}',
            stage: '{{ $labels.stage }}',
            type: '{{ $labels.type }}',
          }, definition.getBurnRatePeriod(), definition.resourceLabels),
        },
      })],

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
