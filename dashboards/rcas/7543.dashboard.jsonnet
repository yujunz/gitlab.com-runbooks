local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;

local commonAnnotations = import 'common_annotations.libsonnet';
local templates = import 'templates.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';
local text = grafana.text;

basic.dashboard(
  '2019-08-14 long degradation after postgres failover',
  tags=['rca'],
  time_from='2019-08-14 06:00:00',
  time_to='2019-08-14 22:00:00',
)
.addPanels(layout.grid([
  text.new(
    title='Loopback traffic on patroni-01',
    mode='markdown',
    content=|||
      Many of the logs on patroni-01 report losing connectivity to services running on localhost. This includes Patroni talking to Postgres and Patroni talking to Consul.
    |||
  ),
  basic.networkTrafficGraph(
    title='Loopback traffic on patroni-01',
    sendQuery=|||
      rate(node_network_transmit_bytes_total{device="lo",fqdn="patroni-01-db-gprd.c.gitlab-production.internal"}[$__interval])
    |||,
    receiveQuery=|||
      rate(node_network_receive_bytes_total{device="lo",fqdn="patroni-01-db-gprd.c.gitlab-production.internal"}[$__interval])
    |||,
    intervalFactor=2
  ),

  // ------------------------------------------------------

  text.new(
    title='Memory pressure on patroni-01',
    mode='markdown',
    content=|||
      Kernel logs show stress from memory pressure in the hours leading up the failover.
    |||
  ),
  basic.saturationTimeseries(
    title='Memory Utilization',
    query=|||
      1 -
      (
        (
          node_memory_MemFree_bytes{fqdn="patroni-01-db-gprd.c.gitlab-production.internal"} +
          node_memory_Buffers_bytes{fqdn="patroni-01-db-gprd.c.gitlab-production.internal"} +
          node_memory_Cached_bytes{fqdn="patroni-01-db-gprd.c.gitlab-production.internal"}
        )
      )
      /
      node_memory_MemTotal_bytes{fqdn="patroni-01-db-gprd.c.gitlab-production.internal"}
    |||,
    legendFormat='{{ fqdn }}',
  ),

], cols=2, rowHeight=10, startRow=1))
+ {
  annotations: {
    list+: [
      {
        datasource: 'Pagerduty',
        enable: true,
        hide: false,
        iconColor: '#F2495C',
        limit: 100,
        name: 'GitLab Production Pagerduty',
        serviceId: 'PATDFCE',
        showIn: 0,
        tags: [],
        type: 'tags',
        urgency: 'high',
      },
      {
        datasource: 'Pagerduty',
        enable: true,
        hide: false,
        iconColor: '#C4162A',
        limit: 100,
        name: 'GitLab Production SLO',
        serviceId: 'P7Q44DU',
        showIn: 0,
        tags: [],
        type: 'tags',
        urgency: 'high',
      },
      {
        datasource: 'Simple Annotations',
        enable: true,
        hide: false,
        iconColor: '#5794F2',
        limit: 100,
        name: 'Key Events',
        // To be completed...
        queries: [
          { date: '2019-08-14T08:25:00Z', text: "The patroni postgres cluster manager on the primary database instance (pg01) reports 'ERROR: get_cluster'" },
        ],
        showIn: 0,
        tags: [],
        type: 'tags',
      },
    ],
  },
}
