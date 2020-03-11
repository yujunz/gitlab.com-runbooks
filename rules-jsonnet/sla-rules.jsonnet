local serviceCatalog = import 'service_catalog.libsonnet';

local keyServices = serviceCatalog.findServices(function(service)
  std.objectHas(service.business.SLA, 'overall_sla_weighting') && service.business.SLA.overall_sla_weighting > 0);

local keyServiceWeights = std.foldl(
  function(memo, item) memo {
    [item.name]: item.business.SLA.overall_sla_weighting,
  }, keyServices, {}
);

local getScoreQuery(weights) =
  local items = [
    'min without(slo) (avg_over_time(slo_observation_status{type="%(type)s"}[5m])) * %(weight)d' % {
      type: type,
      weight: keyServiceWeights[type],
    }
    for type in std.objectFields(weights)
  ];

  std.join('\n  or\n  ', items);

local getWeightQuery(weights) =
  local items = [
    'max without(slo) (clamp_max(clamp_min(slo_observation_status{type="%(type)s"}, 1), 1)) * %(weight)d' % {
      type: type,
      weight: keyServiceWeights[type],
    }
    for type in std.objectFields(weights)
  ];

  std.join('\n  or\n  ', items);

local rules = {
  groups: [{
    name: 'SLA weight calculations',
    interval: '1m',
    rules: [{
      record: 'sla:gitlab:score',
      expr: |||
        sum by (environment, stage) (
          %s
        )
      ||| % [getScoreQuery(keyServiceWeights)],
    }, {
      record: 'sla:gitlab:weights',
      expr: |||
        sum by (environment, stage) (
          %s
        )
      ||| % [getWeightQuery(keyServiceWeights)],
    }],
  }],
};

{
  'sla-rules.yml': std.manifestYamlDoc(rules),
}
