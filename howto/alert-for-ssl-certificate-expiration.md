# Alert about SSL certificate expiration

## Modify list of hosts with SSL certificate

By editing list inside `prometheus.jobs.blackbox-ssl.target` attribute in the role `prometheus-server` on chef, you can add or remove server from monitoring for SSL certificate expiration. By adding server there you will be receiving alerts when there is less than 30 days remain for certificate expiration.
