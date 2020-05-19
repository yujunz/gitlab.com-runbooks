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
        response: {
          // this is being migrated to a string jira_response field.
          // it was creating a lot of dynamic fields, producing mapping updates
          // which put load on the ES master for metadata updates.
          //
          // see also: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31910
          enabled: false,
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
        retry: {
          type: 'long',
        },
        retry_count: {
          type: 'long',
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
  else if index == 'runner' then {
    json: {
      properties: {
        project: {
          // this field was defaulting to float
          // performing a search on a flot was not returning expected results
          // e.g. searching for 17066052 returns 17066051 and 17066053
          // converting to long to avoid that
          // see: https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/9303
          type: 'long',
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
