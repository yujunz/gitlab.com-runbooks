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
  continuousProfiler:: (import './continuous_profiler.libsonnet').continuousProfiler,
  sentry:: (import './sentry.libsonnet').sentry,
  bigquery:: (import './bigquery.libsonnet').bigquery,
  kibana:: (import './kibana.libsonnet').kibana,
  gkeDeployment:: (import './gke_deployment.libsonnet').gkeDeployment,
  generateMarkdown:: generateMarkdown,
}
