local TRIGGER_SCHEDULE_HOURS = 24;  // Run this watcher once a day

local P95_THRESHOLD_MILLIS = 10000;  // Minimum p95 on which to report

local query() = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-rails-inf-gprd*',
  ],
  types: [],
  body: {
    query: {
      bool: {
        must: [{
          range: {
            "@timestamp": {
              gte: std.format('now-%dh', TRIGGER_SCHEDULE_HOURS),
              lte: "now",
            },
          },
        }],
      },
    },
    size: 0,
    aggs: {
      route: {
        terms: {
          field: "json.route.keyword",
          size: 50,
          order: {
            sum_duration: "desc",
          },
        },
        aggs: {
          sum_duration: {
            sum: {
              field: "json.duration",
            },
          },
          percentile_durations: {
            percentiles: {
              field: "json.duration",
              percents: [95],
              keyed: false,
            },
          },
        },
      },
    },
  },
};

local painlessFunctions = "
  boolean findRoute(def routeBucket, def params) {
    routeBucket.percentile_durations.values[0].value >= params.P95_THRESHOLD_MILLIS
  }
";

local conditionScript = "
  ctx.payload.aggregations.route.buckets.any(routeBucket -> findRoute(routeBucket, params))
";

local transformScript = "
  [
    'items': ctx.payload.aggregations.route.buckets.findAll(routeBucket -> findRoute(routeBucket, params))
      .collect(routeBucket -> [
        'routeKey': routeBucket.key,
        'p95latencySeconds': Math.round(routeBucket.percentile_durations.values[0].value/1000),
        'issue_search_url': 'https://gitlab.com/gitlab-org/gitlab/issues?scope=all&state=all&label_name[]=Mechanical%20Sympathy&search=' + routeBucket.key
      ])
  ]
";

local painlessScript(script) = {
  script: {
    inline: painlessFunctions + "\n" + script,
    lang: "painless",
    params: {
      P95_THRESHOLD_MILLIS: P95_THRESHOLD_MILLIS,
    },
  },
};

local searchLinkTemplate() =
  "https://log.gitlab.net/app/kibana#/discover?_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-24h,mode:quick,to:now))&_a=(columns:!(json.route,json.duration,json.path,json.status),filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,index:AWOSvARQwig0Nc2UGcr2,key:json.route.keyword,negate:!f,type:phrase,value:'{{routeKey}}'),query:(match:(json.route.keyword:(query:'{{routeKey}}',type:phrase))))),index:AWOSvARQwig0Nc2UGcr2,interval:auto,query:(match_all:()),sort:!(json.duration,desc))";

{
  trigger: {
    schedule: {
      interval: std.format('%dh', TRIGGER_SCHEDULE_HOURS),
    },
  },
  input: {
    search: {
      request: query(),
    },
  },
  condition: painlessScript(conditionScript),
  transform: painlessScript(transformScript),
  actions: {
    "notify-slack": {
      slack: {
        account: "gitlab_team",
        message: {
          from: "ElasticCloud Watcher: worst-case p95",
          to: [
            "#mech_symp_alerts",
          ],
          text: "*Worst performing Rails API routes in the applications, by p95 latency*
Click through the attachment title to find events in the logs...",
          dynamic_attachments: {
            list_path: "ctx.payload.items",
            attachment_template: {
              title: "{{routeKey}}",
              title_link: searchLinkTemplate(),
              text: "p95 latency for this route: {{ p95latencySeconds }}s (<{{ issue_search_url }}|find related issues>)",
            },
          },
        },
      },
    },
  },
}
