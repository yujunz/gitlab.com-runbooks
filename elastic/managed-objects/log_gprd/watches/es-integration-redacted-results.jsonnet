local TRIGGER_SCHEDULE_MINS = 5;  // Run this watcher at this frequency, in minutes
local QUERY_PERIOD_MINS = 120;
local ALERT_THRESHOLD = 0;

local ES_QUERY = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd-*',
  ],
  types: [],
  body: {
    size: 0,
    query: {
      bool: {
        must: [
          { match_phrase: { 'json.message': { query: 'redacted_search_results' } } },
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
      throttle_period: '120m',
      slack: {
        message: {
          from: 'ElasticCloud Watcher: es-integration-redacted-results',
          to: [
            '#alerts-test',
          ],
          text: 'Search results from the ES integration were redacted. Visit https://log.gprd.gitlab.net/goto/40f98515a7e26975caf5f102baaea8d7 for more details',
        },
      },
    },
  },
}