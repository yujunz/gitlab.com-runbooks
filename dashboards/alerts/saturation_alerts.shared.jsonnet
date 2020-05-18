local saturationResources = import './saturation-resources.libsonnet';
local saturationAlerts = import 'alerts/saturation_alerts.libsonnet';

{
  [saturationResources[key].grafana_dashboard_uid]:
    saturationAlerts.saturationDashboardForComponent(key)
  for key in std.objectFields(saturationResources)
}
