local TRIGGER_SCHEDULE_MINS = 5;  // Run this watcher at this frequency, in minutes

local QUERY_PERIOD_MINS = TRIGGER_SCHEDULE_MINS * 2;

local IGNORE_IPS = [
  '127.0.0.1',
];

local params = {
  time_period_seconds: QUERY_PERIOD_MINS * 60,
  minimum_rate_per_second: 50,
};

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
          {
            range: {
              '@timestamp': {
                gte: std.format('now-%dm', QUERY_PERIOD_MINS),
                lte: 'now',
              },
            },
          },
        ],
        must_not: [
          {
            terms: {
              'json.remote_ip.keyword': IGNORE_IPS,
            },
          },
        ],
      },
    },
    aggs: {
      significant_remote_ips: {
        significant_terms: {
          field: 'json.remote_ip.keyword',
          size: 20,
        },
        aggs: {
          total_duration_s: {
            sum: {
              field: 'json.duration_s',
            },
          },
        },
      },
    },
  },
};

local painlessFunctions = "\n  boolean bucketMatches(def bucket, def params) {\n    (bucket.doc_count / params.time_period_seconds) >= params.minimum_rate_per_second\n  }\n\n  Map bucketTransform(def bucket, def params) {\n    [\n      'key': bucket.key,\n      'count': bucket.doc_count,\n      'total_duration_s_per_second': Math.round(bucket.total_duration_s.value / params.time_period_seconds),\n      'invocation_rate_per_second': Math.round(bucket.doc_count / params.time_period_seconds)\n    ]\n  }\n";

local conditionScript = '\n  ctx.payload.aggregations.significant_remote_ips.buckets.any(bucket -> bucketMatches(bucket, params))\n';

local transformScript = "\n  [\n    'items': ctx.payload.aggregations.significant_remote_ips.buckets\n                .findAll(bucket -> bucketMatches(bucket, params))\n                .collect(bucket -> bucketTransform(bucket, params))\n  ]\n";

local painlessScript(script) = {
  script: {
    inline: painlessFunctions + '\n' + script,
    lang: 'painless',
    params: params,
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
      throttle_period: '10m',
      slack: {
        account: 'gitlab_team',
        message: {
          from: 'ElasticCloud Watcher: rails_scanning_by_ip',
          to: [
            '#alerts-prod-abuse',
          ],
          text: 'Unusual Rail scan activity for an IP has been detected. Click the title of the description to find associated activity in the Rails logs.',
          dynamic_attachments: {
            list_path: 'ctx.payload.items',
            attachment_template: {
              title: 'ip: {{key}}',
              title_link: "https://log.gprd.gitlab.net/app/kibana#/discover?_g=()&_a=(columns:!(json.remote_ip,json.path,json.duration_s,json.status),filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,index:AW5F1e45qthdGjPJueGO,key:json.remote_ip.keyword,negate:!f,type:phrase,value:'{{key}}'),query:(match:(json.remote_ip.keyword:(query:'{{key}}',type:phrase))))),index:AW5F1e45qthdGjPJueGO,interval:auto,query:(match_all:()),sort:!('@timestamp',desc))",
              text: 'Total time in seconds per second: {{total_duration_s_per_second}}s/second\nAverage rate: requests per second {{invocation_rate_per_second}}ops/sec',
            },
          },
        },
      },
    },
  },
}
