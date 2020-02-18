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
          total_fields: {
            limit: 10000,
          },
        },
      },
      number_of_shards: 2,
      // number_of_replicas: 1,
    },


    mappings: {
      properties: {
        json: {
          properties: {
            args: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            db: {
              type: 'float',
            },
            target_id: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            jsonPayload: {
              properties: {
                err: {
                  properties: {
                    detail: {
                      // json.jsonPayload.err.detail, emitted by docker registry
                      // pods (currently in the GKE index), is irregularly
                      // formed: sometimes it's a string, sometimes a json. We
                      // must skip processing entirely to avoid dropping some
                      // logs, and view this field in _source only.
                      enabled: false,
                    },
                  },
                },
              },
            },
            extra: {
              properties: {
                sidekiq: {
                  properties: {
                    args: {
                      type: 'text',
                    },
                    retry: {
                      type: 'text',
                    },
                  },
                },
              },
            },
            user_id: {
              type: 'long',
            },
          },
        },
      },
    },
  },
}
