local test = import "github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet";
local rison = import 'rison.libsonnet';

test.suite({
  testBlank: {
    actual: rison.encode({}),
    expect: '()'
  },

  testString: {
    actual: rison.encode({ name: 'value' }),
    expect: "('name':'value')"
  },

  testNumber: {
    actual: rison.encode({ name: 1 }),
    expect: "('name':1)"
  },

  testHash: {
    actual: rison.encode({ name: { first: 'A', last: 'Z' } }),
    expect: "('name':('first':'A','last':'Z'))"
  },

  testArray: {
    actual: rison.encode({ name: [{ first: 'A' }] }),
    expect: "('name':!(('first':'A')))"
  }
})
