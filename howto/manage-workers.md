# Managing unicorn and sidekiq workers

## First and foremost

*Don't Panic*

## How do I

### Restart unicorn with a zero downtime

Issue the following command from the chef repo:

`bundle exec knife ssh -aipaddress role:gitlab-cluster-worker 'sudo gitlab-ctl hup unicorn'`

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
