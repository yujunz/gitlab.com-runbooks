local test = import "github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet";
local strings = import 'strings.libsonnet';

test.suite({
  testRemoveBlankLines: {
    actual: strings.removeBlankLines(|||
      hello

      there

      you
    |||),
    expect: |||
      hello
      there
      you
    |||
  },

  testChomp: {
    actual: strings.chomp("hello\n\n"),
    expect: "hello"
  },
  testChompBlank: {
    actual: strings.chomp(""),
    expect: ""
  },
  testChompNewLines: {
    actual: strings.chomp("hello\nthere"),
    expect: "hello\nthere"
  },

  testIndentBlank: {
    actual: strings.indent("", 2),
    expect: "",
  },
  testIndentSingleLine: {
    actual: strings.indent("hello", 2),
    expect: "hello",
  },
  testIndentMultiLine: {
    actual: strings.indent("hello\nthere\nworld", 2),
    expect: "hello\n  there\n  world",
  },

})
