local saturationAlerts = import 'alerts/saturation_alerts.libsonnet';

saturationAlerts.saturationDashboardForComponent('disk_sustained_write_iops', 'patroni')
