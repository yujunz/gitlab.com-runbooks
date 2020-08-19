local selectors = import './selectors.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testSerializeHashNull: {
    actual: selectors.serializeHash(null),
    expect: '',
  },
  testSerializeHashEmpty: {
    actual: selectors.serializeHash({}),
    expect: '',
  },
  testSerializeHashSimple: {
    actual: selectors.serializeHash({ a: 'b' }),
    expect: 'a="b"',
  },
  testSerializeHashEq: {
    actual: selectors.serializeHash({ a: { eq: 'b' } }),
    expect: 'a="b"',
  },
  testSerializeHashNe: {
    actual: selectors.serializeHash({ a: { ne: 'b' } }),
    expect: 'a!="b"',
  },
  testSerializeHashRe: {
    actual: selectors.serializeHash({ a: { re: 'b' } }),
    expect: 'a=~"b"',
  },
  testSerializeHashNre: {
    actual: selectors.serializeHash({ a: { nre: 'b' } }),
    expect: 'a!~"b"',
  },
  testSerializeHashArray: {
    actual: selectors.serializeHash({ a: ['1', '2', '3'] }),
    expect: 'a="1",a="2",a="3"',
  },
  testSerializeHashEqArray: {
    actual: selectors.serializeHash({ a: { eq: ['1', '2', '3'] } }),
    expect: 'a="1",a="2",a="3"',
  },
  testSerializeHashNeArray: {
    actual: selectors.serializeHash({ a: { ne: ['1', '2', '3'] } }),
    expect: 'a!="1",a!="2",a!="3"',
  },
  testSerializeHashReArray: {
    actual: selectors.serializeHash({ a: { re: ['1', '2', '3'] } }),
    expect: 'a=~"1",a=~"2",a=~"3"',
  },
  testSerializeHashNreArray: {
    actual: selectors.serializeHash({ a: { nre: ['1', '2', '3'] } }),
    expect: 'a!~"1",a!~"2",a!~"3"',
  },
  testSerializeHashMixedArray: {
    actual: selectors.serializeHash({ a: [{ eq: '1' }, { ne: '2' }, { re: '3' }, { nre: '4' }] }),
    expect: 'a="1",a!="2",a=~"3",a!~"4"',
  },
  testMergeTwoNulls: {
    actual: selectors.merge(null, null),
    expect: null,
  },
  testMergeANull: {
    actual: selectors.merge(null, { b: 1 }),
    expect: { b: 1 },
  },
  testMergeBNull: {
    actual: selectors.merge({ a: 1 }, null),
    expect: { a: 1 },
  },
  testMergeStrings: {
    actual: selectors.merge('a="1"', 'b="2"'),
    expect: 'a="1", b="2"',
  },
  testMergeMixed1: {
    actual: selectors.merge('a="1"', { b: 2 }),
    expect: 'a="1", b="2"',
  },
  testMergeMixed2: {
    actual: selectors.merge({ a: 1 }, 'b="2"'),
    expect: 'a="1", b="2"',
  },
  testMergeHashes: {
    actual: selectors.merge({ a: 1 }, { b: '2' }),
    expect: { a: 1, b: '2' },
  },

})
