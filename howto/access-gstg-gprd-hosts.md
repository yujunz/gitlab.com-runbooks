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

### Hosts for gprd

Last updated: 2018-05-03

```
alerts-01-inf-gprd.c.gitlab-production.internal
bastion-03-inf-gprd.c.gitlab-production.internal
consul-03-inf-gprd.c.gitlab-production.internal
kibana-01-inf-gprd.c.gitlab-production.internal
performance-01-inf-gprd.c.gitlab-production.internal
postgres-03-db-gprd.c.gitlab-production.internal
prometheus-01-inf-gprd.c.gitlab-production.internal
prometheus-app-01-inf-gprd.c.gitlab-production.internal
redis-03-db-gprd.c.gitlab-production.internal
redis-cache-03-db-gprd.c.gitlab-production.internal
redis-cache-sentinel-03-db-gprd.c.gitlab-production.internal
sidekiq-besteffort-03-sv-gprd.c.gitlab-production.internal
api-01-sv-gprd.c.gitlab-production.internal
artifacts-01-stor-gprd.c.gitlab-production.internal
bastion-01-inf-gprd.c.gitlab-production.internal
console-01-sv-gprd.c.gitlab-production.internal
consul-01-inf-gprd.c.gitlab-production.internal
deploy-01-sv-gprd.c.gitlab-production.internal
fe-01-lb-gprd.c.gitlab-production.internal
fe-altssh-01-lb-gprd.c.gitlab-production.internal
fe-pages-01-lb-gprd.c.gitlab-production.internal
file-01-stor-gprd.c.gitlab-production.internal
file-02-stor-gprd.c.gitlab-production.internal
file-03-stor-gprd.c.gitlab-production.internal
file-04-stor-gprd.c.gitlab-production.internal
file-05-stor-gprd.c.gitlab-production.internal
file-06-stor-gprd.c.gitlab-production.internal
file-07-stor-gprd.c.gitlab-production.internal
file-08-stor-gprd.c.gitlab-production.internal
file-09-stor-gprd.c.gitlab-production.internal
file-10-stor-gprd.c.gitlab-production.internal
file-11-stor-gprd.c.gitlab-production.internal
file-12-stor-gprd.c.gitlab-production.internal
file-13-stor-gprd.c.gitlab-production.internal
file-14-stor-gprd.c.gitlab-production.internal
file-15-stor-gprd.c.gitlab-production.internal
file-16-stor-gprd.c.gitlab-production.internal
geo-postgres-01-db-gprd.c.gitlab-production.internal
git-01-sv-gprd.c.gitlab-production.internal
lfs-01-stor-gprd.c.gitlab-production.internal
mailroom-01-sv-gprd.c.gitlab-production.internal
pages-01-stor-gprd.c.gitlab-production.internal
pgbouncer-01-db-gprd.c.gitlab-production.internal
postgres-01-db-gprd.c.gitlab-production.internal
postgres-04-db-gprd.c.gitlab-production.internal
redis-01-db-gprd.c.gitlab-production.internal
redis-cache-01-db-gprd.c.gitlab-production.internal
redis-cache-sentinel-01-db-gprd.c.gitlab-production.internal
registry-01-sv-gprd.c.gitlab-production.internal
runner-01-sv-gprd.c.gitlab-production.internal
share-01-stor-gprd.c.gitlab-production.internal
sidekiq-asap-01-sv-gprd.c.gitlab-production.internal
sidekiq-besteffort-01-sv-gprd.c.gitlab-production.internal
sidekiq-pages-01-sv-gprd.c.gitlab-production.internal
sidekiq-pipeline-01-sv-gprd.c.gitlab-production.internal
sidekiq-pullmirror-01-sv-gprd.c.gitlab-production.internal
sidekiq-realtime-01-sv-gprd.c.gitlab-production.internal
sidekiq-traces-01-sv-gprd.c.gitlab-production.internal
web-01-sv-gprd.c.gitlab-production.internal
api-02-sv-gprd.c.gitlab-production.internal
bastion-02-inf-gprd.c.gitlab-production.internal
consul-02-inf-gprd.c.gitlab-production.internal
fe-02-lb-gprd.c.gitlab-production.internal
fe-altssh-02-lb-gprd.c.gitlab-production.internal
fe-pages-02-lb-gprd.c.gitlab-production.internal
git-02-sv-gprd.c.gitlab-production.internal
mailroom-02-sv-gprd.c.gitlab-production.internal
postgres-02-db-gprd.c.gitlab-production.internal
redis-02-db-gprd.c.gitlab-production.internal
redis-cache-02-db-gprd.c.gitlab-production.internal
redis-cache-sentinel-02-db-gprd.c.gitlab-production.internal
registry-02-sv-gprd.c.gitlab-production.internal
sidekiq-asap-02-sv-gprd.c.gitlab-production.internal
sidekiq-besteffort-02-sv-gprd.c.gitlab-production.internal
sidekiq-pages-02-sv-gprd.c.gitlab-production.internal
sidekiq-pipeline-02-sv-gprd.c.gitlab-production.internal
sidekiq-pullmirror-02-sv-gprd.c.gitlab-production.internal
sidekiq-realtime-02-sv-gprd.c.gitlab-production.internal
sidekiq-traces-02-sv-gprd.c.gitlab-production.internal
web-02-sv-gprd.c.gitlab-production.internal
```

### Hosts for gstg

```
alerts-01-inf-gstg.c.gitlab-staging-1.internal
consul-03-inf-gstg.c.gitlab-staging-1.internal
kibana-01-inf-gstg.c.gitlab-staging-1.internal
performance-01-inf-gstg.c.gitlab-staging-1.internal
prometheus-01-inf-gstg.c.gitlab-staging-1.internal
prometheus-app-01-inf-gstg.c.gitlab-staging-1.internal
sidekiq-besteffort-03-sv-gstg.c.gitlab-staging-1.internal
api-01-sv-gstg.c.gitlab-staging-1.internal
artifacts-01-stor-gstg.c.gitlab-staging-1.internal
bastion-01-inf-gstg.c.gitlab-staging-1.internal
console-01-sv-gstg.c.gitlab-staging-1.internal
consul-01-inf-gstg.c.gitlab-staging-1.internal
deploy-01-sv-gstg.c.gitlab-staging-1.internal
fe-01-lb-gstg.c.gitlab-staging-1.internal
fe-altssh-01-lb-gstg.c.gitlab-staging-1.internal
fe-pages-01-lb-gstg.c.gitlab-staging-1.internal
file-01-stor-gstg.c.gitlab-staging-1.internal
file-02-stor-gstg.c.gitlab-staging-1.internal
geo-postgres-01-db-gstg.c.gitlab-staging-1.internal
git-01-sv-gstg.c.gitlab-staging-1.internal
lfs-01-stor-gstg.c.gitlab-staging-1.internal
mailroom-01-sv-gstg.c.gitlab-staging-1.internal
pages-01-stor-gstg.c.gitlab-staging-1.internal
pgbouncer-01-db-gstg.c.gitlab-staging-1.internal
postgres-01-db-gstg.c.gitlab-staging-1.internal
redis-01-db-gstg.c.gitlab-staging-1.internal
redis-cache-01-db-gstg.c.gitlab-staging-1.internal
registry-01-sv-gstg.c.gitlab-staging-1.internal
share-01-stor-gstg.c.gitlab-staging-1.internal
sidekiq-asap-01-sv-gstg.c.gitlab-staging-1.internal
sidekiq-besteffort-01-sv-gstg.c.gitlab-staging-1.internal
sidekiq-besteffort-04-sv-gstg.c.gitlab-staging-1.internal
sidekiq-pages-01-sv-gstg.c.gitlab-staging-1.internal
sidekiq-pullmirror-01-sv-gstg.c.gitlab-staging-1.internal
sidekiq-realtime-01-sv-gstg.c.gitlab-staging-1.internal
sidekiq-traces-01-sv-gstg.c.gitlab-staging-1.internal
web-01-sv-gstg.c.gitlab-staging-1.internal
consul-02-inf-gstg.c.gitlab-staging-1.internal
fe-02-lb-gstg.c.gitlab-staging-1.internal
fe-altssh-02-lb-gstg.c.gitlab-staging-1.internal
fe-pages-02-lb-gstg.c.gitlab-staging-1.internal
postgres-02-db-gstg.c.gitlab-staging-1.internal
sidekiq-besteffort-02-sv-gstg.c.gitlab-staging-1.internal
sidekiq-besteffort-05-sv-gstg.c.gitlab-staging-1.internal
```
