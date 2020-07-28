local maxErrorsMonitoringSLOPerNode(labels, expr) =
  {
    record: 'slo:max:events:gitlab_component_node_errors:ratio',
    labels: labels,
    expr: expr,
  };

local minApdexMonitoringSLOPerNode(labels, expr) =
  {
    record: 'slo:min:events:gitlab_component_node_apdex:ratio',
    labels: labels,
    expr: expr,
  };

local generateComponentNodeSLORules(serviceDefinition) =
  local hasMonitoringThresholds = std.objectHas(serviceDefinition, 'monitoringThresholds');

  if hasMonitoringThresholds && serviceDefinition.nodeLevelMonitoring then
    local labels = {
      type: serviceDefinition.type,
      tier: serviceDefinition.tier,
    };

    std.prune([
      // Min apdex SLO (multiburn)
      if std.objectHas(serviceDefinition.monitoringThresholds, 'apdexScore') then
        minApdexMonitoringSLOPerNode(
          labels=labels,
          expr='%f' % [serviceDefinition.monitoringThresholds.apdexScore],
        )
      else null,

      // Note: the max error rate is `1 - sla` (multiburn)
      if std.objectHas(serviceDefinition.monitoringThresholds, 'errorRatio') then
        maxErrorsMonitoringSLOPerNode(
          labels=labels,
          expr='%f' % [1 - serviceDefinition.monitoringThresholds.errorRatio],
        )
      else null,
    ])
  else
    [];

{
  // For simplicity, component/node level alerts are evaluated at the prometheus level, not
  // in Thanos. This however means that we don't have access to the global SLO thresholds
  // which are only published in Thanos.
  //
  // This adds thresholds for evaluating the health of component/nodes.
  //
  // Another advantage of keeping this separate is that we could, in future adjust this
  // value independently of main service SLA if necessary.
  componentNodeSLORuleSet()::
    {
      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        generateComponentNodeSLORules(serviceDefinition),
    },

}
