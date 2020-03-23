local rison = import 'rison.libsonnet';

local indexes = {
  workhorse: 'AWM6itvP1NBBQZg_ElD1',
  rails: 'AW5F1e45qthdGjPJueGO',
  sidekiq: 'AWNABDRwNDuQHTm2tH6l',
};

local kibanaEndpoint = 'https://log.gprd.gitlab.net/app/kibana';

local defaultColumns = {
  workhorse: ['json.method', 'json.remote_ip', 'json.status', 'json.uri', 'json.duration_ms'],
  rails: ['json.method', 'json.status', 'json.controller', 'json.action', 'json.path', 'json.duration'],
  sidekiq: ['json.class', 'json.queue', 'json.job_status', 'json.scheduling_latency_s', 'json.duration'],
};

local buildElasticDiscoverSearchQueryURL(index, filters) =
  local applicationState = {
    columns: defaultColumns[index],
    filters: [
      {
        query: f,
      }
      for f in filters
    ],
    index: indexes[index],
  };

  kibanaEndpoint + '#/discover?_a=' + rison.encode(applicationState);

local buildElasticLineCountVizURL(index, filters) =
  local applicationState = {
    filters: [
      {
        query: f,
      }
      for f in filters
    ],
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
            field: 'json.time',
            interval: 'auto',
            min_doc_count: 1,
            scaleMetricValues: false,
            timeRange: {
              from: 'now-30m',
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

  kibanaEndpoint + '#/visualize/create?type=line&indexPattern=' + indexes[index] + '&_a=' + rison.encode(applicationState);

local buildElasticLinePercentileVizURL(index, filters, field) =
  local applicationState = {
    filters: [
      {
        query: f,
      }
      for f in filters
    ],
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
            field: 'json.time',
            interval: 'auto',
            min_doc_count: 1,
            scaleMetricValues: false,
            timeRange: {
              from: 'now-30m',
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

  kibanaEndpoint + '#/visualize/create?type=line&indexPattern=' + indexes[index] + '&_a=' + rison.encode(applicationState);

{
  // Builds an ElasticSearch match filter clause
  matchFilter(field, value)::
    {
      match: {
        [field]: {
          query: value,
          type: 'phrase',
        },
      },
    },

  // Given an index, and a set of filters, returns a URL to a Kibana discover module/search
  buildElasticDiscoverSearchQueryURL(index, filters)::
    buildElasticDiscoverSearchQueryURL(index, filters),

  // Given an index, and a set of filters, returns a URL to a Kibana count visualization
  buildElasticLineCountVizURL(index, filters)::
    buildElasticLineCountVizURL(index, filters),

  // Given an index, and a set of filters, returns a URL to a Kibana percentile visualization
  buildElasticLinePercentileVizURL(index, filters, field)::
    buildElasticLinePercentileVizURL(index, filters, field),
}
