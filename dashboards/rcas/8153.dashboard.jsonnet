local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;

local commonAnnotations = import 'common_annotations.libsonnet';
local templates = import 'templates.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local keyMetrics = import 'key_metrics.libsonnet';
local text = grafana.text;

basic.dashboard(
  '2019-10-13 October 13 / Sunday night Crypto Miner Limit Takedown',
  tags=['rca'],
  time_from='2019-10-13T12:00:00.000Z',
  time_to='2019-10-14T02:00:00Z',
)
.addPanel(
  text.new(
    title='Intro',
    mode='markdown',
    content=|||
      # RCA dashboard for https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/8153

      ## Production incident: https://gitlab.com/gitlab-com/gl-infra/production/issues/1245

      ## Working doc: https://docs.google.com/document/d/1e_2FYIF7yTv90wUubgLEhVYsq03WBno1pOg6lQhPOaE/edit
    |||
  ), gridPos={ x: 0, y: 0, h: 4, w: 24 }
)
.addPanels(layout.grid([

  // ------------------------------------------------------

  text.new(title='CPU utilization on patroni-02, the postgres primary',
           mode='markdown',
           content=|||
             # This graph shows how this incident applied CPU saturation pressure to our Postgres primary database. This had a knock-on effect to the rest of the site.
           |||),
  basic.saturationTimeseries(
    title='Postgres Primary Average CPU Utilization',
    query=|||
      avg(instance:node_cpu_utilization:ratio{fqdn="patroni-02-db-gprd.c.gitlab-production.internal", environment="gprd"}) by (fqdn)
    |||,
    legendFormat='{{ fqdn }}',
  ),

  // ------------------------------------------------------

  text.new(
    title='Sidekiq pipeline latencies go up',
    mode='markdown',
    content=|||
      # ExpireJobCacheWorker and StageUpdateWorker jobs slowed down. Here is the rate at which these jobs were executed.

      ## Side note: at present, we do not record the enqueue rate for Sidekiq jobs. We should as this is an important metric for understanding queueing systems.
    |||
  ),
  basic.timeseries(
    title='ExpireJobCacheWorker,StageUpdateWorker Sidekiq job rates ',
    description='Sidekiq ExpireJobCacheWorker,StageUpdateWorker pipeline (CI) jobs starting per second',
    query=|||
      sum(rate(sidekiq_jobs_completion_seconds_count{queue=~"pipeline_cache:expire_job_cache|pipeline_processing:stage_update", environment="gprd", env="gprd"}[$__interval])) by (queue)
    |||,
    legendFormat='{{ queue }}',
    format='short',
    interval='1m',
    linewidth=1,
    intervalFactor=5,
  ),


  // ------------------------------------------------------

  text.new(
    title='Sidekiq pipeline latencies go up',
    mode='markdown',
    content=|||
      # Some CI pipeline worker queries slowed down, putting pressure on the Postgres primary and slowing down Sidekiq jobs that ran them
    |||
  ),
  basic.latencyTimeseries(
    title='ExpireJobCacheWorker,StageUpdateWorker latency ',
    description='p90 Processing time for ExpireJobCacheWorker,StageUpdateWorker pipeline (CI) jobs',
    query=|||
      histogram_quantile(0.9, sum(rate(sidekiq_jobs_completion_seconds_bucket{queue=~"pipeline_cache:expire_job_cache|pipeline_processing:stage_update", environment="gprd", env="gprd"}[$__interval])) by (le, queue))
    |||,
    legendFormat='{{ queue }}',
    format='s',
    interval='1m',
    linewidth=1,
    intervalFactor=5,
  ),

  // ------------------------------------------------------

  text.new(
    title='Sidekiq queue lengths',
    mode='markdown',
    content=|||
      # As sidekiq slowed down, thousands of duplicate jobs were queued up

      ## https://gitlab.com/gitlab-com/gl-infra/scalability/issues/42 is intended to address this issue
    |||
  ),
  basic.queueLengthTimeseries(
    title='Sidekiq Queue Lengths per Queue',
    description='The number of jobs queued up to be executed. Lower is better',
    query=|||
      max_over_time(sidekiq_queue_size{environment="gprd"}[$__interval]) and on(fqdn) (redis_connected_slaves != 0)
    |||,
    legendFormat='{{ name }}',
    format='short',
    interval='1m',
    linewidth=1,
    intervalFactor=3,
    yAxisLabel='Queue Length',
  ),

  // ------------------------------------------------------

  text.new(
    title='Total CI Minutes on Shared Runners',
    mode='markdown',
    content=|||
      # Total CI Minutes spiked but quickly dropped down as the user was blocked, banned and ran out of minutes

      ## This shows how little impact this had on CI. However the downstream impact was much worse that the actual CI impact.
    |||
  ),
  basic.queueLengthTimeseries(
    title='Sidekiq Queue Lengths per Queue',
    description='The number of jobs queued up to be executed. Lower is better',
    query=|||
      sum(rate(job_queue_duration_seconds_sum{shared_runner="true", environment="gprd"}[$__interval]))
    |||,
    legendFormat='{{ name }}',
    format='s',
    interval='1m',
    linewidth=1,
    intervalFactor=3,
  ),


  // ------------------------------------------------------

  text.new(
    title='Impact on web performance',
    mode='markdown',
    content=|||
      # This chart shows that the impact of this issue on web performance was relatively brief, lasting between 17h35 and 17h54UTC
    |||
  ),
  keyMetrics.apdexPanel('web', 'main'),

  // ------------------------------------------------------

  text.new(
    title='CI Runner 1m SLO',
    mode='markdown',
    content=|||
      # Our CI-Runners SLO is currently being focused on (see https://gitlab.com/gitlab-com/www-gitlab-com/issues/5341) but strangely it seems to have improved during the outage

      ## This may be down to reporting. We should investigate this in more detail
    |||
  ),
  keyMetrics.apdexPanel('ci-runners', 'main'),

  // ------------------------------------------------------

  text.new(
    title='Postgres Transaction Rollbacks',
    mode='markdown',
    content=|||
      # During the incident, we saw a high rate of postgres rollbacks. The cause of this has not been full investigated yet, although its not an unexpected outcome.
    |||
  ),
  keyMetrics.errorRatesPanel('patroni', 'main'),

], cols=2, rowHeight=10, startRow=11))
+ {
  annotations: {
    list+: [
      {
        datasource: 'Pagerduty',
        enable: true,
        hide: false,
        iconColor: '#F2495C',
        limit: 100,
        name: 'GitLab Production Pagerduty',
        serviceId: 'PATDFCE',
        showIn: 0,
        tags: [],
        type: 'tags',
        urgency: 'high',
      },
      {
        datasource: 'Pagerduty',
        enable: true,
        hide: false,
        iconColor: '#C4162A',
        limit: 100,
        name: 'GitLab Production SLO',
        serviceId: 'P7Q44DU',
        showIn: 0,
        tags: [],
        type: 'tags',
        urgency: 'high',
      },
      {
        datasource: 'Simple Annotations',
        enable: true,
        hide: false,
        iconColor: '#5794F2',
        limit: 100,
        name: 'Key Events',
        // To be completed...
        queries: [
        ],  // { date: "2019-08-14T08:25:00Z", text: "The patroni postgres cluster manager on the primary database instance (pg01) reports 'ERROR: get_cluster'" },
        showIn: 0,
        tags: [],
        type: 'tags',
      },
    ],
  },
}
