local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

{
  // Creates a google load balancers component
  // for monitoring a load balancer via stackdriver metrics
  // loadBalancerName: the name of the load balancer
  // projectId: the Google ProjectID that the load balancer is declared in
  googleLoadBalancer(loadBalancerName, projectId)::
    local baseSelector = { target_proxy_name: loadBalancerName, project_id: projectId };

    metricsCatalog.componentDefinition({
      requestRate: rateMetric(
        counter='stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='stackdriver_https_lb_rule_loadbalancing_googleapis_com_https_request_count',
        selector=baseSelector { response_code_class: '500' },
      ),

      significantLabels: ['proxy_continent', 'response_code'],

      toolingLinks: [
        toolingLinks.googleLoadBalancer(
          instanceId=loadBalancerName,
          project=projectId
        ),
      ],
    }),
}
