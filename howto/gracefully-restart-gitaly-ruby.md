# Gracefully restart gitaly-ruby

If you need to restart gitaly-ruby manually (perhaps because you're applying a patch from https://dev.gitlab.org/gitlab/post-deployment-patches) you can do so without downtime, thanks to gitaly-ruby worker redundancy, the following way:

```bash
# Wait 5 seconds between killing gitaly-ruby workers so that the next one available has time to take over
$ pgrep -f /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby | while read i; do echo $i; sudo kill $i; sleep 5; done
```

Every time you kill a gitaly-ruby worker a new process will be spawn to replace it, so by the end of the previous command you should have a refreshed gitaly-ruby process fleet.

Of course, if you need to gracefully restart all workers through the storage fleet you can do so through `knife`:

## Staging

```bash
$ bundle exec knife ssh 'roles:gstg-base-stor-nfs' 'pgrep -f /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby | while read i; do echo $i; sudo kill $i; sleep 5; done'
```

## Production

```bash
$ bundle exec knife ssh 'roles:gprd-base-stor-nfs' 'pgrep -f /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby | while read i; do echo $i; sudo kill $i; sleep 5; done'
```
