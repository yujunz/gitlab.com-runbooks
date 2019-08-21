local TRIGGER_SCHEDULE_HOURS = 24;  // Run this watcher once a day

local GITALY_CALLS_THRESHOLD = 750; // This many Gitaly calls in a single request triggers an alert

local query(keyField) = {
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
              lte: "now"
            }
          }
        }]
      }
    },
    size: 0,
    aggs: {
      controller: {
        terms: {
          field: keyField + '.keyword',
          size: 10,
          order: {
            max_gitaly_calls: "desc"
          }
        },
        aggs: {
          max_gitaly_calls: {
            max: {
              field: "json.gitaly_calls"
            }
          }
        }
      }
    }
  },
};

local painlessFunctions = "
  boolean findController(def controllerBucket, def params) {
    controllerBucket.max_gitaly_calls.value >= params.GITALY_CALLS_THRESHOLD
  }
";

local conditionScript = "
  ctx.payload.aggregations.controller.buckets.any(controllerBucket -> findController(controllerBucket, params))
";

local transformScript = "
  [
    'items': ctx.payload.aggregations.controller.buckets.findAll(controllerBucket -> findController(controllerBucket, params))
  ]
";

local painlessScript(script) = {
  script : {
    inline : painlessFunctions + "\n" + script,
    lang : "painless",
    params : {
      GITALY_CALLS_THRESHOLD: GITALY_CALLS_THRESHOLD
    }
  }
};

local searchLinkTemplate(keyField) =
  "https://log.gitlab.net/app/kibana#/discover?_g=(refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-24h,mode:quick,to:now))&_a=(columns:!(json.controller,json.action,json.route,json.duration,json.path,json.remote_ip,json.username,json.gitaly_calls),filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,index:AWOSvARQwig0Nc2UGcr2,key:" + keyField + ".keyword,negate:!f,type:phrase,value:'{{ key }}'),query:(match:(" + keyField + ".keyword:(query:'{{ key }}',type:phrase))))),index:AWOSvARQwig0Nc2UGcr2,interval:auto,query:(match_all:()),sort:!(json.gitaly_calls,desc))";

{
  alert(
    name,
    keyField,
  ):: {
    trigger: {
      schedule: {
        interval: std.format('%dh', TRIGGER_SCHEDULE_HOURS),
      },
    },
    input: {
      search: {
        request: query(keyField),
      },
    },
    condition: painlessScript(conditionScript),
    transform: painlessScript(transformScript),
    actions: {
      "notify-slack": {
        slack: {
          account: "gitlab_team",
          message: {
            from: "ElasticCloud Watcher: " + name,
            to: [
              "#mech_symp_alerts"
            ],
            text: "*Gitaly n+1 issues detected in the following endpoints.*
Click through to find events...",
            dynamic_attachments: {
              list_path: "ctx.payload.items",
              attachment_template: {
                title: "{{key}}",
                title_link: searchLinkTemplate(keyField),
                text: "Maximum Gitaly calls in a single request: {{ max_gitaly_calls.value }}."
              }
            }
          }
        }
      }
    },
  }
}
