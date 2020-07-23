local test = import "github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet";
local stableIds = import 'stable-ids.libsonnet';

test.suite({
  testBlank: { actual: stableIds.hashStableId(""), expect: 100552 },
  testHello: { actual: stableIds.hashStableId("hello"), expect: 21512 },
})
