local stackdriverLogs = import './stackdriver_logs.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testToolingLink: {
    actual: stackdriverLogs.stackdriverLogsEntry(
      title='simple',
      queryHash={ a: 'b', c: 1 },
    ),
    expect: {
      title: 'simple',
      url: 'https://console.cloud.google.com/logs/query;query=a%3D%22b%22%0Ac%3D1;timeRange=PT30M?project=gitlab-production',
    },
  },
  testSerializeEmptyHashes: {
    actual: stackdriverLogs.serializeQueryHash({}),
    expect: '',
  },
  testSerializeGreaterThanLessThanOperators: {
    actual: stackdriverLogs.serializeQueryHash({
      a: { lt: 1 },
      b: { gt: 2 },
      c: { gte: 3 },
      d: { lte: 5 },
    }),
    expect: 'a<1\nb>2\nc>=3\nd<=5',
  },

})
