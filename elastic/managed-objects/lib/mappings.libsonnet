local mapping(index) =
  local properties = if index == 'rails' then {
    json: {
      properties: {
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
  }
  else if index == 'sidekiq' then {
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
        target_id: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
      },
    },
  }
  else if index == 'gke' then {
    json: {
      properties: {
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
      },
    },
  } else {
  };
  {
    properties: properties,
  };

{
  mapping:: mapping,
}
