// Dummy secrets for CI testing.
{
  // GitLab issue webhook receivers.
  issueChannels: [
    { name: 'gitlab.com/gitlab-com/gl-infra/infrastructure', token: 'secret' },
    { name: 'gitlab.com/gitlab-com/gl-infra/production', token: 'secret' },
  ],
  // PagerDuty services.
  pagerDutyChannels: [
    { name: 'non_prod_pagerduty', serviceKey: 'secret' },
    { name: 'prod_pagerduty', serviceKey: 'secret' },
    { name: 'slo_dr', serviceKey: 'secret' },
    { name: 'slo_gprd_cny', serviceKey: 'secret' },
    { name: 'slo_gprd_main', serviceKey: 'secret' },
    { name: 'slo_non_prod', serviceKey: 'secret' },
  ],
  // GitLab Slack.
  slackAPIURL: 'https://example.com/secret',
  // https://deadmanssnitch.com/
  snitchChannels: [
    { name: 'ops', apiKey: 'secret' },
    { name: 'gprd', apiKey: 'secret' },
    { name: 'gstg', apiKey: 'secret' },
    { name: 'pre', apiKey: 'secret' },
    { name: 'testbed', apiKey: 'secret' },
  ],
  // Generic webhook configs.
  webhookChannels: [
    { name: 'slack_bridge', url: 'http://example.com', token: 'secret' },
  ],
}
