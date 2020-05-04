local saturationAlerts = import 'alerts/saturation_alerts.libsonnet';

saturationAlerts.saturationDashboardForComponent('redis_memory', 'redis')
