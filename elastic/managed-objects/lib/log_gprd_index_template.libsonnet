local mappings = import 'mappings.libsonnet';

{
  get(
    index,
    env,
  ):: {
    index_patterns: ['pubsub-%s-inf-%s-*' % [index, env]],


    settings: {
      index: {
        lifecycle: {
          name: 'gitlab-infra-ilm-policy',
          rollover_alias: 'pubsub-%s-inf-%s' % [index, env],
        },
        mapping: {
          ignore_malformed: true,
          total_fields: {
            limit: 10000,
          },
        },
        routing: {
          allocation: {
            total_shards_per_node: 2,
          },
        },
      },
      number_of_shards: 6,
      // number_of_replicas: 1,
    },

    mappings: mappings.mapping(index),
  },
}
