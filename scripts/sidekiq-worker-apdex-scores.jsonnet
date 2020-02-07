// This file is used to generate `rules/sidekiq-worker-apdex-scores.yml`
// Please be sure to run `scripts/generate-sidekiq-worker-apdex-scores.sh` after changing this file

// Weekly p95 job execution duration values
// Calculated using the following ELK query: https://log.gprd.gitlab.net/goto/3bd0a288bd965a9e5ada6869740ae54c
// Our thanos cluster is unable to handle this query, but if could it would
// be: `histogram_quantile(0.95, sum(rate(sidekiq_jobs_completion_seconds_bucket{environment="gprd"}[1w])) by (le, queue, environment))`
local P95_VALUES_FOR_QUEUES = {
  authorized_projects: 0.725,
  'auto_devops:auto_devops_disable': 0.102,
  'auto_merge:auto_merge_process': 1.162,
  chat_notification: 0.697,
  'container_repository:cleanup_container_repository': 17.958,
  'container_repository:delete_container_repository': 50.057,
  create_evidence: 0.118,
  create_github_webhook: 4.001,
  create_gpg_signature: 4.138,
  create_note_diff_file: 0.625,
  'cronjob:admin_email': 0.046,
  'cronjob:ci_archive_traces_cron': 6.841,
  'cronjob:expire_build_artifacts': 2720.055,
  'cronjob:geo_sidekiq_cron_config': 0.196,
  'cronjob:gitlab_usage_ping': 381.416,
  'cronjob:historical_data': 15.113,
  'cronjob:import_export_project_cleanup': 123.922,
  'cronjob:import_software_licenses': 3.165,
  'cronjob:issue_due_scheduler': 2.842,
  'cronjob:ldap_all_groups_sync': 0.027,
  'cronjob:ldap_sync': 0.034,
  'cronjob:namespaces_prune_aggregation_schedules': 4.335,
  'cronjob:pages_domain_removal_cron': 0.666,
  'cronjob:pages_domain_ssl_renewal_cron': 3.146,
  'cronjob:pages_domain_verification_cron': 1.56,
  'cronjob:pipeline_schedule': 26.355,
  'cronjob:prune_old_events': 1.087,
  'cronjob:prune_web_hook_logs': 15.075,
  'cronjob:pseudonymizer': 0.13,
  'cronjob:remove_expired_group_links': 5.754,
  'cronjob:remove_expired_members': 47.449,
  'cronjob:remove_unreferenced_lfs_objects': 15.027,
  'cronjob:repository_archive_cache': 25.373,
  'cronjob:requests_profiles': 0.049,
  'cronjob:schedule_migrate_external_diffs': 0.03,
  'cronjob:stuck_ci_jobs': 64.441,
  'cronjob:stuck_import_jobs': 12.057,
  'cronjob:stuck_merge_jobs': 0.929,
  'cronjob:trending_projects': 15.178,
  'cronjob:update_all_mirrors': 2.445,
  'cronjob:update_max_seats_used_for_gitlab_com_subscriptions': 183.472,
  delete_diff_files: 0.158,
  delete_merged_branches: 25.604,
  delete_stored_files: 17.741,
  delete_user: 22.464,
  'deployment:deployments_finished': 0.517,
  'deployment:deployments_success': 0.744,
  design_management_new_version: 2.602,
  detect_repository_languages: 6.702,
  elastic_commit_indexer: 2.516,
  elastic_indexer: 0.58,
  email_receiver: 1.106,
  emails_on_push: 10.983,
  'epics:epics_update_epics_dates': 0.133,
  export_csv: 10.753,
  'gcp_cluster:cluster_install_app': 9.198,
  'gcp_cluster:cluster_patch_app': 5.453,
  'gcp_cluster:cluster_provision': 4.683,
  'gcp_cluster:cluster_update_app': 3.497,
  'gcp_cluster:cluster_upgrade_app': 60.864,
  'gcp_cluster:cluster_wait_for_app_installation': 3.54,
  'gcp_cluster:cluster_wait_for_app_update': 2.903,
  'gcp_cluster:cluster_wait_for_ingress_ip_address': 1.54,
  'gcp_cluster:clusters_applications_uninstall': 6.744,
  'gcp_cluster:clusters_applications_wait_for_uninstall_app': 3.611,
  'gcp_cluster:wait_for_cluster_creation': 2.847,
  git_garbage_collect: 0.196,
  github_import_advance_stage: 0.55,
  'github_importer:github_import_import_diff_note': 0.237,
  'github_importer:github_import_import_issue': 0.24,
  'github_importer:github_import_import_note': 0.199,
  'github_importer:github_import_import_pull_request': 6.137,
  'github_importer:github_import_refresh_import_jid': 0.092,
  'github_importer:github_import_stage_finish_import': 2.466,
  'github_importer:github_import_stage_import_base_data': 0.96,
  'github_importer:github_import_stage_import_issues_and_diff_notes': 1.093,
  'github_importer:github_import_stage_import_lfs_objects': 1.492,
  'github_importer:github_import_stage_import_notes': 0.595,
  'github_importer:github_import_stage_import_pull_requests': 0.999,
  'github_importer:github_import_stage_import_repository': 16.725,
  gitlab_shell: 0.19,
  group_destroy: 27.083,
  import_issues_csv: 27.977,
  'incident_management:incident_management_process_prometheus_alert': 1.6,
  invalid_gpg_signature_update: 108.016,
  irker: 4.036,
  'jira_connect:jira_connect_sync_branch': 2.701,
  'jira_connect:jira_connect_sync_merge_request': 0.684,
  'mail_scheduler:mail_scheduler_issue_due': 5.128,
  'mail_scheduler:mail_scheduler_notification_service': 1.001,
  mailers: 1.946,
  merge: 6.312,
  new_epic: 4.139,
  new_issue: 1.055,
  new_merge_request: 3.519,
  new_note: 4.107,
  'notifications:new_release': 1.399,
  'object_pool:object_pool_create': 0.756,
  'object_pool:object_pool_destroy': 0.141,
  'object_pool:object_pool_join': 0.178,
  'object_pool:object_pool_schedule_join': 0.152,
  pages_domain_ssl_renewal: 9.595,
  pages_domain_verification: 0.892,
  pages: 23.938,
  'pipeline_background:archive_trace': 1.153,
  'pipeline_cache:expire_job_cache': 0.152,
  'pipeline_cache:expire_pipeline_cache': 0.519,
  'pipeline_creation:create_pipeline': 4.101,
  'pipeline_creation:run_pipeline_schedule': 2.596,
  'pipeline_default:ci_create_cross_project_pipeline': 4.929,
  'pipeline_default:ci_pipeline_bridge_status': 0.246,
  'pipeline_default:pipeline_metrics': 0.101,
  'pipeline_default:pipeline_notification': 0.325,
  'pipeline_default:store_security_reports': 12.08,
  'pipeline_default:sync_security_reports_to_report_approval_rules': 0.41,
  'pipeline_hooks:build_hooks': 0.538,
  'pipeline_hooks:pipeline_hooks': 0.591,
  'pipeline_processing:build_finished': 0.489,
  'pipeline_processing:build_queue': 0.622,
  'pipeline_processing:build_success': 0.07,
  'pipeline_processing:ci_build_prepare': 11.863,
  'pipeline_processing:ci_build_schedule': 0.408,
  'pipeline_processing:pipeline_process': 1.185,
  'pipeline_processing:pipeline_success': 0.035,
  'pipeline_processing:pipeline_update': 0.142,
  'pipeline_processing:stage_update': 0.147,
  'pipeline_processing:update_head_pipeline_for_merge_request': 0.194,
  post_receive: 2.511,
  process_commit: 1.165,
  project_cache: 0.283,
  project_daily_statistics: 0.097,
  project_destroy: 7.516,
  project_export: 84.283,
  project_import_schedule: 0.843,
  project_service: 0.687,
  reactive_caching: 8.438,
  rebase: 5.231,
  refresh_license_compliance_checks: 0.279,
  repository_cleanup: 23.09,
  repository_fork: 31.327,
  repository_import: 35.965,
  repository_remove_remote: 0.806,
  repository_update_mirror: 3.206,
  repository_update_remote_mirror: 35.902,
  'todos_destroyer:todos_destroyer_confidential_issue': 0.148,
  'todos_destroyer:todos_destroyer_entity_leave': 2.522,
  'todos_destroyer:todos_destroyer_group_private': 0.17,
  'todos_destroyer:todos_destroyer_private_features': 0.091,
  'todos_destroyer:todos_destroyer_project_private': 0.105,
  update_external_pull_requests: 0.121,
  update_merge_requests: 1.589,
  'update_namespace_statistics:namespaces_root_statistics': 0.187,
  'update_namespace_statistics:namespaces_schedule_aggregation': 0.101,
  update_project_statistics: 0.364,
  web_hook: 1.583,
};

// --------------------------------------------------------

// Returns the next biggest latency bucket for a given latency
local thresholdForLatency(latency) =
  if latency < 0.1 then
    '0.1'
  else if latency < 0.25 then
    '0.25'
  else if latency < 0.5 then
    '0.5'
  else if latency < 1 then
    '1'
  else if latency < 2.5 then
    '2.5'
  else if latency < 5 then
    '5'
  else if latency < 10 then
    '10'
  else if latency < 60 then
    '60'
  else if latency < 300 then
    '300'
  else if latency < 600 then
    '600'
  else
    '+Inf';

// Groups each worker by its apdex threshold
local latencyGroups =
  local addQueueToGroup(groups, queue) =
    local threshold = thresholdForLatency(P95_VALUES_FOR_QUEUES[queue]);
    groups {
      [threshold]+: [queue],
    };

  std.foldl(addQueueToGroup, std.objectFields(P95_VALUES_FOR_QUEUES), {});

// Converts an array of workers into a prometheus regular expression matcher
local arrayToRegExp(queues) = std.join('|', queues);

// Given a threshold and list of workers, generates the appropriate prometheus Apdex expression
local apdexScoreForQueues(threshold, queues) =
  |||
    sum(rate(sidekiq_jobs_completion_seconds_bucket{le="%(threshold)s", queue=~"%(queues_re)s"}[1m])) by (environment, queue, stage, tier, type)
    /
    sum(rate(sidekiq_jobs_completion_seconds_bucket{le="+Inf", queue=~"%(queues_re)s"}[1m])) by (environment, queue, stage, tier, type) >= 0
  ||| % {
    threshold: threshold,
    queues_re: arrayToRegExp(queues),
  };

local recordingRuleForThresholdAndQueues(threshold, queues) =
  {
    record: 'gitlab_background_worker_queue_duration_apdex:ratio',
    labels: {
      threshold: threshold,
    },
    expr: apdexScoreForQueues(threshold, queues),
  };

local excludeInfThreshold(threshold) = threshold != '+Inf';

local rulesFile = {
  groups: [{
    name: 'sidekiq-worker-apdex-scores.rules',
    rules: [
      recordingRuleForThresholdAndQueues(threshold, latencyGroups[threshold])
      for threshold in std.filter(excludeInfThreshold, std.objectFields(latencyGroups))
    ],
  }],
};

std.manifestYamlDoc(rulesFile)
