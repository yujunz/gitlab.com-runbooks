# Managing unicorn and sidekiq workers

## First and foremost

*Don't Panic*

## How do I

### Reload unicorn with zero downtime

Issue the following command from the chef repo:

`bundle exec knife ssh -aipaddress role:gitlab-cluster-worker 'sudo gitlab-ctl hup unicorn'`

### How to perform zero downtime frontend host reboot

For some specific cases, your only option will be restarting the `unicorn` process (for example change the `listen` directive). In this case, a restart will induce 5XX HTTP codes, and that's bad.

Using [HAProxy's set server directive](http://cbonte.github.io/haproxy-dconv/1.6/management.html#9.2-set%20server) we can change server `state` between `ready` and `maint` status so ongoing requests can finish and new requests will be routed to a different server.

We can enable/disable specific servers on specific backends with the following command:
```
bundle exec knife ssh -C 1 -p 2222 -a ipaddress 'roles:gitlab-base-lb-fe' "echo 'set server <backend_name>/<backend_server_name> state <ready|maint>' | sudo socat stdio /run/haproxy/admin.sock"
```

You can look for <backend_name> and <backend_server_name> in HAProxy's configuration, in any of the `feXX.lb.gitlab.com` nodes in `/etc/haproxy/haproxy.conf` file.

After disabling a node, make sure you check that all client connections are gone, then run `sudo gitlab-ctl restart unicorn`. On a `web` node, for example, we would check for connections to port 443 with `sudo netstat -pnta | grep nginx | grep -c ESTAB`.

### Gracefully restart sidekiq jobs

Issue the following command from the chef repo:

```
bundle exec knife ssh -C 10 -a ipaddress 'role:gitlab-cluster-worker' '
sudo /opt/gitlab/init/sidekiq 1; echo "Waiting workers 60s" ; sleep 60 ; sudo gitlab-ctl restart sidekiq'
```

This command will send a signal to stop picking jobs, then it'll wait 1 minute and then
force a restart in all the workers, 10 workers at a time.

### Update packages fleet wide

This happens every Monday morning automagically, still, it is necessary to do it manually
it's important to lock the version of gitlab-ee to not have it redeployed accidentally, so use this command

```shell
bundle exec knife ssh -aipaddress 'role:bla' 'sudo apt-mark hold gitlab-ee; sudo apt-get update; sudo apt-get -y dist-upgrade; sudo apt-mark unhold gitlab-ee'
```
