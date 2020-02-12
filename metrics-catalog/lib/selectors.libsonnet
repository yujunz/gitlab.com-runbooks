// serializeItem supports 5 forms for the value:
// 1: for string values: -> `label="value"`
// 2: for equality values { eq: "value" } -> `label="value"`
// 3: for non-equality values { ne: "value" } -> `label!="value"`
// 4: for regex-match values { re: "value" } -> `label=~"value"`
// 5: for non-regex-match values { nre: "value" } -> `label!~"value"`

local serializeItem(label, value) =
  local operator =
    if std.isString(value) then
      '='
    else if std.objectHas(value, 're') then
      '=~'
    else if std.objectHas(value, 'nre') then
      '!~'
    else if std.objectHas(value, 'ne') then
      '!='
    else if std.objectHas(value, 'eq') then
      '='
    else
      std.assertEqual('', 'Illegal value');

  local innerValue =
    if std.isString(value) then
      value
    else if std.objectHas(value, 're') then
      value.re
    else if std.objectHas(value, 'nre') then
      value.nre
    else if std.objectHas(value, 'ne') then
      value.ne
    else if std.objectHas(value, 'eq') then
      value.eq
    else
      std.assertEqual('', 'Illegal value');

  '%s%s"%s"' % [label, operator, innerValue];
{
  join(selectors)::
    local nonEmptySelectors = std.filter(function(x) std.length(x) > 0, selectors);
    std.join(', ', nonEmptySelectors),

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
    local fields = std.set(std.objectFields(selectorHash));
    local pairs = std.foldl(function(memo, key)
                              memo + [serializeItem(key, selectorHash[key])],
                            fields,
                            []);

    std.join(', ', pairs),

  // Remove certain selectors from a selectorHash
  without(selectorHash, labels)::
    local fields = std.set(std.objectFields(selectorHash));
    local remaining = std.setDiff(fields, std.set(labels));

    std.foldl(function(memo, key)
                memo { [key]: selectorHash[key] },
              remaining,
              {}),
}
