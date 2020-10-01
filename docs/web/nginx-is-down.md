# Nginx is down

Nginx sits between HAProxy and gitlab-workhorse, which means a wide-spread of nginx instances being
down could bring GitLab.com down completely or put a lot of stress on unaffected nodes.

## Invalid configurations

Nginx can be down because of invalid configurations. Check `/var/log/gitlab/nginx/current` for
lines similar to `[emerg] invalid parameter "xyz" in /var/opt/gitlab/nginx/conf/some-file.conf:8`.
If found, then a recent update has been made to Nginx Chef attributes and they need to be reverted or
rectified, followed by running `chef-client` on the affected hosts.
