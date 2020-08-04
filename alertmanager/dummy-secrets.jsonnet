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
    { name: 'ops', apiKey: 'secret', cluster: 'alertmanager-notifications' },
    { name: 'ops', apiKey: 'secret', cluster: '' },
    { name: 'ops', apiKey: 'secret', cluster: 'ops-gitlab-gke' },
    { name: 'gprd', apiKey: 'secret', cluster: '' },
    { name: 'gprd', apiKey: 'secret', cluster: 'gprd-gitlab-gke' },
    { name: 'gstg', apiKey: 'secret', cluster: '' },
    { name: 'pre', apiKey: 'secret', cluster: '' },
    { name: 'testbed', apiKey: 'secret', cluster: '' },
    { name: 'thanos-rule', apiKey: 'secret', cluster: '' },
  ],
  // Generic webhook configs.
  webhookChannels: [
    { name: 'slack_bridge-nonprod', url: 'http://example.com', token: 'secret' },
    { name: 'slack_bridge-prod', url: 'http://example.com', token: 'secret' },
  ],
}
