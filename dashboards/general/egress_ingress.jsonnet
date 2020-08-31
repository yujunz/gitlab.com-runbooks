local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local timepickerlib = import 'github.com/grafana/grafonnet-lib/grafonnet/timepicker.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local row = grafana.row;
local templates = import 'grafana/templates.libsonnet';
local graphPanel = grafana.graphPanel;
local generalGraphPanel(
  title,
  fill=1,
  format=null,
  formatY1=null,
  formatY2=null,
  decimals=3,
  description=null,
  linewidth=2,
  sort=0,
      ) = graphPanel.new(
  title,
  linewidth=linewidth,
  fill=fill,
  format=format,
  formatY1=formatY1,
  formatY2=formatY2,
  datasource='$PROMETHEUS_DS',
  description=description,
  decimals=decimals,
  sort=sort,
  legend_show=false,
  legend_values=false,
  legend_min=false,
  legend_max=true,
  legend_current=true,
  legend_total=false,
  legend_avg=true,
  legend_alignAsTable=true,
  legend_hideEmpty=false,
  legend_rightSide=true,
);

local networkPanel(title, filter) =
  generalGraphPanel(title)
  .addTarget(
    promQuery.target('sum(increase(node_network_transmit_bytes_total{device!=\"lo\", %(filter)s, env=\"$environment\"}[1d]))' % { filter: filter }, legendFormat="egress")
  )
  .addTarget(
    promQuery.target('sum(increase(node_network_receive_bytes_total{device!=\"lo\", %(filter)s, env=\"$environment\"}[1d])) * -1' % { filter: filter }, legendFormat="ingress")
  )
  .resetYaxes()
  .addYaxis(
    format='bytes',
    label='bytes',
  )
  .addYaxis(
    format='byte',
    show=false,
  );


basic.dashboard(
  'Network Ingress/Egress Overview',
  tags=['general'],
  editable=true,
  refresh='5m',
  timepicker=timepickerlib.new(refresh_intervals=['1m', '5m', '10m', '30m']),
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
  time_from='now-30d',
  time_to='now'
)

.addTemplate(templates.environment)

// ----------------------------------------------------------------------------
// Overview
// ----------------------------------------------------------------------------

.addPanels(
  layout.grid([
    grafana.text.new(
      title='Explainer',
      mode='markdown',
      content=|||
        # What is this?

        Amount of ingress / egress traffic per day, broken up by fleet type.

        ## Explanation

        * HAProxy:
          * registry: registry.gitlab.com traffic 
          * fe: gitlab.com traffic (via cloudflare)
          * pages: *.gitlab.io and pages custom domains
        * Fleet
          * git: git-https, git-ssh, websockets
          * api: gitlab.com public api, gitlab.com/v4/api/*
          * web: gitlab.com web traffic, anything that is not gitlab.com/v4/api/*
          * web-pages: *.gitlab.io pages traffic
        * Storage
          * file: All projects/wikis from local disk, this is where gitaly runs
          * pages: NFS server for *.gitlab.io gitlab pages
          * share: Shared cache for job traces and artifacts
          * patroni: All postgres database servers
          * redis: All redis clusters
      |||
    ),
    grafana.text.new(
      title='FAQ',
      mode='markdown',
      content=|||
        ## FAQ

        * Why is the fleet bandwidth so symetrical? Shouldn't we be sending more than we receive?
          * Most of our traffic is proxied to the storage tier, or to object storage.
        * Do clients download direct from object storage?
          * It depends. 
            * registry: all image pulls are direct from object storage 
            * uploads/lfs/merge-request-diffs: currently set to proxy but we might change that
              https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10117
        * Why does web-pages have so much ingress?
          *  Probably because of NFS, as you can see it is reading a lot of data from NFS but not serving
               as much to the client, and probably compressed.
      |||
    ),
  ], cols=2, rowHeight=13, startRow=1)
)
.addPanel(
  row.new(title='HAProxy'),
  gridPos={ x: 0, y: 2, w: 24, h: 12 },
)
.addPanels(
  layout.grid([
    networkPanel('Fe (HAProxy) Registry Data Transfer / 24h', 'fqdn=~"^fe-registry-[0-9].*"'),
    networkPanel('Fe (HAProxy) Data Transfer / 24h', 'fqdn=~"^fe-[0-9].*"'),
    networkPanel('Fe Pages (HAProxy) Data Transfer / 24h', 'fqdn=~"^fe-pages-[0-9].*"'),
  ], cols=3, rowHeight=7, startRow=2)
)
.addPanel(
  row.new(title='Fleet'),
  gridPos={ x: 0, y: 3, w: 24, h: 12 },
)
.addPanels(
  layout.grid([
    networkPanel('Git Data Transfer / 24h', 'fqdn=~"^git-.*"'),
    networkPanel('API Data Transfer / 24h', 'fqdn=~"^api-.*"'),
    networkPanel('Web Data Transfer / 24h', 'fqdn=~"^web-[0-9]+.*"'),
    networkPanel('Web Pages Transfer / 24h', 'fqdn=~"^web-pages.*"'),
  ], cols=4, rowHeight=7, startRow=3)
)
.addPanel(
  row.new(title='Storage'),
  gridPos={ x: 0, y: 4, w: 24, h: 12 },
)
.addPanels(
  layout.grid([
    networkPanel('File (Gitaly) Data Transfer / 24h', 'fqdn=~"^file-.*"'),
    networkPanel('Patroni  (Database) Data Transfer / 24h', 'fqdn=~"^share-.*"'),
    networkPanel('Redis  (All) Data Transfer / 24h', 'type=~"^redis.*"'),
  ], cols=3, rowHeight=7, startRow=4)
)
.addPanels(
  layout.grid([
    networkPanel('Pages Storage (NFS) Data Transfer / 24h', 'fqdn=~"^pages-.*"'),
    networkPanel('Share Cache Storage (Traces / Artifacts) Data Transfer / 24h', 'fqdn=~"^share-.*"'),
  ], cols=2, rowHeight=7, startRow=5)
)
