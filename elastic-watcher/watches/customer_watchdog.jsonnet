

local TRIGGER_SCHEDULE_MINS = 30; // Run this watcher at this frequency, in minutes
local QUERY_PERIOD_MINS = 30;
local P95_ALERT_THRESHOLD_LATENCY_SECONDS = 3;
local GOLD_WATCH_TOP_LEVEL_DOMAINS = std.extVar('gold_watch_top_level_domains');

local wildcardQueries() =  [
  {
    wildcard: {
      "json.uri.keyword": "/" + topLevelDomain + "/*"
    }
  } for topLevelDomain in std.split(GOLD_WATCH_TOP_LEVEL_DOMAINS, ",")
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
            field: "json.duration",
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
        gte: P95_ALERT_THRESHOLD_LATENCY_SECONDS
      }
    }
  },
  actions: {
    "notify-slack": {
      throttle_period: "1m",
      slack: {
        account: "gitlab_team",
        message: {
          from: "ElasticCloud Watcher: gold-watch",
          to: [
            "#gold-watch"
          ],
          text: "Gold-watch: Customer watchdog alert",
          attachments : [
          {
            title : "Latency issues detected",
            text : "Canary customer accounts experiencing a p95 latency of {{ctx.payload.aggregations.percentile_durations.values.0.value}}s. <https://log.gitlab.net/goto/9128cfe7e30f58716af9e63fac492ca8>",
            color : "danger"
          }]
        }
      }
    }
  }
}
