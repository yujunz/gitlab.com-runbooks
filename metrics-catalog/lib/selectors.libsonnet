local strings = import './strings.libsonnet';

// serializeItem supports 5 forms for the value:
// 1: for string values: -> `label="value"`
// 2: for equality values { eq: "value" } -> `label="value"`
// 3: for non-equality values { ne: "value" } -> `label!="value"`
// 4: for regex-match values { re: "value" } -> `label=~"value"`
// 5: for non-regex-match values { nre: "value" } -> `label!~"value"`

local serializeItemPair(label, operator, value) =
  local innerValue =
    if std.isString(value) then
      value
    else if std.isNumber(value) then
      '%g' % [value]
    else
      std.assertEqual(std.type(value), 'Illegal value');

  '%s%s"%s"' % [label, operator, innerValue];


local serializeItems(label, operator, value) =
  if std.isArray(value) then
    [serializeItemPair(label, operator, v) for v in value]
  else
    [serializeItemPair(label, operator, value)];

local serializeHashItem(label, value) =
  if std.isString(value) || std.isNumber(value) then
    serializeItems(label, '=', value)
  else if std.isArray(value) then
    // if the value is an array, iterate over the items
    std.flatMap(function(va) serializeHashItem(label, va), value)
  else
    (if std.objectHas(value, 're') then serializeItems(label, '=~', value.re) else [])
    +
    (if std.objectHas(value, 'nre') then serializeItems(label, '!~', value.nre) else [])
    +
    (if std.objectHas(value, 'ne') then serializeItems(label, '!=', value.ne) else [])
    +
    (if std.objectHas(value, 'eq') then serializeItems(label, '=', value.eq) else []);

{
  // Joins an array of selectors and returns a serialized selector string
  join(selectors)::
    local selectorsSerialized = std.map(function(x) self.serializeHash(x), selectors);
    local nonEmptySelectors = std.filter(function(x) std.length(x) > 0, selectorsSerialized);
    std.join(', ', nonEmptySelectors),

  // Given selectors a,b creates a new selector that
  // is logically (a AND b)
  merge(a, b)::
    if std.isString(a) then
      self.join([a, self.serializeHash(b)])
    else if std.isString(b) then
      self.join([self.serializeHash(a), b])
    else
      a + b,

  // serializeHash converts a selector hash object into a prometheus selector query
  // The selector has is a hash with the form { "label_name": <value> }
  // Simple values represent the prometheus equality operator.
  // Object values can have 4 forms:
  // 1. Equality: { eq: "value" } -> `label="value"`
  // 2. Non-equality values { ne: "value" } -> `label!="value"`
  // 3. Regex-match values { re: "value" } -> `label=~"value"`
  // 4. Non-regex-match values { nre: "value" } -> `label!~"value"`
  //
  // Examples:
  // - HASH --------------------------------------- SERIALIZED FORM ----------------
  // * { type: "gitlab" }                           type="gitlab"
  // * { type: { eq: "gitlab" } }                   type="gitlab"
  // * { type: { ne: "gitlab" } }                   type!="gitlab"
  // * { type: { re: "gitlab" } }                   type=~"gitlab"
  // * { type: { nre: "gitlab" } }                  type!~"gitlab"
  // * { type: "gitlab", job: { re: "redis.*"} }    type!~"gitlab",job=~"redis.*"
  // -------------------------------------------------------------------------------
  serializeHash(selectorHash)::
    if std.isString(selectorHash) then
      strings.chomp(selectorHash)
    else
      (
        local fields = std.set(std.objectFields(selectorHash));
        local pairs = std.flatMap(function(key) serializeHashItem(key, selectorHash[key]), fields);
        std.join(',', pairs)
      ),

  // Remove certain selectors from a selectorHash
  without(selectorHash, labels)::
    if std.isString(selectorHash) then
      std.assertEqual(selectorHash, { __assert__: "selectors.without requires a selector hash" })
    else
      local fields = std.set(std.objectFields(selectorHash));
      local labelSet = if std.isArray(labels) then std.set(labels) else std.set(std.objectFields(labels));
      local remaining = std.setDiff(fields, labelSet);

      std.foldl(function(memo, key)
                  memo { [key]: selectorHash[key] },
                remaining,
                {}),

  // Given a selector, returns the labels
  getLabels(selector)::
    if selector == '' then
      []
    else if selector == null then
      []
    else
      std.objectFields(selector),
}
