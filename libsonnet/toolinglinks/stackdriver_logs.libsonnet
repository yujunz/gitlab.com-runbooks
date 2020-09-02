local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition;
local url = import 'github.com/jsonnet-libs/xtd/url.libsonnet';

local serializeQueryHashValue(value) =
  if std.isString(value) then
    '"%s"' % [value]
  else
    value;


local serializeQueryHashItem(key, op, value) =
  '%(key)s%(op)s%(value)s' % {
    key: key,
    op: op,
    value: value,
  };


local serializeQueryHashPair(key, value) =
  if value == null then
    null
  else if !std.isObject(value) then
    serializeQueryHashItem(key, '=', serializeQueryHashValue(value))
  else if std.objectHas(value, 'gt') then
    serializeQueryHashItem(key, '>', serializeQueryHashValue(value.gt))
  else if std.objectHas(value, 'gte') then
    serializeQueryHashItem(key, '>=', serializeQueryHashValue(value.gte))
  else if std.objectHas(value, 'lt') then
    serializeQueryHashItem(key, '<', serializeQueryHashValue(value.lt))
  else if std.objectHas(value, 'lte') then
    serializeQueryHashItem(key, '<=', serializeQueryHashValue(value.lte))
  else
    std.assertEqual(value, { __message__: 'unknown operator' });

// https://cloud.google.com/logging/docs/view/advanced-queries
local serializeQueryHash(hash) =
  local lines = std.map(function(key) serializeQueryHashPair(key, hash[key]), std.objectFields(hash));
  local linesFiltered = std.filter(function(f) f != null, lines);
  std.join('\n', linesFiltered);

{
  // Given a hash, returns a textual stackdriver logs query
  serializeQueryHash:: serializeQueryHash,

  // Returns a link to a stackdriver logging query
  stackdriverLogsEntry(
    title,
    queryHash,
    project='gitlab-production',
    timeRange='PT30M',
  )::
    toolingLinkDefinition({
      title: title,
      url: 'https://console.cloud.google.com/logs/query;query=%(query)s;timeRange=%(timeRange)s?project=%(project)s' % {
        project: project,
        timeRange: timeRange,
        query: url.escapeString(serializeQueryHash(queryHash)),
      },
    }),
}
