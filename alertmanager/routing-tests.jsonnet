local configFile = std.extVar('configFile');

local generateTest(testcase) =
  'amtool config routes test --verify.receivers=%(receivers)s --config.file %(configFile)s %(labels)s' % {
    configFile: configFile,
    labels: std.join(' ', std.map(function(key) key + "=" + testcase.labels[key], std.objectFields(testcase.labels))),
    receivers: std.join(',', testcase.receivers)
  };

local generateTests(testcases) =
  std.join('\n', std.map(generateTest, testcases));

/**
 * This file contains a test of tests to ensure that out alert routing rules
 * work as we expect them too
 */
generateTests([
  {
    /* no labels */
    labels: {},
    receivers: [
      'main_alerts_channel'
    ],
  },
  {
    /* no matching labels */
    labels: {
      __unknown: 'x'
    },
    receivers: [
      'main_alerts_channel'
    ],
  },
  {
    /* pagerduty */
    labels: {
      pager: 'pagerduty'
    },
    receivers: [
      'prod_pagerduty',
      'pager_alerts_channel'
    ],
  }, {
    /* production pagerduty and rules_domain=general */
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      env: 'gprd'
    },
    receivers: [
      /* This is probably wrong, but not changing anything yet */
      'slack_bridge-prod',
      'slack_alerts_general',
      'prod_pagerduty',
      'pager_alerts_channel'
    ],
  }, {
    /* channel=gitaly, pager=pagerduty, rules_domain=general  */
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      channel: 'gitaly',
      env: 'gprd'
    },
    receivers: [
      /* This is probably wrong, but not changing anything yet */
      'slack_bridge-prod',
      'slack_alerts_general',
      'gitaly_alerts_channel',
      'prod_pagerduty',
      'pager_alerts_channel',
    ],
  }, {
    /* channel=gitaly, pager=pagerduty, rules_domain=general  */
    labels: {
      channel: 'database',
      env: 'gprd'
    },
    receivers: [
      /* This is probably wrong, but not changing anything yet */
      'database_alerts_channel',
      'main_alerts_channel'
    ],
  },
])
