// Generate Alertmanager configurations
local secrets = std.extVar('secrets_file');
local serviceCatalog = import 'service_catalog.libsonnet';

// GitLab Issue Alert Delivery is disabled while we
// investigate issues not being created
// https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2451#note_385151530
local enableGitLabIssueAlertDelivery = false;

// Where the alertmanager templates are deployed.
local templateDir = '/etc/alertmanager/templates';

//
// Receiver helpers and definitions.
local slackChannels = [
  // Generic chanels.
  { name: 'prod_alerts_slack_channel', channel: 'alerts' },
  { name: 'production_slack_channel', channel: 'production' },
  { name: 'nonprod_alerts_slack_channel', channel: 'alerts-nonprod' },
];

local webhookChannels =
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

// Returns a list of teams with valid `slack_alerts_channel` values
local teamsWithAlertingSlackChannels() =
  local allTeams = serviceCatalog.getTeams();
  std.filter(function(team) std.objectHas(team, 'slack_alerts_channel') && team.slack_alerts_channel != '', allTeams);

local defaultGroupBy = [
  'env',
  'tier',
  'type',
  'alertname',
  'stage',
];

local Route(
  receiver,
  match=null,
  match_re=null,
  group_by=null,
  group_wait=null,
  group_interval=null,
  repeat_interval=null,
  continue=null,
  routes=null,
      ) = {
  receiver: receiver,
  [if match != null then 'match']: match,
  [if match_re != null then 'match_re']: match_re,
  [if group_by != null then 'group_by']: group_by,
  [if group_wait != null then 'group_wait']: group_wait,
  [if group_interval != null then 'group_interval']: group_interval,
  [if repeat_interval != null then 'repeat_interval']: repeat_interval,
  [if routes != null then 'routes']: routes,
  [if continue != null then 'continue']: continue,
};

local RouteCase(
  match=null,
  match_re=null,
  group_by=null,
  group_wait=null,
  group_interval=null,
  repeat_interval=null,
  continue=true,
  defaultReceiver=null,
  when=null,
      ) =
  Route(
    receiver=defaultReceiver,
    match=match,
    match_re=match_re,
    group_by=group_by,
    group_wait=group_wait,
    group_interval=group_interval,
    repeat_interval=repeat_interval,
    continue=continue,
    routes=[
      (
        local c = { match: null, match_re: null } + case;
        Route(
          receiver=c.receiver,
          match=c.match,
          match_re=c.match_re,
          group_by=null,
          continue=false
        )
      )
      for case in when
    ],
  );

local SnitchRoute(channel) =
  local environment = channel.name;

  Route(
    receiver='dead_mans_snitch_' + environment,
    match={
      alertname: 'SnitchHeartBeat',
      env: environment,
    },
    group_by=null,
    group_wait='1m',
    group_interval='5m',
    repeat_interval='5m',
    continue=false
  );

local receiverNameForTeamSlackChannel(team) =
  'team_' + std.strReplace(team.name, '-', '_') + '_alerts_channel';

local routingTree = Route(
  continue=null,
  group_by=defaultGroupBy,
  repeat_interval='8h',
  receiver='prod_alerts_slack_channel',
  routes=
  [
    /* SnitchRoutes do not continue */
    SnitchRoute(channel)
    for channel in secrets.snitchChannels
  ] +
  (
    if enableGitLabIssueAlertDelivery then
      [
        /* pager=issue alerts do not continue */
        Route(
          receiver='issue:' + issueChannel.name,
          match={
            pager: 'issue',
            env: 'gprd',
            project: issueChannel.name,
          },
          continue=false,
          group_wait='10m',
          group_interval='1h',
          repeat_interval='3d',
        )
        for issueChannel in secrets.issueChannels
      ]
    else
      []
  ) + [
    /* pager=pagerduty alerts do continue */
    RouteCase(
      match={ pager: 'pagerduty' },
      continue=true,
      when=[
        { match: { env: 'gstg' }, receiver: 'non_prod_pagerduty' },
        { match: { env: 'dr' }, receiver: 'non_prod_pagerduty' },
        { match: { env: 'pre' }, receiver: 'non_prod_pagerduty' },

        { match: { slo_alert: 'yes', env: 'gprd', stage: 'cny' }, receiver: 'slo_gprd_cny' },
        { match: { slo_alert: 'yes', env: 'gprd', stage: 'main' }, receiver: 'slo_gprd_main' },
        { match: { slo_alert: 'yes', env: 'gprd', stage: 'main' }, receiver: 'slo_gprd_main' },
      ],
      defaultReceiver='prod_pagerduty',
    ),
    /*
     * Send ops/gprd slackline alerts to production slackline
     * gstg slackline alerts go to staging slackline
     * other slackline alerts are passed up
     */
    Route(
      receiver='slack_bridge-prod',
      match={ rules_domain: 'general', env: 'gprd' },
      continue=true,
      // rules_domain='general' should be preaggregated so no need for additional groupBy keys
      group_by=['...']
    ),
    Route(
      receiver='slack_bridge-prod',
      match={ rules_domain: 'general', env: 'ops' },
      continue=true,
      // rules_domain='general' should be preaggregated so no need for additional groupBy keys
      group_by=['...']
    ),
    Route(
      receiver='slack_bridge-nonprod',
      match={ rules_domain: 'general', env: 'gstg' },
      continue=true,
      // rules_domain='general' should be preaggregated so no need for additional groupBy keys
      group_by=['...']
    ),
  ] + [
    Route(
      receiver=receiverNameForTeamSlackChannel(team),
      continue=true,
      match={
        env: 'gprd',  // For now we only send production channel alerts to teams
        team: team.name,
      },
    )
    for team in teamsWithAlertingSlackChannels()
  ] + [
    // Terminators go last
    Route(
      receiver='nonprod_alerts_slack_channel',
      match={ env: 'pre' },
      continue=false,
    ),
    Route(
      receiver='nonprod_alerts_slack_channel',
      match={ env: 'dr' },
      continue=false,
    ),
    Route(
      receiver='nonprod_alerts_slack_channel',
      match={ env: 'gstg' },
      continue=false,
    ),
    // Pager alerts should appear in the production channel
    Route(
      receiver='production_slack_channel',
      match={ pager: 'pagerduty' },
      continue=false,
    ),
    // All else to #alerts
    Route(
      receiver='prod_alerts_slack_channel',
      continue=false,
    ),
  ]
);

//
// Generate the list of routes and receivers.

local receivers =
  [PagerDutyReceiver(c) for c in secrets.pagerDutyChannels] +
  [SlackReceiver(c) for c in slackChannels] +

  // Generate receivers for each team that has a channel
  [SlackReceiver({
    name: receiverNameForTeamSlackChannel(team),
    channel: team.slack_alerts_channel,
  }) for team in teamsWithAlertingSlackChannels()] +
  [WebhookReceiver(c) for c in webhookChannels];

//
// Generate the whole alertmanager config.
local alertmanager = {
  global: {
    slack_api_url: secrets.slackAPIURL,
  },
  receivers: receivers,
  route: routingTree,
  templates: [
    templateDir + '/*.tmpl',
  ],
};

local k8sAlertmanager = {
  alertmanager: {
    config: alertmanager,
  },
};

{
  'alertmanager.yml': std.manifestYamlDoc(alertmanager, indent_array_in_object=true),
  'k8s_alertmanager.yaml': std.manifestYamlDoc(k8sAlertmanager, indent_array_in_object=true),
}
