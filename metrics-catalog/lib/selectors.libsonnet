{
  join(selectors)::
    local nonEmptySelectors = std.filter(function(x) std.length(x) > 0, selectors);
    std.join(', ', nonEmptySelectors),
}
