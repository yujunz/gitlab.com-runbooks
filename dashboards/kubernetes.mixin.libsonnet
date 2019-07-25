local kubernetes = import "kubernetes-mixin/mixin.libsonnet";

local mixin = kubernetes {
  _config+:: {
    kubeStateMetricsSelector: 'job="kube-state-metrics"',
    cadvisorSelector: 'job="kubernetes-cadvisor"',
    nodeExporterSelector: 'job="kubernetes-node-exporter"',
    kubeletSelector: 'job="kubernetes-kubelet"',
    grafanaK8s+:: {
      dashboardNamePrefix: '',
      dashboardTags: ['kubernetes', 'infrastucture'],
    },
  },
};

// Perform custom modifications to the dashboard to suit the GitLab Grafana deployment
{
  [std.strReplace(x, 'k8s-', '')]: mixin.grafanaDashboards[x] {
    uid: null,
    timezone: "UTC"
  }, for x in std.objectFields(mixin.grafanaDashboards)
}


