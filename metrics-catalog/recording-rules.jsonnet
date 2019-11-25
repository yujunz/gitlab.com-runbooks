local recordingRuleRenderer = import './lib/recording_rule_renderer.libsonnet';

recordingRuleRenderer.yaml(import './services/all.jsonnet')
