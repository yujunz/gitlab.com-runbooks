local rison = import 'rison.libsonnet';

local indexes = {
  workhorse: 'AWM6itvP1NBBQZg_ElD1',
  rails: 'AW5F1e45qthdGjPJueGO',
};

local defaultColumns = {
  workhorse: ['json.method', 'json.remote_ip', 'json.status', 'json.uri', 'json.duration_ms'],
  rails: ['json.method', 'json.status', 'json.controller', 'json.action', 'json.path', 'json.duration'],
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

  'https://log.gprd.gitlab.net/app/kibana#/discover?_a=' + rison.encode(applicationState);

local buildElasticLineVizURL(index, filters) =
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
            field: '@timestamp',
            interval: 'auto',
            min_doc_count: 1,
            scaleMetricValues: false,
            timeRange: {
              from: 'now-15m',
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

  'https://log.gprd.gitlab.net/app/kibana#/visualize/create?type=line&indexPattern=' + indexes[index] + '&_a=' + rison.encode(applicationState);

{
  matchFilter(field, value)::
    {
      match: {
        [field]: {
          query: value,
          type: 'phrase',
        },
      },
    },

  buildElasticDiscoverSearchQueryURL(index, filters)::
    buildElasticDiscoverSearchQueryURL(index, filters),

  buildElasticLineVizURL(index, filters)::
    buildElasticLineVizURL(index, filters),

}
