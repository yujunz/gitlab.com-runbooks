# Gitaly version mismatch

## Symptoms

* Multiple versions of Gitaly are running within a fleet.

## 1. Figure out which version of Gitaly are running, and on what hosts

Visit the [Gitaly Version Tracker](https://dashboards.gitlab.net/dashboard/db/gitaly-version-tracker?orgId=1&var-environment=gprd)
dashboard to find out which versions are running on each host.

If a deployment is currently being carried out there may be two versions running alongside
one another for a period of up to 30 minutes.

Longer periods indicate a problem with the deployment, including

* Have hosts been skipped from the deployment?
* Is the deployment stuck?

## 2. Figure out which version of Gitaly is the expected version

1. `/chatops run auto_deploy status`
1. Click on the production revision
1. Click "Browse files"
1. Open "GITALY_SERVER_VERSION"

## Known scenarios

### Race condition during upgrade

Symptoms:

* The old gitaly process has forked its child, but has not exited. Note that
  Gitaly processes spawn many gitaly-ruby workers, do not confuse these for the
  new main gitaly process.
* `gitlab-ctl hup gitaly` fails
* The shard should be healthy, serving requests as normal - but subsequent
  gitaly deployments might fail. Some requests on the affected nodes will be
  served by outdated gitaly versions.

Resolution:

* Examine the process table, write down the pids of the "old" gitaly process
  ("the parent") that refuses to exit, and its main gitaly process child.
* Ensure that the gitaly binary has been replaced with the desired new version:
   * On the affected host: `/opt/gitlab/embedded/bin/gitaly --version`
* Follow `/var/log/gitlab/gitaly/current`
   * Look for logs with a "pid" field. Both parent and child PIDs should be
     serving requests successfully.
   * Keep following this log file throughout the resolution.
* `kill -9 <parent PID>`.
   * Note that this might interrupt in-flight requests, but there is not a more
     graceful solution to this problem at this time.
* `gitlab-ctl hup gitaly`. This should succeed. The process tree should appear
  "normal", with one main gitaly process with a set of gitaly-ruby worker
  children.

Example process tree:

```
root@file-praefect-02-stor-gprd.c.gitlab-production.internal:~# ps -ef --forest | grep gitaly
root     23333 23272  0 13:00 pts/0    00:00:00                      \_ grep gitaly
root      2798  2771  0 Apr09 ?        00:00:02  \_ runsv gitaly
root     30136  2798  0 Jun02 ?        00:00:28      \_ svlogd /var/log/gitlab/gitaly
git      16705  2798  0 Jul23 ?        00:00:11      \_ /opt/gitlab/embedded/bin/gitaly-wrapper /opt/gitlab/embedded/bin/gitaly /var/opt/gitlab/gitaly/config.toml
git      13658     1  2 Jul23 ?        00:38:02 /opt/gitlab/embedded/bin/gitaly /var/opt/gitlab/gitaly/config.toml
git      13688 13658  0 Jul23 ?        00:02:30  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.3
git      13689 13658  0 Jul23 ?        00:02:33  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.5
git      13697 13658  0 Jul23 ?        00:02:39  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.4
git      13699 13658  0 Jul23 ?        00:02:32  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.1
git      13701 13658  0 Jul23 ?        00:02:32  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.6
git      13705 13658  0 Jul23 ?        00:02:33  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.2
git      13706 13658  0 Jul23 ?        00:02:41  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.15
git      13708 13658  0 Jul23 ?        00:02:32  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.0
git      13710 13658  0 Jul23 ?        00:02:40  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.7
git      13716 13658  0 Jul23 ?        00:02:37  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.10
git      13723 13658  0 Jul23 ?        00:02:32  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.8
git      13724 13658  0 Jul23 ?        00:02:35  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.9
git      13725 13658  0 Jul23 ?        00:02:32  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.11
git      13726 13658  0 Jul23 ?        00:02:33  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.12
git      13727 13658  0 Jul23 ?        00:02:33  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.13
git      13728 13658  0 Jul23 ?        00:02:33  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.18
git      13731 13658  0 Jul23 ?        00:02:37  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.16
git      13740 13658  0 Jul23 ?        00:02:33  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.17
git      13741 13658  0 Jul23 ?        00:02:34  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.14
git      13744 13658  0 Jul23 ?        00:02:34  \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 13658 /var/opt/gitlab/gitaly/internal_sockets/ruby.19
git      12827 13658  5 11:54 ?        00:03:33  \_ /opt/gitlab/embedded/bin/gitaly /var/opt/gitlab/gitaly/config.toml
git      12853 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.0
git      12855 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.2
git      12866 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.1
git      12867 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.15
git      12874 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.3
git      12881 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.5
git      12883 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.4
git      12884 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.13
git      12885 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.12
git      12888 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.14
git      12890 12827  0 11:54 ?        00:00:08      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.17
git      12893 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.16
git      12897 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.8
git      12899 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.18
git      12900 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.9
git      12901 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.19
git      12903 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.6
git      12910 12827  0 11:54 ?        00:00:08      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.7
git      12912 12827  0 11:54 ?        00:00:08      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.11
git      12915 12827  0 11:54 ?        00:00:09      \_ ruby /opt/gitlab/embedded/service/gitaly-ruby/bin/gitaly-ruby 12827 /var/opt/gitlab/gitaly/internal_sockets/ruby.10
git      23079 12827 77 13:00 ?        00:00:24      \_ /opt/gitlab/embedded/bin/git --git-dir /var/opt/gitlab/git-data/repositories/@hashed/fa/53/fa539965395b8382145f8370b34eab249cf610d2d6f2943c95b9b9d08a63d4a3.git fetch --prune ssh://gitaly/internal.git +refs/*:refs/* --end-of-options
```

Example incident: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2452

Tracking issue: https://gitlab.com/gitlab-org/gitaly/-/issues/2988
