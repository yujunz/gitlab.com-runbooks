local TRIGGER_SCHEDULE_MINS = 60;  // Run this watcher at this frequency, in minutes
local QUERY_PERIOD_MINS = 70;
local OOM_ALERT_THRESHOLD = 3;

local ES_QUERY = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-system-inf-gprd-*',
  ],
  types: [],
  body: {
    size: 0,
    query: {
      bool: {
        must: [
          { match_phrase: { 'json.message': { query: 'oom_score_adj' } } },
          { match_phrase: { 'json.message': { query: 'oom-killer' } } },
          { range: { '@timestamp': { gte: std.format('now-%dm', QUERY_PERIOD_MINS), lte: 'now' } } },
        ],
      },
    },
    aggs: {
      fqdn: { terms: { field: 'json.fqdn.keyword', size: 10, order: { _count: 'desc' } } },
    },
  },
};

local painlessFunctions = '\n  boolean bucketMatches(def bucket, def params) {\n    bucket.doc_count >= params.OOM_ALERT_THRESHOLD\n  }\n';

local conditionScript = '\n  ctx.payload.aggregations.fqdn.buckets.any(bucket -> bucketMatches(bucket, params))\n';

local transformScript = "\n  [\n    'items': ctx.payload.aggregations.fqdn.buckets\n                .findAll(bucket -> bucketMatches(bucket, params))\n  ]\n";

local painlessScript(script) = {
  script: {
    inline: painlessFunctions + '\n' + script,
    lang: 'painless',
    params: {
      OOM_ALERT_THRESHOLD: OOM_ALERT_THRESHOLD,
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
  condition: painlessScript(conditionScript),
  transform: painlessScript(transformScript),
  actions: {
    'notify-slack': {
      throttle_period: '30m',
      slack: {
        account: 'gitlab_team',
        message: {
          from: 'ElasticCloud Watcher: oom_watcher',
          to: [
            '#mech_symp_alerts',
          ],
          text: 'Multiple OOM-events detected on nodes. Visit https://log.gitlab.net/goto/fedfb6a8e169bac2f1dfccdadda0caa5 for more details',
          dynamic_attachments: {
            list_path: 'ctx.payload.items',
            attachment_template: {
              title: 'node: {{key}}',
              text: 'OOM-Events: {{ doc_count }}',
            },
          },
        },
      },
    },
  },
}
