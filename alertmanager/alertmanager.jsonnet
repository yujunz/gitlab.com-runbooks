// Generate Alertmanager configurations
local secrets = std.extVar('secrets');

// Where the alertmanager templates are deployed.
local templateDir = '/etc/alertmanager/templates';

//
// Reciver helpers and definitinos.

local slackChannels = [
  // Generic chanels.
  { name: 'main_alerts_channel', channel: 'alerts' },
  { name: 'pager_alerts_channel', channel: 'production' },

  // Team channels.
  { name: 'ci-cd_alerts_channel', channel: 'alerts-ci-cd' },
  { name: 'ci-cd_low_priority_alerts_channel', channel: 'alerts-ci-cd' },
  { name: 'database_alerts_channel', channel: 'database' },
  { name: 'database_low_priority_alerts_channel', channel: 'database' },
  { name: 'gitaly_alerts_channel', channel: 'g_gitaly' },
  { name: 'gitaly_low_priority_alerts_channel', channel: 'gitaly-alerts' },
  { name: 'observability_alerts_channel', channel: 'observability' },
  { name: 'observability_low_priority_alerts_channel', channel: 'observability' },

  // This is temporary while https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/4881 is ongoing
  { name: 'slack_alerts_general', channel: 'alerts-gen-svc-test' },
];

local webhookChannels =
  [
    { name: 'dead_mans_snitch', url: 'https://nosnch.in/' + secrets.snitchApiKey, sendResolved: false },
  ] +
  [
    { name: 'dead_mans_snitch_' + s.name, url: 'https://nosnch.in/' + s.apiKey, sendResolved: false }
    for s in secrets.snitchChannels
  ] +
  [
    {
      name: w.name,
      url: w.url,
      sendResolved: true,
      httpConfig: {
        bearer_token: w.token,
      },
    }
    for w in secrets.webhookChannels
  ] +
  [
    {
      name: 'issue:' + s.name,
      url: 'https://' + s.name + '/prometheus/alerts/notify.json',
      sendResolved: true,
      httpConfig: {
        bearer_token: s.token,
      },
    }
    for s in secrets.issueChannels
  ];

local PagerDutyReceiver(channel) = {
  name: channel.name,
  pagerduty_configs: [
    {
      service_key: channel.serviceKey,
      description: '{{ template "slack.title" . }}',
      client: 'GitLab Alertmanager',
      client_url: '{{ template "slack.link" . }}',
      details: {
        note: '{{ template "slack.text" . }}',
      },
      send_resolved: true,
    },
  ],
};

local SlackReceiver(channel) = {
  name: channel.name,
  slack_configs: [
    {
      channel: '#' + channel.channel,
      color: '{{ template "slack.color" . }}',
      icon_emoji: '{{ template "slack.icon" . }}',
      send_resolved: true,
      text: '{{ template "slack.text" . }}',
      title: '{{ template "slack.title" . }}',
      title_link: '{{ template "slack.link" . }}',
    },
  ],
};

local WebhookReceiver(channel) = {
  name: channel.name,
  webhook_configs: [
    {
      url: channel.url,
      send_resolved: channel.sendResolved,
      http_config: if std.objectHas(channel, 'httpConfig') then channel.httpConfig else {},
    },
  ],
};

//
// Route helpers and definitions.

// Make sure there is a TEAM_alerts_channel and TEAM_low_priority_alerts_channel in slackChannels above.
local teams = [
  'ci-cd',
  'database',
  'gitaly',
  'observability',
];

local defaultGroupBy = [
  'env',
  'tier',
  'type',
  'alertname',
  'stage',
];

local SnitchRoute(channel) = {
  match: {
    alertname: 'SnitchHeartBeat',
    env: channel.name,
  },
  receiver: 'dead_mans_snitch_' + channel.name,
  group_wait: '1m',
  group_interval: '5m',
  repeat_interval: '5m',
  continue: false,
};

local TeamRoute(team) = {
  continue: true,
  group_by: [
    'env',
    'alertname',
    'instance',
    'job',
    'stage',
  ],
  match: {
    channel: team,
  },
  receiver: team + '_alerts_channel',
  routes: [
    {
      continue: false,
      match: {
        severity: 'warn',
      },
      receiver: team + '_low_priority_alerts_channel',
    },
    {
      continue: false,
      match: {
        severity: 'error',
      },
      receiver: team + '_alerts_channel',
    },
  ],
};

local slackBridge = {
  continue: true,
  group_by: defaultGroupBy,
  match: {
    rules_domain: 'general',
  },
  receiver: 'slack_bridge',
};

local slackAlertsGeneralNoPager = {
  continue: false,
  group_by: defaultGroupBy,
  match: {
    pager: '',
    rules_domain: 'general',
  },
  receiver: 'slack_alerts_general',
};

local slackAlertsGeneralPager = {
  continue: true,
  group_by: defaultGroupBy,
  match: {
    pager: 'pagerduty',
    rules_domain: 'general',
  },
  receiver: 'slack_alerts_general',
};


local issueRoutes = {
  continue: true,
  match: {
    pager: 'issue',
  },
  group_by: [
    'env',
    'alertname',
    'stage',
  ],
  group_wait: '10m',
  group_interval: '1h',
  repeat_interval: '3d',
  routes: [
    {
      match: {
        project: i.name,
      },
      receiver: 'issue:' + i.name,
    }
    for i in secrets.issueChannels
  ],
};

local pagerdutyRoutes = {
  continue: false,
  match: {
    pager: 'pagerduty',
  },
  routes: [
    {
      continue: false,
      match_re: {
        env: 'gstg|dr|pre',
      },
      group_by: [
        'env',
        'alertname',
        'stage',
      ],
      receiver: 'non_prod_pagerduty',
    },
    {
      continue: false,
      match: {
        slo_alert: 'yes',
        env: 'dr',
      },
      receiver: 'slo_dr',
    },
    {
      continue: true,
      match: {
        slo_alert: 'yes',
        env: 'gprd',
        stage: 'cny',
      },
      receiver: 'slo_gprd_cny',
    },
    {
      continue: true,
      match: {
        slo_alert: 'yes',
        env: 'gprd',
        stage: 'main',
      },
      receiver: 'slo_gprd_main',
    },
    {
      continue: false,
      group_by: defaultGroupBy,
      match: {
        slo_alert: 'yes',
      },
      receiver: 'pager_alerts_channel',
    },
    {
      continue: false,
      match: {
        slo_alert: 'yes',
      },
      receiver: 'slo_non_prod',
    },
    {
      continue: true,
      group_by: ['env', 'alertname', 'stage'],
      receiver: 'prod_pagerduty',
    },
    {
      continue: true,
      group_by: defaultGroupBy,
      receiver: 'pager_alerts_channel',
    },
  ],
};

local catchallRoutes = {
  continue: false,
  group_by: defaultGroupBy,
  receiver: 'main_alerts_channel',
};

//
// Generate the list of routes and receivers.

local receivers =
  [PagerDutyReceiver(c) for c in secrets.pagerDutyChannels] +
  [SlackReceiver(c) for c in slackChannels] +
  [WebhookReceiver(c) for c in webhookChannels];

local generalAlertsRoutes = [
  {
    continue: true,
    match: {
      rules_domain: 'general',
    },
    group_by: defaultGroupBy,
    receiver: 'slack_bridge',
  },
  {
    continue: false,
    match: {
      rules_domain: 'general',
      pager: '',
    },
    group_by: defaultGroupBy,
    receiver: 'slack_alerts_general',
  },
  {
    continue: true,
    match: {
      rules_domain: 'general',
      pager: 'pagerduty',
    },
    group_by: defaultGroupBy,
    receiver: 'slack_alerts_general',
  },
];

local routes =
  [SnitchRoute(c) for c in secrets.snitchChannels] +
  [
    {
      match: {
        alertname: 'SnitchHeartBeat',
      },
      receiver: 'dead_mans_snitch',
      group_wait: '1m',
      group_interval: '5m',
      repeat_interval: '5m',
      continue: false,
    },
  ] +
  [slackBridge] +
  [slackAlertsGeneralNoPager] +
  [slackAlertsGeneralPager] +
  [TeamRoute(t) for t in teams] +
  [issueRoutes] +
  [pagerdutyRoutes] +
  [catchallRoutes];

//
// Generate the whole alertmanager config.

local alertmanager = {
  global: {
    slack_api_url: secrets.slackAPIURL,
  },
  receivers: receivers,
  route: {
    repeat_interval: '8h',
    receiver: 'main_alerts_channel',
    group_by: defaultGroupBy,
    routes: routes,
  },
  templates: [
    templateDir + '/*.tmpl',
  ],
};

{
  'alertmanager.yml': std.manifestYamlDoc(alertmanager, indent_array_in_object=true),
}
