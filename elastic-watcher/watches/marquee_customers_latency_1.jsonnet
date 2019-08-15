

local TRIGGER_SCHEDULE_MINS = 30; // Run this watcher at this frequency, in minutes
local QUERY_PERIOD_MINS = 30;
local P95_ALERT_THRESHOLD_LATENCY_SECONDS = 3;
local MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS = std.extVar('marquee_customers_top_level_domains');

local wildcardQueries() =  [
  {
    wildcard: {
      "json.uri.keyword": "/" + topLevelDomain + "/*"
    }
  } for topLevelDomain in std.split(MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS, ",")
];

local ES_QUERY = {
  search_type: "query_then_fetch",
  indices: [
    "pubsub-workhorse-inf-gprd-*"
  ],
  types: [],
  body: {
    size: 0,
    query: {
      bool: {
        must: [
          {
            range: {
              "@timestamp": {
                gte: std.format("now-%dm", QUERY_PERIOD_MINS),
                lte: "now"
              }
            }
          },
          {
            match_phrase: {
              "json.hostname": "web"
            }
          }
        ],
        should: wildcardQueries(),
        minimum_should_match: 1
      }
  },
  aggs: {
    percentile_durations: {
          percentiles: {
            field: "json.duration_ms",
            percents: [
              95.0
            ],
            keyed: false
          }
        }
    }
  }
};

{
  trigger: {
    schedule: {
      interval: std.format("%dm", TRIGGER_SCHEDULE_MINS)
    }
  },
  input: {
    search: {
      request: ES_QUERY
    }
  },
  condition: {
    compare: {
      "ctx.payload.aggregations.percentile_durations.values.0.value": {
        gte: P95_ALERT_THRESHOLD_LATENCY_SECONDS * 1000 /* Convert to milliseconds */
      }
    }
  },
  actions: {
    "notify-slack": {
      throttle_period: "1m",
      slack: {
        account: "gitlab_team",
        message: {
          from: "ElasticCloud Watcher: marquee-customers latency alert",
          to: [
            "#marquee_account_alrts"
          ],
          text: "Marquee customers latency alert",
          attachments : [
          {
            title : "Latency issues detected",
            text : "Marquee customer accounts experiencing a p95 latency of {{ctx.payload.aggregations.percentile_durations.values.0.value}}ms. <https://log.gitlab.net/goto/a28ff15a4609fdcb93e128c94263edb2>",
            color : "danger"
          }]
        }
      }
    }
  }
}
