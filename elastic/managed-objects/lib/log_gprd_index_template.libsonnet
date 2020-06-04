local mappings = {
  camoproxy: import './index_mappings/camoproxy.jsonnet',
  consul: import './index_mappings/consul.jsonnet',
  gitaly: import './index_mappings/gitaly.jsonnet',
  gke: import './index_mappings/gke.jsonnet',
  mailroom: import './index_mappings/mailroom.jsonnet',
  monitoring: import './index_mappings/monitoring.jsonnet',
  pages: import './index_mappings/pages.jsonnet',
  postgres: import './index_mappings/postgres.jsonnet',
  praefect: import './index_mappings/praefect.jsonnet',
  puma: import './index_mappings/puma.jsonnet',
  rails: import './index_mappings/rails.jsonnet',
  redis: import './index_mappings/redis.jsonnet',
  registry: import './index_mappings/registry.jsonnet',
  runner: import './index_mappings/runner.jsonnet',
  shell: import './index_mappings/shell.jsonnet',
  sidekiq: import './index_mappings/sidekiq.jsonnet',
  system: import './index_mappings/system.jsonnet',
  workhorse: import './index_mappings/workhorse.jsonnet',
};
local settings = import 'settings_gprd.libsonnet';

{
  get(
    index,
    env,
  ):: {
    index_patterns: ['pubsub-%s-inf-%s-*' % [index, env]],
    mappings: mappings[index],
    settings: settings.setting(index, env),
  },
}
