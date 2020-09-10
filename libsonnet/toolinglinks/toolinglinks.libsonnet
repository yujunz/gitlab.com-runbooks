local generateMarkdownLink(toolingLinkDefinition, options) =
  local toolingLinks = toolingLinkDefinition(options);

  [
    |||
      * [%(title)s](%(url)s)
    ||| % {
      title: tl.title,
      url: tl.url,
    }

    for tl in toolingLinks
  ];

local generateMarkdown(toolingLinks, options={}) =
  local optionsWithDefaults = {
    prometheusSelectorHash: {},
  } + options;
  std.join('', std.flatMap(function(toolingLinkDefinition) generateMarkdownLink(toolingLinkDefinition, options), toolingLinks));

{
  cloudSQL: (import './cloud_sql.libsonnet').cloudSQL,
  continuousProfiler:: (import './continuous_profiler.libsonnet').continuousProfiler,
  elasticAPM:: (import './elastic_apm.libsonnet').elasticAPM,
  grafana:: (import './grafana.libsonnet').grafana,
  sentry:: (import './sentry.libsonnet').sentry,
  bigquery:: (import './bigquery.libsonnet').bigquery,
  kibana:: (import './kibana.libsonnet').kibana,
  gkeDeployment:: (import './gke_deployment.libsonnet').gkeDeployment,
  googleLoadBalancer: (import './google_load_balancer.libsonnet').googleLoadBalancer,
  generateMarkdown:: generateMarkdown,
}
