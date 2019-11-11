local MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS = std.extVar('marquee_customers_top_level_domains');

local wildcardQuery(topLevelDomain) = {
    wildcard: {
      'json.uri.keyword': '/' + topLevelDomain + '/*',
    },
  };

local wildcardQueries() = [
  wildcardQuery(topLevelDomain)
for topLevelDomain in std.split(MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS, ',')
];

local boolCanaryCustomerQuery() = {
    minimum_should_match: 1,
    should: wildcardQueries(),
  };

local disabledIndividualWildcardQueries() = [
  wildcardQuery(topLevelDomain) +
  {
    meta: {
      index: 'AWM6itvP1NBBQZg_ElD1',
      negate: false,
      disabled: true,
      type: 'custom',
      alias: null,
      key: 'wildcard',
      value: std.manifestJson(wildcardQuery(topLevelDomain).wildcard),
    },
    '$state': {
      store: 'appState',
    },
  }
for topLevelDomain in std.split(MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS, ',')
];

{
  visState: {
    title: 'Marquee Customers: aggregated customer latency in Workhorse',
    type: 'line',
    params: {
      addLegend: true,
      addTimeMarker: false,
      addTooltip: true,
      categoryAxes: [
        {
          id: 'CategoryAxis-1',
          labels: {
            show: true,
            truncate: 100,
          },
          position: 'bottom',
          scale: {
            type: 'linear',
          },
          show: true,
          style: {},
          title: {
            text: 'json.time per 5 minutes',
          },
          type: 'category',
        },
      ],
      grid: {
        categoryLines: false,
        style: {
          color: '#eee',
        },
      },
      legendPosition: 'right',
      seriesParams: [
        {
          data: {
            id: '1',
            label: 'Percentiles of json.duration_ms',
          },
          drawLinesBetweenPoints: true,
          mode: 'normal',
          show: 'true',
          showCircles: true,
          type: 'line',
          valueAxis: 'ValueAxis-1',
        },
      ],
      times: [],
      type: 'line',
      valueAxes: [
        {
          id: 'ValueAxis-1',
          labels: {
            filter: false,
            rotate: 0,
            show: true,
            truncate: 100,
          },
          name: 'LeftAxis-1',
          position: 'left',
          scale: {
            mode: 'normal',
            type: 'linear',
          },
          show: true,
          style: {},
          title: {
            text: 'Percentiles of json.duration_ms',
          },
          type: 'value',
        },
      ],
    },
    aggs: [
      {
        id: '1',
        enabled: true,
        type: 'percentiles',
        schema: 'metric',
        params: {
          field: 'json.duration_ms',
          percents: [
            95,
          ],
        },
      },
      {
        id: '2',
        enabled: true,
        type: 'date_histogram',
        schema: 'segment',
        params: {
          field: 'json.time',
          interval: 'auto',
          customInterval: '2h',
          min_doc_count: 1,
          extended_bounds: {},
        },
      },
    ],
    listeners: {},
  },
  searchSourceJSON: {
    index: 'AWM6itvP1NBBQZg_ElD1',
    query: {
      match_all: {},
    },
    filter: [
      {
        meta: {
          index: 'AWM6itvP1NBBQZg_ElD1',
          negate: false,
          disabled: false,
          alias: null,
          type: 'phrase',
          key: 'json.hostname',
          value: 'web',
        },
        query: {
          match: {
            'json.hostname': {
              query: 'web',
              type: 'phrase',
            },
          },
        },
        '$state': {
          store: 'appState',
        },
      },
      {
        bool: boolCanaryCustomerQuery(),
        meta: {
          negate: false,
          index: 'AWM6itvP1NBBQZg_ElD1',
          disabled: false,
          alias: 'Any Canary Customer',
          type: 'custom',
          key: 'bool',
          value: std.manifestJson(boolCanaryCustomerQuery()),
        },
        '$state': {
          store: 'appState',
        },
      },
    ] + disabledIndividualWildcardQueries(),
  },
}
