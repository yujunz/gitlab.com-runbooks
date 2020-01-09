// https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7981
local TRIGGER_SCHEDULE_MINS = 5;  // Run this watcher at this frequency, in minutes
local QUERY_PERIOD_MINS = TRIGGER_SCHEDULE_MINS * 4;  // Ensure we definitely catch any
local ALERT_THRESHOLD = 5;  // A small number doesn't warrant alerting, I think.  Tweak this as necessary to ensure useful alerting

local ES_QUERY = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-gke-inf-gprd-*',
  ],
  types: [],
  body: {
    size: 0,
    query: {
      bool: {
        must: [
          { match_phrase_prefix: { 'json.jsonPayload.error': { query: 'read: connection reset by peer' } } },
          { match_phrase_prefix: { 'json.jsonPayload.error': { query: 'gcs: Get https://storage.googleapis.com/' } } },
          { range: { '@timestamp': { gte: std.format('now-%dm', QUERY_PERIOD_MINS), lte: 'now' } } },
        ],
      },
    },
  },
};


{
  trigger: {
    schedule: {
      interval: std.format('%dm', TRIGGER_SCHEDULE_MINS),
    },
  },
  input: {
    search: {
      request: ES_QUERY,
    },
  },
  condition: {
    compare: {
      'ctx.payload.hits.total': {
        gt: ALERT_THRESHOLD,
      },
    },
  },
  actions: {
    'notify-slack': {
      throttle_period: '30m',
      slack: {
        account: 'gitlab_team',
        message: {
          from: 'ElasticCloud Watcher: registry_gcs_connection_resets',
          to: [
            '#alerts-test',
          ],
          text: 'Registry is seeing Connection Resets talking to GCS.  This may indicate an outage is being caused by GCS connectivity',
          attachments: [
            {
              title: 'Registry Connection Resets from GCS',
              text: '{{ctx.payload.hits.total}} GCS connection resets in the last' + QUERY_PERIOD_MINS + 'minutes.',
              color: 'danger',
            },
          ],
        },
      },
    },
  },
}
