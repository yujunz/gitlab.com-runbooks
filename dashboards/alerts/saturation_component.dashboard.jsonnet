local saturationAlerts = import 'alerts/saturation_alerts.libsonnet';
local saturationDetail = import 'saturation_detail.libsonnet';
local seriesOverrides = import 'series_overrides.libsonnet';
local templates = import 'templates.libsonnet';

saturationAlerts.saturationDashboard(
  dashboardTitle='Saturation Component Alert',
  component='$component',
  panel=saturationDetail.saturationPanel(
    title='$component Saturation',
    description='Saturation is a measure of what ratio of a finite resource is currently being utilized. Lower is better.',
    component='$component',
    linewidth=2,
    query=|||
      max(
        max_over_time(
          gitlab_component_saturation:ratio{environment="$environment", type="$type", stage="$stage", component="$component"}[$__interval]
        )
      ) by (component)
    |||,
    legendFormat='{{ component }} component',
  )
  .addSeriesOverride(seriesOverrides.goldenMetric('/ component/'))

)
.addTemplate(templates.saturationComponent)
