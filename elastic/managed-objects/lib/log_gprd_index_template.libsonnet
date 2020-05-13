local mappings = import 'mappings.libsonnet';
local settings = import 'settings.libsonnet';

{
  get(
    index,
    env,
  ):: {
    index_patterns: ['pubsub-%s-inf-%s-*' % [index, env]],
    mappings: mappings.mapping(index),
    settings: settings.setting(index, env),
  },
}
