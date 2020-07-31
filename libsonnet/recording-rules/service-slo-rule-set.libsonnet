local minApdexDeprecatedSingleBurnSLO(labels, expr) =
  {
    record: 'slo:min:gitlab_service_apdex:ratio',
    labels: labels,
    expr: expr,
  };

local maxErrorsDeprecatedSingleBurnSLO(labels, expr) =
  {
    record: 'slo:max:gitlab_service_errors:ratio',
    labels: labels,
    expr: expr,
  };

local maxErrorsMonitoringSLO(labels, expr) =
  {
    record: 'slo:max:events:gitlab_service_errors:ratio',
    labels: labels,
    expr: expr,
  };

local minApdexMonitoringSLO(labels, expr) =
  {
    record: 'slo:min:events:gitlab_service_apdex:ratio',
    labels: labels,
    expr: expr,
  };

local maxErrorsDeploymentSLO(labels, expr) =
  {
    record: 'slo:max:deployment:gitlab_service_errors:ratio',
    labels: labels,
    expr: expr,
  };

local minApdexDeploymentSLO(labels, expr) =
  {
    record: 'slo:min:deployment:gitlab_service_apdex:ratio',
    labels: labels,
    expr: expr,
  };

local generateServiceSLORules(serviceDefinition) =
  local hasContractualThresholds = std.objectHas(serviceDefinition, 'contractualThresholds');
  local hasMonitoringThresholds = std.objectHas(serviceDefinition, 'monitoringThresholds');
  local hasDeploymentThresholds = std.objectHas(serviceDefinition, 'deploymentThresholds');

  local triggerDurationLabels = if hasContractualThresholds && std.objectHas(serviceDefinition.contractualThresholds, 'alertTriggerDuration') then
    {
      alert_trigger_duration: serviceDefinition.contractualThresholds.alertTriggerDuration,
    }
  else {};

  local labels = {
    type: serviceDefinition.type,
    tier: serviceDefinition.tier,
  };

  local labelsWithTriggerDurations = labels + triggerDurationLabels;

  std.prune([
    if hasContractualThresholds && std.objectHas(serviceDefinition.contractualThresholds, 'apdexRatio') then
      minApdexDeprecatedSingleBurnSLO(
        labels=labelsWithTriggerDurations,
        expr='%f' % [serviceDefinition.contractualThresholds.apdexRatio]
      )
    else null,

    if hasContractualThresholds && std.objectHas(serviceDefinition.contractualThresholds, 'errorRatio') then
      maxErrorsDeprecatedSingleBurnSLO(
        labels=labelsWithTriggerDurations,
        expr='%f' % [serviceDefinition.contractualThresholds.errorRatio],
      )
    else null,

    // Min apdex SLO (multiburn)
    if hasMonitoringThresholds && std.objectHas(serviceDefinition.monitoringThresholds, 'apdexScore') then
      minApdexMonitoringSLO(
        labels=labels,
        expr='%f' % [serviceDefinition.monitoringThresholds.apdexScore],
      )
    else null,

    // Note: the max error rate is `1 - sla` (multiburn)
    if hasMonitoringThresholds && std.objectHas(serviceDefinition.monitoringThresholds, 'errorRatio') then
      maxErrorsMonitoringSLO(
        labels=labels,
        expr='%f' % [1 - serviceDefinition.monitoringThresholds.errorRatio],
      )
    else null,

    // Min apdex SLO (multiburn)
    if hasDeploymentThresholds && std.objectHas(serviceDefinition.deploymentThresholds, 'apdexScore') then
      minApdexDeploymentSLO(
        labels=labels,
        expr='%f' % [serviceDefinition.deploymentThresholds.apdexScore],
      )
    else null,

    // Note: the max error rate is `1 - sla` (multiburn)
    if hasDeploymentThresholds && std.objectHas(serviceDefinition.deploymentThresholds, 'errorRatio') then
      maxErrorsDeploymentSLO(
        labels=labels,
        expr='%f' % [1 - serviceDefinition.deploymentThresholds.errorRatio],
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
