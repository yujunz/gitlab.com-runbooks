local basic = import 'basic.libsonnet';
local commonAnnotations = import 'common_annotations.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;
local annotation = grafana.annotation;
local serviceCatalog = import 'service_catalog.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local sidekiqHelpers = import 'services/lib/sidekiq-helpers.libsonnet';

local selector = 'environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue"';

local joinSelectors(selectors) =
  local nonEmptySelectors = std.filter(function(x) std.length(x) > 0, selectors);
  std.join(', ', nonEmptySelectors);

local latencyHistogramQuery(percentile, bucketMetric, selector, aggregator, rangeInterval) =
  local aggregatorWithLe = joinSelectors([aggregator] + ['le']);
  |||
    histogram_quantile(%(percentile)g, sum by (%(aggregatorWithLe)s) (
      rate(%(bucketMetric)s{%(selector)s}[%(rangeInterval)s])
    ))
  ||| % {
    percentile: percentile,
    aggregatorWithLe: aggregatorWithLe,
    selector: selector,
    bucketMetric: bucketMetric,
    rangeInterval: rangeInterval,
  };

local counterRateQuery(bucketMetric, selector, aggregator, rangeInterval) =
  |||
    sum by (%(aggregator)s) (
      rate(%(bucketMetric)s{%(selector)s}[%(rangeInterval)s])
    )
  ||| % {
    aggregator: aggregator,
    selector: selector,
    bucketMetric: bucketMetric,
    rangeInterval: rangeInterval,
  };

local counterChangesQuery(bucketMetric, selector, aggregator, rangeInterval) =
  |||
    sum by (%(aggregator)s) (
      changes(%(bucketMetric)s{%(selector)s}[%(rangeInterval)s])
    )
  ||| % {
    aggregator: aggregator,
    selector: selector,
    bucketMetric: bucketMetric,
    rangeInterval: rangeInterval,
  };

local queuelatencyTimeseries(title, aggregators, legendFormat) =
  basic.latencyTimeseries(
    title=title,
    query=latencyHistogramQuery(0.95, 'sidekiq_jobs_queue_duration_seconds_bucket', selector, aggregators, '$__interval'),
    legendFormat=legendFormat,
  );


local latencyTimeseries(title, aggregators, legendFormat) =
  basic.latencyTimeseries(
    title=title,
    query=latencyHistogramQuery(0.95, 'sidekiq_jobs_completion_seconds_bucket', selector, aggregators, '$__interval'),
    legendFormat=legendFormat,
  );

local qpsTimeseries(title, aggregators, legendFormat) =
  basic.timeseries(
    title=title,
    query=counterRateQuery('sidekiq_jobs_completion_seconds_count', selector, aggregators, '$__interval'),
    legendFormat=legendFormat,
  );

local errorRateTimeseries(title, aggregators, legendFormat) =
  basic.timeseries(
    title=title,
    query=counterChangesQuery('sidekiq_jobs_failed_total', selector, aggregators, '$__interval'),
    legendFormat=legendFormat,
  );

local statPanel(
  title,
  panelTitle,
  color,
  query,
  legendFormat,
      ) =
  {
    links: [],
    options: {
      graphMode: 'none',
      colorMode: 'background',
      justifyMode: 'auto',
      fieldOptions: {
        values: false,
        calcs: [
          'lastNotNull',
        ],
        defaults: {
          thresholds: {
            mode: 'absolute',
            steps: [
              {
                color: color,
                value: null,
              },
            ],
          },
          mappings: [],
          title: title,
          unit: 's',
          decimals: 0,
        },
        overrides: [],
      },
      orientation: 'vertical',
    },
    pluginVersion: '6.6.1',
    targets: [promQuery.target(query, legendFormat=legendFormat, instant=true)],
    title: panelTitle,
    type: 'stat',
  };


basic.dashboard(
  'Queue Detail',
  tags=['type:sidekiq', 'detail'],
)
.addTemplate(templates.stage)
.addTemplate(template.new(
  'queue',
  '$PROMETHEUS_DS',
  'label_values(sidekiq_jobs_completion_seconds_count{environment="$environment", type="sidekiq"}, queue)',
  current='post_receive',
  refresh='load',
  sort=1,
  multi=true,
  includeAll=true,
  allValues='.*',
))
.addPanels(
  layout.grid([
    basic.labelStat(
      query=|||
        label_replace(
          topk by (queue) (1, sum(rate(sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue"}[$__range])) by (queue, %(label)s)),
          "%(label)s", "%(default)s", "%(label)s", ""
        )
      ||| % {
        label: attribute.label,
        default: attribute.default,
      },
      title=attribute.title,
      panelTitle='Queue Attribute: ' + attribute.title,
      color=attribute.color,
      legendFormat='{{ %s }} ({{ queue }})' % [attribute.label],
      links=attribute.links
    )
    for attribute in [{
      label: 'latency_sensitive',
      title: 'Latency Sensitive',
      color: 'yellow',
      default: 'unknown',
      links: [],
    }, {
      label: 'feature_category',
      title: 'Feature Category',
      color: 'blue',
      default: 'unknown',
      links: [],
    }, {
      label: 'priority',
      title: 'Priority',
      color: 'orange',
      default: 'unknown',
      links: [{
        title: 'Sidekiq Priority Detail: ${__field.labels.priority}',
        url: '/d/sidekiq-priority-detail/sidekiq-priority-detail?orgId=1&var-priority=${__field.labels.priority}&var-environment=${environment}&var-stage=${stage}&${__url_time_range}',
      }],
    }, {
      label: 'external_dependencies',
      title: 'External Dependencies',
      color: 'green',
      default: 'none',
      links: [],
    }, {
      label: 'boundary',
      title: 'Resource Boundary',
      color: 'purple',
      default: 'none',
      links: [],
    }]
  ] + [
    statPanel(
      'Max Queuing Duration SLO',
      'Max Queuing Duration SLO',
      'light-red',
      |||
        vector(%(nonUrgentSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", latency_sensitive="no"}
        or
        vector(%(urgentSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", latency_sensitive="yes"}
      ||| % {
        nonUrgentSLO: sidekiqHelpers.slos.nonUrgent.queueingDurationSeconds,
        urgentSLO: sidekiqHelpers.slos.urgent.queueingDurationSeconds,
      },
      '{{ queue }}',
    ),
    statPanel(
      'Max Execution Duration SLO',
      'Max Execution Duration SLO',
      'red',
      |||
        vector(%(nonUrgentSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", latency_sensitive="no"}
        or
        vector(%(urgentSLO)f) and on () sidekiq_running_jobs{environment="$environment", type="sidekiq", stage="$stage", queue=~"$queue", latency_sensitive="yes"}
      ||| % {
        nonUrgentSLO: sidekiqHelpers.slos.nonUrgent.executionDurationSeconds,
        urgentSLO: sidekiqHelpers.slos.urgent.executionDurationSeconds,
      },
      '{{ queue }}',
    ),
  ], cols=8, rowHeight=4)
  +
  layout.grid([
    queuelatencyTimeseries('Queue Time', aggregators='queue', legendFormat='p95 {{ queue }}'),
    latencyTimeseries('Execution Time', aggregators='queue', legendFormat='p95 {{ queue }}'),
    qpsTimeseries('QPS', aggregators='queue', legendFormat='{{ queue }}'),
    errorRateTimeseries('Error Rate', aggregators='queue', legendFormat='{{ queue }}'),

    queuelatencyTimeseries('Queue Time per Node', aggregators='fqdn, queue', legendFormat='p95 {{ queue }} - {{ fqdn }}'),
    latencyTimeseries('Execution Time per Node', aggregators='fqdn, queue', legendFormat='p95 {{ queue }} - {{ fqdn }}'),
    qpsTimeseries('QPS per Node', aggregators='fqdn, queue', legendFormat='{{ queue }} - {{ fqdn }}'),
    errorRateTimeseries('Error Rate per Node', aggregators='fqdn, queue', legendFormat='{{ queue }} - {{ fqdn }}'),
  ], cols=4, startRow=100)
)
.trailer()
+ {
  links+:
    platformLinks.triage +
    serviceCatalog.getServiceLinks('sidekiq') +
    platformLinks.services +
    [platformLinks.dynamicLinks('Sidekiq Detail', 'type:sidekiq')],
}
