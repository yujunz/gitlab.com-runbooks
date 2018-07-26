## Accessing the gstg and gprd hosts

As we build out the new gprd and gstg environments you may need to access the
hosts. If you need ssh access to individual vms you have come to the right
place. If you are having difficulty with getting access or you don't believe we
have enabled your public ssh key on these hosts please submit an issue to the
[infrastructure tracker](https://gitlab.com/gitlab-com/infrastructure) with the
`~access_request` and the production team will help.

Direct access to the public internet is turned off in both gstg and gprd, to
access VMs you will need to configure you ssh client to use the bastion hosts.

* [Bastion instructions for gprd](gprd-bastions.md)
* [Bastion instructions for gstg](gstg-bastions.md)

### Hosts

* [GPRD Hosts](https://dashboards.gitlab.net/d/fasrTtKik/hosts?panelId=2&orgId=1&tab=time%20range&var-environment=gprd&var-prometheus=prometheus-01-inf-gprd)
* [GSTG Hosts](https://dashboards.gitlab.net/d/fasrTtKik/hosts?panelId=2&orgId=1&tab=time%20range&var-environment=gstg&var-prometheus=prometheus-01-inf-gstg)

### Tab completion for hosts

To add tab completion to host names that you have already connected to install
`bash-completion` (brew install on osx) and the following to your
`.bash_profile`

```
# for completion
if [ -f /usr/local/etc/bash_completion ]; then
. /usr/local/etc/bash_completion
fi
```

### Monitoring

Logs for gprd & gstg:

- https://log.gitlab.net ([read](logging.md) on how to filter logs per environment)

Grafana:

- https://dashboards.gitlab.net/

Prometheus:

- gprd: https://prometheus.gprd.gitlab.net/ and https://prometheus-app.gprd.gitlab.net/
- gstg: https://prometheus.gstg.gitlab.net/ and https://prometheus-app.gstg.gitlab.net/

Alerts:

- gprd: https://alerts.gprd.gitlab.net/
- gstg: https://alerts.gstg.gitlab.net/


