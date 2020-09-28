local metricsConfig = import 'metrics-config.libsonnet';
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
    'min without(slo) (avg_over_time(slo_observation_status{type="%(type)s", monitor="global"}[5m])) * %(weight)d' % {
      type: type,
      weight: keyServiceWeights[type],
    }
    for type in std.objectFields(weights)
  ];

  std.join('\n  or\n  ', items);

local getWeightQuery(weights) =
  local items = [
    'max without(slo) (clamp_max(clamp_min(slo_observation_status{type="%(type)s", monitor="global"}, 1), 1)) * %(weight)d' % {
      type: type,
      weight: keyServiceWeights[type],
    }
    for type in std.objectFields(weights)
  ];

  std.join('\n  or\n  ', items);

local rules = {
  groups: [{
    name: 'SLA weight calculations',
    partial_response_strategy: 'warn',
    interval: '1m',
    rules: [{
      // TODO: these are kept for backwards compatability for now
      record: 'sla:gitlab:score',
      expr: |||
        sum by (environment, env, stage) (
          %s
        )
      ||| % [getScoreQuery(keyServiceWeights)],
    }, {
      // TODO: these are kept for backwards compatibility for now
      // See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/309
      record: 'sla:gitlab:weights',
      expr: |||
        sum by (environment, env, stage) (
          %s
        )
      ||| % [getWeightQuery(keyServiceWeights)],
    }, {
      record: 'sla:gitlab:ratio',
      labels: {
        sla_type: 'weighted_v1',
      },
      // Adding a clamp here is a safety precaution. In normal circumstances this should
      // never exceed one. However in incidents such as show,
      // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/11457
      // there are failure modes where this may occur.
      // Having the clamp_max guard clause can help contain the blast radius.
      expr: |||
        clamp_max(
          sla:gitlab:score{monitor="global"} / sla:gitlab:weights{monitor="global"},
          1
        )
      |||,
    }],
  }, {
    name: 'SLA target',
    partial_response_strategy: 'warn',
    interval: '5m',
    rules: [{
      record: 'sla:gitlab:target',
      expr: '%g' % [metricsConfig.slaTarget],
    }],
  }],
};

{
  'sla-rules.yml': std.manifestYamlDoc(rules),
}
