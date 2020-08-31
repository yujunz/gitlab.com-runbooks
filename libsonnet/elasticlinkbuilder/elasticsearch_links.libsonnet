local rison = import 'rison.libsonnet';

local kibanaEndpoint = 'https://log.gprd.gitlab.net/app/kibana';

local kueryFilter(field, value) =
  {
    language: 'kuery',
    query: '%s:%s' % [field, value],
  };

// Builds an ElasticSearch match filter clause
local matchFilter(field, value) =
  {
    query: {
      match: {
        [field]: {
          query: value,
          type: 'phrase',
        },
      },

    },
  };

// Builds an ElasticSearch range filter clause
local rangeFilter(field, gteValue, lteValue) =
  {
    query: {
      range: {
        [field]: {
          [if gteValue != null then 'gte']: gteValue,
          [if lteValue != null then 'lte']: lteValue,
        },
      },
    },
  };

local existsFilter(field) =
  {
    exists: {
      field: field,
    },
  };

local mustNot(filter) =
  filter {
    meta+: {
      negate: true,
    },
  };

local statusCode(field) =
  [rangeFilter(field, gteValue=500, lteValue=null)];

local indexCatalog = {
  // Improve these logs when https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/11221 is addressed
  camoproxy: {
    timestamp: '@timestamp',
    indexId: 'AWz5hIoSGphUgZwzAG7q',
    defaultColumns: ['json.camoproxy_message', 'json.camoproxy_err'],
    failureFilter: [existsFilter('json.camoproxy_err')],
    //defaultLatencyField: 'json.grpc.time_ms',
    //latencyFieldUnitMultiplier: 1000,
  },

  gitaly: {
    timestamp: 'json.time',
    indexId: 'AW5F1OHTiGcMMNRn84Di',
    defaultColumns: ['json.hostname', 'json.grpc.method', 'json.grpc.request.glProjectPath', 'json.grpc.code', 'json.grpc.time_ms'],
    failureFilter: [mustNot(matchFilter('json.grpc.code', 'OK')), existsFilter('json.grpc.code')],
    defaultLatencyField: 'json.grpc.time_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  monitoring: {
    timestamp: '@timestamp',
    indexId: 'AW5ZoH2ddtvLTaJbch2P',
    defaultColumns: ['json.hostname', 'json.msg', 'json.level'],
    failureFilter: [matchFilter('json.level', 'error')],
  },

  pages: {
    timestamp: 'json.time',
    indexId: 'AWRaEscWMdvjVyaYlI-L',
    defaultColumns: ['json.hostname', 'json.pages_domain', 'json.host', 'json.pages_host', 'json.path', 'json.remote_ip', 'json.duration_ms'],
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  postgres: {
    timestamp: '@timestamp',
    indexId: 'AWM6iZV51NBBQZg_DR-U',
    defaultColumns: ['json.hostname', 'json.application_name', 'json.error_severity', 'json.message', 'json.session_start_time', 'json.sql_state_code', 'json.duration_ms'],
    defaultLatencyField: 'json.duration_ms',  // Only makes sense in the context of slowlog entries
    latencyFieldUnitMultiplier: 1000,
  },

  postgres_pgbouncer: {
    timestamp: 'json.time',
    indexId: 'AWM6iZV51NBBQZg_DR-U',
    defaultColumns: ['json.hostname', 'json.pg_message'],
  },

  praefect: {
    timestamp: 'json.time',
    indexId: 'AW98WAQvqthdGjPJ8jTY',
    defaultColumns: ['json.hostname', 'json.virtual_storage', 'json.grpc.method', 'json.relative_path', 'json.grpc.code', 'json.grpc.time_ms'],
    failureFilter: [mustNot(matchFilter('json.grpc.code', 'OK')), existsFilter('json.grpc.code')],
    defaultLatencyField: 'json.grpc.time_ms',
    latencyFieldUnitMultiplier: 1000,
  },

  rails: {
    timestamp: 'json.time',
    indexId: 'AW5F1e45qthdGjPJueGO',
    defaultColumns: ['json.method', 'json.status', 'json.controller', 'json.action', 'json.path', 'json.duration_s'],
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_s',
    latencyFieldUnitMultiplier: 1,
  },

  rails_api: {
    timestamp: 'json.time',
    indexId: 'AW5F1e45qthdGjPJueGO',
    defaultColumns: ['json.method', 'json.status', 'json.route', 'json.path', 'json.duration_s'],
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_s',
    latencyFieldUnitMultiplier: 1,
  },

  redis: {
    timestamp: 'json.time',
    indexId: 'AWSQX_Vf93rHTYrsexmk',
    defaultColumns: ['json.hostname', 'json.redis_message'],
    defaultLatencyField: 'json.exec_time',  // Note: this is only useful in the context of slowlogs
    latencyFieldUnitMultiplier: 1000000,  // Redis uses us
  },

  registry: {
    timestamp: 'json.time',
    indexId: '97ce8e90-63ad-11ea-8617-2347010d3aab',
    defaultColumns: ['json.http.request.uri', 'json.http.response.duration', 'json.err.code', 'json.msg', 'json.http.response.status'],
    failureFilter: statusCode('json.http.response.status'),
    // Requires https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/11136
    // defaultLatencyField: 'json.duration_s',
    // latencyFieldUnitMultiplier: 1,
  },

  runners: {
    timestamp: '@timestamp',
    indexId: 'AWgzayS3ENm-ja4G1a8d',
    defaultColumns: ['json.operation', 'json.job', 'json.operation', 'json.repo_url', 'json.project', 'json.msg'],
    failureFilter: [matchFilter('json.msg', 'failed')],
    defaultLatencyField: 'json.duration',
    latencyFieldUnitMultiplier: 1000000000,  // nanoseconds, ah yeah
  },

  shell: {
    timestamp: 'json.time',
    indexId: 'AWORyp9K1NBBQZg_dXA9',
    defaultColumns: ['json.command', 'json.msg', 'json.level', 'json.gl_project_path', 'json.error'],
    failureFilter: [matchFilter('json.level', 'error')],
  },

  sidekiq: {
    timestamp: 'json.time',
    indexId: 'AWNABDRwNDuQHTm2tH6l',
    defaultColumns: ['json.class', 'json.queue', 'json.job_status', 'json.scheduling_latency_s', 'json.duration_s'],
    failureFilter: [matchFilter('json.job_status', 'fail')],
    defaultLatencyField: 'json.duration_s',
    latencyFieldUnitMultiplier: 1,
  },

  workhorse: {
    timestamp: 'json.time',
    indexId: 'AWM6itvP1NBBQZg_ElD1',
    defaultColumns: ['json.method', 'json.remote_ip', 'json.status', 'json.uri', 'json.duration_ms'],
    failureFilter: statusCode('json.status'),
    defaultLatencyField: 'json.duration_ms',
    latencyFieldUnitMultiplier: 1000,
  },
};

local buildElasticDiscoverSearchQueryURL(index, filters, query='') =
  local applicationState = {
    columns: indexCatalog[index].defaultColumns,
    filters: filters,
    index: indexCatalog[index].indexId,
    query: query,
  };

  kibanaEndpoint + '#/discover?_a=' + rison.encode(applicationState) + '&_g=(time:(from:now-1h,to:now))';

local buildElasticLineCountVizURL(index, filters) =
  local ic = indexCatalog[index];

  local applicationState = {
    filters: filters,
    vis: {
      aggs: [
        {
          enabled: true,
          id: '1',
          params: {},
          schema: 'metric',
          type: 'count',
        },
        {
          enabled: true,
          id: '2',
          params: {
            drop_partials: true,
            extended_bounds: {},
            field: ic.timestamp,
            interval: 'auto',
            min_doc_count: 1,
            scaleMetricValues: false,
            timeRange: {
              from: 'now-1h',
              to: 'now',
            },
            useNormalizedEsInterval: true,
          },
          schema: 'segment',
          type: 'date_histogram',
        },
      ],
    },
  };

  kibanaEndpoint + '#/visualize/create?type=line&indexPattern=' + indexCatalog[index].indexId + '&_a=' + rison.encode(applicationState) + '&_g=(time:(from:now-1h,to:now))';

local buildElasticLinePercentileVizURL(index, filters, field) =
  local ic = indexCatalog[index];

  local applicationState = {
    filters: filters,
    vis: {
      aggs: [
        {
          enabled: true,
          id: '1',
          params: {
            field: field,
            percents: [50, 95, 99],  // Fix percentiles for now
          },
          schema: 'metric',
          type: 'percentiles',
        },
        {
          enabled: true,
          id: '2',
          params: {
            drop_partials: true,
            extended_bounds: {},
            field: ic.timestamp,
            interval: 'auto',
            min_doc_count: 1,
            scaleMetricValues: false,
            timeRange: {
              from: 'now-1h',
              to: 'now',
            },
            useNormalizedEsInterval: true,
          },
          schema: 'segment',
          type: 'date_histogram',
        },
      ],
    },
  };

  kibanaEndpoint + '#/visualize/create?type=line&indexPattern=' + indexCatalog[index].indexId + '&_a=' + rison.encode(applicationState) + '&_g=(time:(from:now-1h,to:now))';

{
  matchFilter:: matchFilter,
  rangeFilter:: rangeFilter,
  kueryFilter:: kueryFilter,

  // Given an index, and a set of filters, returns a URL to a Kibana discover module/search
  buildElasticDiscoverSearchQueryURL(index, filters, query='')::
    buildElasticDiscoverSearchQueryURL(index, filters, query),

  // Search for failed requests
  buildElasticDiscoverFailureSearchQueryURL(index, filters)::
    buildElasticDiscoverSearchQueryURL(
      index,
      filters + indexCatalog[index].failureFilter
    ),

  // Search for requests taking longer than the specified number of seconds
  buildElasticDiscoverSlowRequestSearchQueryURL(index, filters, slowRequestSeconds)::
    local ic = indexCatalog[index];
    buildElasticDiscoverSearchQueryURL(
      index,
      filters + [rangeFilter(ic.defaultLatencyField, gteValue=slowRequestSeconds * ic.latencyFieldUnitMultiplier, lteValue=null)]
    ),

  // Given an index, and a set of filters, returns a URL to a Kibana count visualization
  buildElasticLineCountVizURL(index, filters)::
    buildElasticLineCountVizURL(index, filters),

  buildElasticLineFailureCountVizURL(index, filters)::
    buildElasticLineCountVizURL(
      index,
      filters + indexCatalog[index].failureFilter
    ),

  // Given an index, and a set of filters, returns a URL to a Kibana percentile visualization
  buildElasticLinePercentileVizURL(index, filters, field=null)::
    local fieldWithDefault = if field == null then
      indexCatalog[index].defaultLatencyField
    else
      field;
    buildElasticLinePercentileVizURL(index, filters, fieldWithDefault),

  // Returns true iff the named index supports failure queries
  indexSupportsFailureQueries(index)::
    std.objectHas(indexCatalog[index], 'failureFilter'),

  // Returns true iff the named index supports latency queries
  indexSupportsLatencyQueries(index)::
    std.objectHas(indexCatalog[index], 'defaultLatencyField'),


}
