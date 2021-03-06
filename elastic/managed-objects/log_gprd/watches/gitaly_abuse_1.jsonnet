local TRIGGER_SCHEDULE_MINS = 5;  // Run this watcher at this frequency, in minutes

local QUERY_PERIOD_MINS = TRIGGER_SCHEDULE_MINS * 2;

local IGNORE_REPOS = [
  'gitlab-org/gitlab-foss',
  'gitlab-org/gitlab',
  'gitlab-com/www-gitlab-com',
];

local params = {
  time_period_seconds: QUERY_PERIOD_MINS * 60,
  wall_time_ms_per_second_threshold: 4000,
  minimum_invocation_rate_per_second: 10,
  invocation_rate_per_second_threshold: 100,
};

local ES_QUERY = {
  search_type: 'query_then_fetch',
  indices: [
    'pubsub-gitaly-inf-gprd-*',
  ],
  types: [],
  body: {
    size: 0,
    query: {
      bool: {
        must: [
          {
            match_phrase: {
              'json.grpc.code.keyword': {
                query: 'OK',
              },
            },
          },
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
              'json.grpc.request.glProjectPath.keyword': IGNORE_REPOS,
            },
          },
        ],
      },
    },
    aggs: {
      significant_repos: {
        significant_terms: {
          field: 'json.grpc.request.glProjectPath.keyword',
          size: 3,
        },
        aggs: {
          fqdn: {
            top_hits: {
              docvalue_fields: [
                'json.fqdn.keyword',
              ],
              _source: 'json.fqdn.keyword',
              size: 1,
            },
          },
          wall_time_ms: {
            sum: {
              field: 'json.grpc.time_ms',
            },
          },
        },
      },
    },
  },
};

local painlessFunctions = "\n  boolean bucketMatches(def bucket, def params) {\n    (\n      (bucket.doc_count / params.time_period_seconds) >= params.minimum_invocation_rate_per_second\n    )\n    &&\n    (\n      ((bucket.wall_time_ms.value / params.time_period_seconds) >= params.wall_time_ms_per_second_threshold)\n      ||\n      ((bucket.doc_count / params.time_period_seconds) >= params.invocation_rate_per_second_threshold)\n    )\n  }\n\n  Map bucketTransform(def bucket, def params) {\n    [\n      'key': bucket.key,\n      'count': bucket.doc_count,\n      'wall_time_ms_per_second': Math.round(bucket.wall_time_ms.value / params.time_period_seconds),\n      'invocation_rate_per_second': Math.round(bucket.doc_count / params.time_period_seconds),\n      'fqdn': bucket.fqdn.hits.hits[0].fields['json.fqdn.keyword'][0]\n    ]\n  }\n";

local conditionScript = '\n  ctx.payload.aggregations.significant_repos.buckets.any(bucket -> bucketMatches(bucket, params))\n';

local transformScript = "\n  [\n    'items': ctx.payload.aggregations.significant_repos.buckets\n                .findAll(bucket -> bucketMatches(bucket, params))\n                .collect(bucket -> bucketTransform(bucket, params))\n  ]\n";

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
          from: 'ElasticCloud Watcher: gitaly_abuse_1',
          to: [
            '#alerts-prod-abuse',
          ],
          text: 'Unusual Gitaly activity for a project has been detected. Review the runbook at https://gitlab.com/gitlab-com/runbooks/tree/master/docs/gitaly/gitaly-unusual-activity.md for more details',
          dynamic_attachments: {
            list_path: 'ctx.payload.items',
            attachment_template: {
              title: 'Project: {{key}}',
              title_link: "https://log.gprd.gitlab.net/app/kibana#/visualize/create?type=line&indexPattern=AW5F1OHTiGcMMNRn84Di&_g=(filters:!(('$state':(store:globalState),exists:(field:json.grpc.code),meta:(alias:!n,disabled:!f,index:AW5F1OHTiGcMMNRn84Di,key:json.grpc.code,negate:!f,type:exists,value:exists)),('$state':(store:globalState),meta:(alias:!n,disabled:!f,index:AW5F1OHTiGcMMNRn84Di,key:json.grpc.request.glProjectPath.keyword,negate:!f,type:phrase,value:'{{ key }}'),query:(match:(json.grpc.request.glProjectPath.keyword:(query:'{{ key }}',type:phrase))))),refreshInterval:(display:Off,pause:!f,value:0),time:(from:now-4h,mode:quick,to:now))&_a=(filters:!(),linked:!f,query:(match_all:()),uiState:(),vis:(aggs:!((enabled:!t,id:'1',params:(customLabel:operations),schema:metric,type:count),(enabled:!t,id:'2',params:(customInterval:'2h',extended_bounds:(),field:json.time,interval:auto,min_doc_count:1),schema:segment,type:date_histogram),(enabled:!t,id:'3',params:(customLabel:'total+call+time',field:json.grpc.time_ms),schema:metric,type:sum)),listeners:(),params:(addLegend:!t,addTimeMarker:!f,addTooltip:!t,categoryAxes:!((id:CategoryAxis-1,labels:(show:!t,truncate:100),position:bottom,scale:(type:linear),show:!t,style:(),title:(text:'json.time+per+5+minutes'),type:category)),grid:(categoryLines:!f,style:(color:%23eee)),legendPosition:right,seriesParams:!((data:(id:'1',label:operations),drawLinesBetweenPoints:!t,mode:normal,show:true,showCircles:!t,type:line,valueAxis:ValueAxis-1),(data:(id:'3',label:'total+call+time'),drawLinesBetweenPoints:!t,mode:normal,show:!t,showCircles:!t,type:line,valueAxis:ValueAxis-2)),times:!(),type:line,valueAxes:!((id:ValueAxis-1,labels:(filter:!f,rotate:0,show:!t,truncate:100),name:LeftAxis-1,position:left,scale:(mode:normal,type:linear),show:!t,style:(),title:(text:operations),type:value),(id:ValueAxis-2,labels:(filter:!f,rotate:0,show:!t,truncate:100),name:RightAxis-1,position:right,scale:(mode:normal,type:linear),show:!t,style:(),title:(text:'total+call+time'),type:value))),title:'New+Visualization',type:line))",
              text: 'File Server: <https://dashboards.gitlab.net/d/000000204/gitaly-nfs-metrics-per-host?orgId=1&var-fqdn={{fqdn}}&from=now-1h&to=now|{{fqdn}}>\nAverage Gitaly Wall time: {{wall_time_ms_per_second}}ms/second\nAverage rate: invocations per second {{invocation_rate_per_second}}ops/sec',
            },
          },
        },
      },
    },
  },
}
