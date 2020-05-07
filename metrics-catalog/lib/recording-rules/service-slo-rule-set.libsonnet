local minApdexSLO(labels, expr) =
  {
    record: 'slo:min:gitlab_service_apdex:ratio',
    labels: labels,
    expr: expr,
  };

local maxErrorsSLO(labels, expr) =
  {
    record: 'slo:max:gitlab_service_errors:ratio',
    labels: labels,
    expr: expr,
  };

local maxErrorsEventRateSLO(labels, expr) =
  {
    record: 'slo:max:events:gitlab_service_errors:ratio',
    labels: labels,
    expr: expr,
  };

local minApdexTargetSLO(labels, expr) =
  {
    record: 'slo:min:events:gitlab_service_apdex:ratio',
    labels: labels,
    expr: expr,
  };

local generateServiceSLORules(serviceDefinition) =
  local hasMonitoringThresholds = std.objectHas(serviceDefinition, 'monitoringThresholds');
  local hasEventBasedSLOTargets = std.objectHas(serviceDefinition, 'eventBasedSLOTargets');

  local triggerDurationLabels = if hasMonitoringThresholds && std.objectHas(serviceDefinition.monitoringThresholds, 'alertTriggerDuration') then
    {
      alert_trigger_duration: serviceDefinition.monitoringThresholds.alertTriggerDuration,
    }
  else {};

  local labels = {
    type: serviceDefinition.type,
    tier: serviceDefinition.tier,
  };

  local labelsWithTriggerDurations = labels + triggerDurationLabels;

  std.prune([
    if hasMonitoringThresholds && std.objectHas(serviceDefinition.monitoringThresholds, 'apdexRatio') then
      minApdexSLO(
        labels=labelsWithTriggerDurations,
        expr='%f' % [serviceDefinition.monitoringThresholds.apdexRatio]
      )
    else null,

    if hasMonitoringThresholds && std.objectHas(serviceDefinition.monitoringThresholds, 'errorRatio') then
      maxErrorsSLO(
        labels=labelsWithTriggerDurations,
        expr='%f' % [serviceDefinition.monitoringThresholds.errorRatio],
      )
    else null,

    // Min apdex SLO (multiburn)
    if hasEventBasedSLOTargets && std.objectHas(serviceDefinition.eventBasedSLOTargets, 'apdexScore') then
      minApdexTargetSLO(
        labels=labels,
        expr='%f' % [serviceDefinition.eventBasedSLOTargets.apdexScore],
      )
    else null,

    // Note: the max error rate is `1 - sla` (multiburn)
    if hasEventBasedSLOTargets && std.objectHas(serviceDefinition.eventBasedSLOTargets, 'errorRatio') then
      maxErrorsEventRateSLO(
        labels=labels,
        expr='%f' % [1 - serviceDefinition.eventBasedSLOTargets.errorRatio],
      )
    else null,
  ]);

{
  // serviceSLORuleSet generates static recording rules for recording the current
  // SLO for each service in the metrics catalog.
  // These values are static, but can change over time.
  // They are used for alerting, visualisation and calculating availability.
  serviceSLORuleSet()::
    {
      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        generateServiceSLORules(serviceDefinition),
    },

}
