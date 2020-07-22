local configFile = std.extVar('configFile');

local generateTest(index, testcase) =
  '(amtool config routes test --verify.receivers=%(receivers)s --config.file %(configFile)s %(labels)s >/dev/null) && echo "✔︎ %(name)s" || { echo "𐄂 Testcase #%(index)d %(name)s failed. Expected %(receivers)s got $(amtool config routes test --config.file %(configFile)s %(labels)s)"; exit 1; }' % {
    configFile: configFile,
    labels: std.join(' ', std.map(function(key) key + '=' + testcase.labels[key], std.objectFields(testcase.labels))),
    receivers: std.join(',', testcase.receivers),
    index: index,
    name: testcase.name,
  };

local generateTests(testcases) =
  std.join('\n', std.mapWithIndex(generateTest, testcases));

/**
 * This file contains a test of tests to ensure that out alert routing rules
 * work as we expect them too
 */
generateTests([
  {
    name: 'no labels',
    labels: {},
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'no matching labels',
    labels: {
      __unknown: 'x',
    },
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'pagerduty',
    labels: {
      pager: 'pagerduty',
    },
    receivers: [
      'prod_pagerduty',
      'production_slack_channel',
    ],
  },
  {
    name: 'production pagerduty and rules_domain=general',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      env: 'gprd',
    },
    receivers: [
      'prod_pagerduty',
      'slack_bridge-prod',
      'production_slack_channel',
    ],
  },
  {
    name: 'gstg pagerduty and rules_domain=general',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      env: 'gstg',
    },
    receivers: [
      'non_prod_pagerduty',
      'slack_bridge-nonprod',
      'nonprod_alerts_slack_channel'
    ],
  },
  {
    name: 'pager=pagerduty, no env label',
    labels: {
      pager: 'pagerduty',
    },
    receivers: [
      'prod_pagerduty',
      'production_slack_channel'
    ],
  },

  {
    name: 'team=gitaly, pager=pagerduty, rules_domain=general',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      team: 'gitaly',
      env: 'gprd',
    },
    receivers: [
      'prod_pagerduty',
      'slack_bridge-prod',
      'team_gitaly_alerts_channel',
      'production_slack_channel',
    ],
  },
  {
    name: 'team alerts for non-prod productions should not go to team channels',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      team: 'gitaly',
      env: 'gstg',
    },
    receivers: [
      'non_prod_pagerduty',
      'slack_bridge-nonprod',
      'nonprod_alerts_slack_channel',
    ],
  },
  {
    name: 'non-existent team',
    labels: {
      team: 'non_existent',
      env: 'gprd',
    },
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'pager=issue, gstg environment',
    labels: {
      pager: 'issue',
      project: 'gitlab.com/gitlab-com/gl-infra/infrastructure',
      env: 'gstg',
    },
    receivers: [
      'nonprod_alerts_slack_channel',
    ],
  },
  {
    name: 'pager=issue, gprd environment',
    labels: {
      pager: 'issue',
      project: 'gitlab.com/gitlab-com/gl-infra/infrastructure',
      env: 'gprd',
    },
    receivers: [
      'issue:gitlab.com/gitlab-com/gl-infra/infrastructure',
    ],
  },
  {
    name: 'pager=issue, unknown project',
    labels: {
      pager: 'issue',
      project: 'nothing',
      env: 'gprd',
    },
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'alertname="SnitchHeartBeat", env="ops"',
    labels: {
      alertname: 'SnitchHeartBeat',
      env: 'ops',
    },
    receivers: [
      'dead_mans_snitch_ops',
    ],
  },
  {
    name: 'alertname="SnitchHeartBeat", unknown environment',
    labels: {
      alertname: 'SnitchHeartBeat',
      env: 'space',
    },
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'alertname="SnitchHeartBeat", no environment',
    labels: {
      alertname: 'SnitchHeartBeat',
    },
    receivers: [
      'prod_alerts_slack_channel',
    ],
  },
  {
    name: 'pager=pagerduty, team=gitaly, env=gprd, slo_alert=yes, stage=cny, rules_domain=general',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      team: 'gitaly',
      env: 'gprd',
      slo_alert: "yes",
      stage: "cny"
    },
    receivers: [
      'slo_gprd_cny', // Pagerduty
      'slack_bridge-prod', // Slackline
      'team_gitaly_alerts_channel', // Gitaly team alerts channel
      'production_slack_channel' // production channel for pager alerts
    ],
  },
  {
    name: 'pager=pagerduty, team=gitaly, env=pre, slo_alert=yes, stage=cny, rules_domain=general',
    labels: {
      pager: 'pagerduty',
      rules_domain: 'general',
      team: 'gitaly',
      env: 'pre',
      slo_alert: "yes",
      stage: "cny"
    },
    receivers: [
      'non_prod_pagerduty',
      'slack_bridge-nonprod',
      'nonprod_alerts_slack_channel'
    ],
  },
  {
    name: 'pager=pagerduty, team=verify, env=gprd',
    labels: {
      pager: 'pagerduty',
      team: 'verify',
      env: 'gprd',
    },
    receivers: [
      'prod_pagerduty',
      'team_verify_alerts_channel',
      'production_slack_channel'
    ],
  },
  {
    name: 'pager=pagerduty, team=gitlab-pages',
    labels: {
      pager: 'pagerduty',
      team: 'gitlab-pages',
      env: 'gprd',
    },
    receivers: [
      'prod_pagerduty',
      'team_gitlab_pages_alerts_channel',
      'production_slack_channel'
    ],
  },
  {
    name: 'non pagerduty, team=gitlab-pages',
    labels: {
      team: 'gitlab-pages',
      severity: 's4',
      env: 'gprd',
    },
    receivers: [
      'team_gitlab_pages_alerts_channel',
      'prod_alerts_slack_channel'
    ],
  },
])
