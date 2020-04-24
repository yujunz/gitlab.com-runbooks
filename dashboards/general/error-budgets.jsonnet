local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;

local styles = [
  {
    type: 'hidden',
    pattern: 'Time',
    mappingType: 1,
  },
  {
    unit: 'percentunit',
    type: 'number',
    decimals: 3,
    pattern: 'Value',
    mappingType: 1,
  },
  {
    unit: 'short',
    type: 'string',
    alias: 'Queue',
    decimals: 2,
    pattern: 'queue',
    mappingType: 2,
    link: true,
    linkUrl: '/d/sidekiq-queue-detail/sidekiq-queue-detail?orgId=1&var-environment=$environment&var-queue=${__cell}',
    linkTooltip: 'View queue details',
  },
];

dashboard.new(
  'Feature Category Error Budgets',
  schemaVersion=16,
  tags=['feature_category'],
  timezone='utc',
  graphTooltip='shared_crosshair',
  time_from='now-7d',
  time_to='now',
  timepicker={
    refresh_intervals: [],
  },
)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanels(
  layout.grid([
    basic.table(
      title='Apdex by Feature Category',
      query=|||
        sort(
          clamp_max(
            sum by (feature_category) (
              avg_over_time(gitlab_background_jobs:execution:apdex:ratio_6h{environment="$environment", env="$environment"}[$__range])
              *
              avg_over_time(gitlab_background_jobs:execution:ops:rate_6h{environment="$environment", env="$environment"}[$__range])
            )
            /
              (
              sum by(feature_category) (
                avg_over_time(gitlab_background_jobs:execution:ops:rate_6h{environment="$environment", env="$environment"}[$__range])
              )
            ) > 0,
            1
          )
        )
      |||,
      styles=styles
    ),
    basic.table(
      title='Error Rate by Feature Category',
      query=|||
        sort_desc(
          clamp_max(
            sum by (feature_category) (
              avg_over_time(gitlab_background_jobs:execution:error:rate_6h{environment="$environment", env="$environment"}[$__range])
            )
            /
              (
              sum by(feature_category) (
                avg_over_time(gitlab_background_jobs:execution:ops:rate_6h{environment="$environment", env="$environment"}[$__range])
              ) > 0
            ),
            1
          )
        )
      |||,
      styles=styles
    ),
    basic.table(
      title='Apdex by Queue',
      query=|||
        sort(
          clamp_max(
            sum by (queue, feature_category) (
              avg_over_time(gitlab_background_jobs:execution:apdex:ratio_6h{environment="$environment", env="$environment"}[$__range])
              *
              avg_over_time(gitlab_background_jobs:execution:ops:rate_6h{environment="$environment", env="$environment"}[$__range])
            )
            /
              (
              sum by(queue, feature_category) (
                avg_over_time(gitlab_background_jobs:execution:ops:rate_6h{environment="$environment", env="$environment"}[$__range])
              )
            ) > 0,
            1
          )
        )
      |||,
      styles=styles,
    ),
    basic.table(
      title='Error Rate by Queue',
      query=|||
        sort_desc(
          clamp_max(
            sum by (queue, feature_category) (
              avg_over_time(gitlab_background_jobs:execution:error:rate_6h{environment="$environment", env="$environment"}[$__range])
            )
            /
            (
              sum by(queue, feature_category) (
                avg_over_time(gitlab_background_jobs:execution:ops:rate_6h{environment="$environment", env="$environment"}[$__range])
              )
            ) > 0,
            1
          )
        )
      |||,
      styles=styles
    ),
  ], cols=2, rowHeight=12, startRow=1)
)
+ {
  links+: platformLinks.services + platformLinks.triage,
}
