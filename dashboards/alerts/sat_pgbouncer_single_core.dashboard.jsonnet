local saturationAlerts = import 'alerts/saturation_alerts.libsonnet';

saturationAlerts.saturationDashboardForComponent('pgbouncer_single_core', 'patroni')
