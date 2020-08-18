local toolingLinkDefinition = import './tooling_link_definition.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testGenerateMarkdownBlank: {
    actual: toolingLinkDefinition.toolingLinkDefinition({
      url: "https://gitlab.com/",
      title: "GitLab"
    }),
    expect: {
      url: "https://gitlab.com/",
      title: "GitLab"
    },
  },
})
