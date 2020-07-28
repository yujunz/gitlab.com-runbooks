<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->
#  Web-pages Service
* [Service Overview](https://dashboards.gitlab.net/d/web-pages-main/web-pages-overview)
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22web-pages%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:Pages"

## Logging

* [Pages](https://log.gprd.gitlab.net/goto/00a732029c1448a741c8730c04038fd9)
* [haproxy](https://console.cloud.google.com/logs/viewer?project=gitlab-production&interval=PT1H&resource=gce_instance&customFacets=labels.%22compute.googleapis.com%2Fresource_name%22&advancedFilter=labels.tag%3D%22haproxy%22%0Alabels.%22compute.googleapis.com%2Fresource_name%22%3A%22fe-pages-%22)
* [system](https://log.gprd.gitlab.net/goto/3384c89c5a828db866d2fa8ec86cd97f)

## Troubleshooting Pointers

* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../uncategorized/deploycmd.md](../uncategorized/deploycmd.md)
<!-- END_MARKER -->
