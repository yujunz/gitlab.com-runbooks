local TRIGGER_SCHEDULE_MINS = 5;  // Run this watch at this frequency, in minutes
local QUERY_PERIOD_MINS = 120;
local ALERT_THRESHOLD = 0;

local ES_QUERY = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-workhorse-inf-gprd-*',
  ],
  types: [],
  body: {
    size: 0,
    query: {
      bool: {
        must: [
          { match_phrase: { 'json.msg': { query: 'error' } } },
          { match_phrase: { 'json.uri': { query: 'gitlab-lfs' } } },
          { match_phrase: { 'json.message': { query: 'stale' } } },
          { range: { '@timestamp': { gte: std.format('now-%dm', QUERY_PERIOD_MINS), lte: 'now' } } },  // timestamp is used here rather than json.time on purpose
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
      throttle_period: QUERY_PERIOD_MINS + 'm',
      slack: {
        message: {
          from: 'ElasticCloud Watcher: stale nfs',
          to: [
            '#alerts-test',
          ],
          text: 'Stale nfs errors were detected. Please investigate this further. See: https://gitlab.com/gitlab-org/gitlab/issues/32718#note_233384831 and https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/8227 for more information.',
        },
      },
    },
  },
}
