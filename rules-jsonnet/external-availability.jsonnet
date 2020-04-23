local serviceCatalog = import 'service_catalog.libsonnet';

local keyServices = serviceCatalog.findServices(function(service)
  std.objectHas(service.business.SLA, 'overall_sla_weighting') && service.business.SLA.overall_sla_weighting > 0);

local externalAvailabilityRatioRule(service, range) =
  {
    record: 'gitlab_service_external_availability:ratio_%s' % [range],
    labels: {
      type: service.name,
      tier: service.tier,
    },
    expr: |||
      avg by (environment) (
        avg_over_time(pingdom_check_status{tags=~".*\\b%(type)s\\b.*"}[%(range)s])
      )
    ||| % { type: service.name, range: range },
  };

local rules = {
  groups: [{
    // External monitoring
    name: 'External monitoring, short interval',
    interval: '1m',
    rules:
      [externalAvailabilityRatioRule(service, '5m') for service in keyServices]
      +
      [externalAvailabilityRatioRule(service, '1h') for service in keyServices],
  }, {
    name: 'External monitoring, long interval',
    interval: '5m',
    rules: [externalAvailabilityRatioRule(service, '1d') for service in keyServices],
  }],
};

{
  'external-availability.yml': std.manifestYamlDoc(rules),
}
