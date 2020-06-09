<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Waf Service

* **Responsible Teams**:
  * [infrastructure-coreinfra](https://about.gitlab.com/handbook/engineering/infrastructure/team/reliability/). **Slack Channel**: [#production](https://gitlab.slack.com/archives/production)
* **General Triage Dashboard**: https://dashboards.gitlab.net/d/26q8nTzZz/service-platform-metrics?from=now-6h&to=now&var-prometheus_ds=Global&var-environment=gprd&var-type=waf&orgId=1
* **Alerts**: https://alerts.gprd.gitlab.net/#/alerts?filter=%7Btype%3D%22waf%22%2C%20tier%3D%22lb%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:WAF"

## Logging

* []()

## Troubleshooting Pointers

* [../cloudflare/README.md](../cloudflare/README.md)
* [../cloudflare/cloudflare-terraform.md](../cloudflare/cloudflare-terraform.md)
* [cloudflare-managing-traffic.md](cloudflare-managing-traffic.md)
<!-- END_MARKER -->
