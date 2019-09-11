// This file is used to generate `rules/sidekiq-worker-apdex-scores.yml`
// Please be sure to run `scripts/generate-sidekiq-worker-apdex-scores.sh` after changing this file

// Weekly p95 job execution duration values
// Calculated using the following ELK query: https://log.gitlab.net/goto/3bd0a288bd965a9e5ada6869740ae54c
// Our thanos cluster is unable to handle this query, but if could it would
// be: `histogram_quantile(0.95, sum(rate(sidekiq_jobs_completion_time_seconds_bucket{environment="gprd"}[1w])) by (le, worker, environment))`
local P95_VALUES_FOR_WORKERS = {
  ExpireBuildArtifactsWorker: 2716.17,
  UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker: 1242.25,
  PipelineScheduleWorker: 549.81,
  RemoveExpiredMembersWorker: 498.06,
  ImportExportProjectCleanupWorker: 448.27,
  GitlabUsagePingWorker: 353.07,
  'Namespaces::PruneAggregationSchedulesWorker': 275.84,
  ProjectExportWorker: 242.24,
  'Ci::ArchiveTracesCronWorker': 178.06,
  StuckCiJobsWorker: 174.01,
  InvalidGpgSignatureUpdateWorker: 125.07,
  ImportIssuesCsvWorker: 118.35,
  GroupDestroyWorker: 69.06,
  ClusterUpgradeAppWorker: 62.46,
  DeleteUserWorker: 57.31,
  ProjectDestroyWorker: 55.69,
  DeleteMergedBranchesWorker: 53.88,
  StoreSecurityReportsWorker: 50.57,
  StuckImportJobsWorker: 48.71,
  DeleteContainerRepositoryWorker: 48.55,
  ExportCsvWorker: 43.54,
  RepositoryForkWorker: 37.83,
  CleanupContainerRepositoryWorker: 34.53,
  PagesDomainVerificationCronWorker: 32.60,
  PagesWorker: 25.70,
  RepositoryImportWorker: 23.72,
  PostReceive: 23.43,
  RepositoryCleanupWorker: 21.85,
  EmailsOnPushWorker: 21.29,
  'Gitlab::GithubImport::Stage::ImportRepositoryWorker': 20.63,
  RunPipelineScheduleWorker: 19.77,
  RepositoryArchiveCacheWorker: 19.68,
  RepositoryUpdateRemoteMirrorWorker: 18.70,
  HistoricalDataWorker: 17.37,
  'Ci::BuildPrepareWorker': 17.21,
  ReactiveCachingWorker: 17.14,
  PagesDomainSslRenewalCronWorker: 17.08,
  'Gitlab::GithubImport::Stage::FinishImportWorker': 16.15,
  RemoveUnreferencedLfsObjectsWorker: 15.90,
  'Ci::CreateCrossProjectPipelineWorker': 15.84,
  DeleteStoredFilesWorker: 15.68,
  NewEpicWorker: 15.62,
  PruneWebHookLogsWorker: 15.32,
  TrendingProjectsWorker: 15.26,
  ClusterInstallAppWorker: 14.22,
  CreatePipelineWorker: 14.09,
  CreateGithubWebhookWorker: 13.75,
  ClusterPatchAppWorker: 12.15,
  CreateGpgSignatureWorker: 12.10,
  'Clusters::Applications::UninstallWorker': 11.36,
  BuildQueueWorker: 9.69,
  ArchiveTraceWorker: 8.87,
  'MailScheduler::NotificationServiceWorker': 8.70,
  'IncidentManagement::ProcessAlertWorker': 8.53,
  MergeWorker: 8.25,
  RebaseWorker: 8.21,
  'Clusters::Applications::WaitForUninstallAppWorker': 8.15,
  'MailScheduler::IssueDueWorker': 8.08,
  NewMergeRequestWorker: 7.63,
  PipelineProcessWorker: 7.47,
  RemoveExpiredGroupLinksWorker: 7.04,
  DetectRepositoryLanguagesWorker: 6.99,
  'Deployments::SuccessWorker': 6.85,
  'ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper': 6.39,
  ClusterWaitForAppInstallationWorker: 6.38,
  PagesDomainRemovalCronWorker: 6.12,
  'Gitlab::GithubImport::Stage::ImportBaseDataWorker': 6.02,
  EmailReceiverWorker: 5.91,
  NewIssueWorker: 5.85,
  WaitForClusterCreationWorker: 5.80,
  BuildFinishedWorker: 5.78,
  IssueDueSchedulerWorker: 5.73,
  'Gitlab::GithubImport::Stage::ImportIssuesAndDiffNotesWorker': 5.70,
  ClusterProvisionWorker: 5.19,
  CreateNoteDiffFileWorker: 4.89,
  'Gitlab::GithubImport::Stage::ImportPullRequestsWorker': 4.72,
  ElasticCommitIndexerWorker: 4.63,
  ClusterWaitForIngressIpAddressWorker: 4.49,
  PagesDomainSslRenewalWorker: 4.40,
  'Ci::BuildScheduleWorker': 4.38,
  ElasticIndexerWorker: 4.30,
  'TodosDestroyer::EntityLeaveWorker': 4.08,
  'Gitlab::GithubImport::ImportPullRequestWorker': 3.93,
  'Gitlab::GithubImport::Stage::ImportNotesWorker': 3.80,
  'Deployments::FinishedWorker': 3.70,
  'Gitlab::GithubImport::Stage::ImportLfsObjectsWorker': 3.68,
  BuildProcessWorker: 3.66,
  WebHookWorker: 3.62,
  GitGarbageCollectWorker: 3.14,
  AutoMergeProcessWorker: 3.10,
  StuckMergeJobsWorker: 3.08,
  ProjectServiceWorker: 3.07,
  RepositoryUpdateMirrorWorker: 3.00,
  UpdateProjectStatisticsWorker: 2.94,
  PipelineHooksWorker: 2.93,
  UpdateAllMirrorsWorker: 2.80,
  NewNoteWorker: 2.79,
  'Geo::SidekiqCronConfigWorker': 2.71,
  'ObjectPool::JoinWorker': 2.61,
  'ObjectPool::CreateWorker': 2.57,
  'Namespaces::RootStatisticsWorker': 2.51,
  ExpirePipelineCacheWorker: 2.40,
  'Gitlab::GithubImport::ImportIssueWorker': 2.39,
  PruneOldEventsWorker: 2.22,
  'Gitlab::GithubImport::AdvanceStageWorker': 2.10,
  'ObjectPool::ScheduleJoinWorker': 1.99,
  ProcessCommitWorker: 1.96,
  PipelineNotificationWorker: 1.95,
  'Gitlab::GithubImport::ImportDiffNoteWorker': 1.90,
  UpdateMergeRequestsWorker: 1.82,
  BuildHooksWorker: 1.80,
  DeleteDiffFilesWorker: 1.78,
  'Gitlab::GithubImport::ImportNoteWorker': 1.78,
  RepositoryRemoveRemoteWorker: 1.71,
  'Namespaces::ScheduleAggregationWorker': 1.53,
  PagesDomainVerificationWorker: 1.48,
  ProjectDailyStatisticsWorker: 1.45,
  ChatNotificationWorker: 1.41,
  'AutoDevops::DisableWorker': 1.39,
  'TodosDestroyer::PrivateFeaturesWorker': 1.31,
  'TodosDestroyer::ConfidentialIssueWorker': 1.28,
  ProjectCacheWorker: 1.15,
  RemoteMirrorNotificationWorker: 1.14,
  'TodosDestroyer::ProjectPrivateWorker': 1.08,
  StageUpdateWorker: 1.07,
  SyncSecurityReportsToReportApprovalRulesWorker: 1.03,
  IrkerWorker: 1.03,
  PipelineUpdateWorker: 0.91,
  'Gitlab::GithubImport::RefreshImportJidWorker': 0.87,
  BuildSuccessWorker: 0.83,
  PipelineMetricsWorker: 0.83,
  GitlabShellWorker: 0.81,
  PseudonymizerWorker: 0.80,
  'TodosDestroyer::GroupPrivateWorker': 0.77,
  RequestsProfilesWorker: 0.68,
  ExpireJobCacheWorker: 0.66,
  ProjectImportScheduleWorker: 0.61,
  LdapAllGroupsSyncWorker: 0.59,
  PipelineSuccessWorker: 0.55,
  ScheduleMigrateExternalDiffsWorker: 0.53,
  UpdateHeadPipelineForMergeRequestWorker: 0.53,
  'Geo::ContainerRepositorySyncDispatchWorker': 0.50,
  LdapSyncWorker: 0.48,
  AuthorizedProjectsWorker: 0.32,
  'ObjectPool::DestroyWorker': 0.14,
  AdminEmailWorker: 0.05,
};

// --------------------------------------------------------

// Returns the next biggest latency bucket for a given latency
local thresholdForLatency(latency) =
  if latency < 0.1 then
    "0.1"
  else if latency < 0.25 then
    "0.25"
  else if latency < 0.5 then
    "0.5"
  else if latency < 1 then
    "1"
  else if latency < 2.5 then
    "2.5"
  else if latency < 5 then
    "5"
  else if latency < 10 then
    "10"
  else if latency < 25 then
    "25"
  else if latency < 50 then
    "50"
  else
    "+Inf";

// Groups each worker by its apdex threshold
local latencyGroups =
  local addWorkerToGroup(groups, worker) =
    local threshold = thresholdForLatency(P95_VALUES_FOR_WORKERS[worker]);
    groups {
      [threshold]+: [worker],
    };

  std.foldl(addWorkerToGroup, std.objectFields(P95_VALUES_FOR_WORKERS), {});

// Converts an array of workers into a prometheus regular expression matcher
local arrayToRegExp(workers) = std.join('|', workers);

// Given a threshold and list of workers, generates the appropriate prometheus Apdex expression
local apdexScoreForWorkers(threshold, workers) =
  'sum(rate(sidekiq_jobs_completion_time_seconds_bucket{le="' + threshold + '", worker=~"' + arrayToRegExp(workers) + '"}[1m])) by (environment, worker, stage, tier, type)
   /
   sum(rate(sidekiq_jobs_completion_time_seconds_bucket{le="+Inf", worker=~"' + arrayToRegExp(workers) + '"}[1m])) by (environment, worker, stage, tier, type) >= 0';

local recordingRuleForThresholdAndWorkers(threshold, workers) =
  {
    record: "gitlab_background_worker_queue_duration_apdex:ratio",
    labels: {
      threshold: threshold,
    },
    expr: apdexScoreForWorkers(threshold, workers),
  };

local excludeInfThreshold(threshold) = threshold != "+Inf";

local rulesFile = {
  groups: [{
    name: "sidekiq-worker-apdex-scores.rules",
    rules: [
      recordingRuleForThresholdAndWorkers(threshold, latencyGroups[threshold])
for threshold in std.filter(excludeInfThreshold, std.objectFields(latencyGroups))
    ],
  }],
};

std.manifestYamlDoc(rulesFile)
