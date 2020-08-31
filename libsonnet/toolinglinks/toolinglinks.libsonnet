local generateMarkdownLink(toolingLinkDefinition) =
  |||
    * [%(title)s](%(url)s)
  ||| % {
    title: toolingLinkDefinition.title,
    url: toolingLinkDefinition.url,
  };

local generateMarkdown(toolingLinks) =
  std.join('', std.map(generateMarkdownLink, toolingLinks));

{
  cloudSQL: (import './cloud_sql.libsonnet').cloudSQL,
  continuousProfiler:: (import './continuous_profiler.libsonnet').continuousProfiler,
  elasticAPM:: (import './elastic_apm.libsonnet').elasticAPM,
  grafana:: (import './grafana.libsonnet').grafana,
  sentry:: (import './sentry.libsonnet').sentry,
  bigquery:: (import './bigquery.libsonnet').bigquery,
  kibana:: (import './kibana.libsonnet').kibana,
  gkeDeployment:: (import './gke_deployment.libsonnet').gkeDeployment,
  generateMarkdown:: generateMarkdown,
}