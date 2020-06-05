local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local promQuery = import 'prom_query.libsonnet';

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

basic.dashboard(
  'Feature Category Detail - Error Budgets',
  tags=['feature_category'],
  time_from='now-7d',
  time_to='now/m',
)
.addPanels(
  layout.grid([
    grafana.text.new(
      title='Apdex by Feature Category Help',
      mode='markdown',
      content=|||
        This table shows the apdex scores for each Sidekiq worker in the application, aggregated up
        to the feature category level.

        To help understand what this metric means, you can think of it as the percentage of jobs
        for each feature category that meet their execution SLO.

        Currently we have 3 levels of `urgency` for Sidekiq jobs. High, low and throttled. Each
        level has an maximum execution time. The apdex score is effectively the number of jobs
        in each category that meet their execution latency SLO.
      |||
    ),
    grafana.text.new(
      title='Error Rate by Feature Category Help',
      mode='markdown',
      content=|||
        This table shows the error ratios for each Sidekiq worker in the application, aggregated up
        to the feature category level.

        This is a percentage of jobs in each feature category that complete successfully.
      |||
    ),
  ], cols=2, rowHeight=6, startRow=1)
  +
  layout.grid([
    basic.table(
      title='Apdex by Feature Category',
      query=|||
        sort_desc(
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
        sort(
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
  ], cols=2, rowHeight=12, startRow=100)
  +
  layout.grid([
    grafana.text.new(
      title='Apdex by Queue Help',
      mode='markdown',
      content=|||
        This table shows the apdex scores for each Sidekiq worker in the application.

        The apdex score measures the percentage of jobs that complete within their
        execution latency SLO.

        To find out what the execution latency SLO for a job is, click through the table
        to the Sidekiq Queue Detail dashboard.
      |||
    ),
    grafana.text.new(
      title='Error Rate by Queue Help',
      mode='markdown',
      content=|||
        This table shows the error ratios for each Sidekiq worker in the application.

        This is a percentage of jobs for each worker that complete successfully.
      |||
    ),
  ], cols=2, rowHeight=6, startRow=200)
  +
  layout.grid([
    basic.table(
      title='Apdex by Queue',
      query=|||
        sort_desc(
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
        sort(
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
  ], cols=2, rowHeight=12, startRow=300) +
  layout.grid([
    grafana.text.new(
      title='Error Budget Queue Attribution Help',
      mode='markdown',
      content=|||
        This charts shows how much each queue contributed to the total degradation of availability
        of the Sidekiq service, over the range for this dashboard. This takes into account
        percentage of time that it missed its queueing latency SLO, percentage of time that it
        missed its execution latency SLO, and error rates.

        The ratio is measured as a fraction of the entire service, not on a per-queue basis.
      |||
    ),
  ], cols=1, rowHeight=4, startRow=400) +
  layout.grid([
    graphPanel.new(
      'Error Budget Queue Attribution',
      description='Total queue contribution to error budget',
      min=0,
      max=null,
      x_axis_mode='series',
      x_axis_values='current',
      lines=false,
      points=false,
      bars=true,
      format='percentunit',
      legend_show=false,
      value_type='individual'
    )
    .addTarget(
      promQuery.target(
        |||
          topk(8,
            sum without(attribution) (
              label_replace(
                (1 - avg_over_time(gitlab_background_jobs:execution:apdex:ratio_6h{environment="$environment", env="$environment"}[$__range]))
                *
                avg_over_time(gitlab_background_jobs:execution:apdex:weight:score_6h{environment="$environment", env="$environment"}[$__range])
                / on() group_left()
                sum(avg_over_time(gitlab_background_jobs:execution:apdex:weight:score_6h{environment="$environment", env="$environment"}[$__range])),
                "attribution", "execution", "", ""
              )
              or
              label_replace(
                (1 - avg_over_time(gitlab_background_jobs:queue:apdex:ratio_6h{environment="$environment", env="$environment"}[$__range]))
                *
                avg_over_time(gitlab_background_jobs:queue:apdex:weight:score_6h{environment="$environment", env="$environment"}[$__range])
                / on() group_left()
                sum(avg_over_time(gitlab_background_jobs:queue:apdex:weight:score_6h{environment="$environment", env="$environment"}[$__range])),
                "attribution", "queue", "", ""
              )
              or
              label_replace(
                avg_over_time(gitlab_background_jobs:execution:error:rate_6h[$__range])
                / on() group_left()
                sum(avg_over_time(gitlab_background_jobs:execution:ops:rate_6h[$__range]))
                ,"attribution", "errors", "", ""
              )
            )
          )
        |||,
        instant=true,
        legendFormat='{{ queue }}',
      )
    ) + {
      tooltip: {
        shared: false,
        sort: 0,
        value_type: 'individual',
      },
    },

  ], cols=1, rowHeight=12, startRow=500)
)
+ {
  links+: platformLinks.services + platformLinks.triage,
}
