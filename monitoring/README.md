## Monitoring with Prometheus

### Login to prometheus console

1. Login to the [prometheus server](https://prometheus.gitlab.com) instance using your dev.gitlab.com account.

### List of jobs which are scraped

1. Login to prometheus console
1. With the query `up==1` you can get list of jobs for which scrappers are works
1. With the query `up==0` you can get list of jobs for which scrappers are not working

### Check if alertmanager is working

1. Login to prometheus console
1. If `up{job="alertmanager"}` is 0 then alertmanager is not receiving data from prometheus. Alertmanager can be down.
1. If result is 1, then alertmanager is working.
