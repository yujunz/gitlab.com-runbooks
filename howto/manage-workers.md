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
