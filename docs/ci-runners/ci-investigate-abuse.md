# Investigating Abuse Reports

Sometimes we receive abuse reports from Digital Ocean regarding something
our docker-machines have done. This can be the result of a malicious user
or it could also be a mistake. Usually the abuse report will give you the
IP address and sometimes the Droplet name. We only use each droplet for
one build before it is destroyed.

## Do a search through logs

First, let's log into https://log.gprd.gitlab.net/

To find if the IP was used by Runner:

1. Set Time Range to a time close to time declared in abuse report (e.g. if the
   report mentions that abusive usage was recorded at 2017-08-17 17:05 UTC, then
   set time range between 2h before and 2h after this time).
1. Execute a query: `program:"gitlab-runner" AND "docker=\"tcp://12.34.56.78"` where
   `12.34.56.78` is the IP address mentioned in abuse report.

If there is no results, then try to extend the time range of the search. If still
there is no results - the IP was not used by us.

If we will have any results then we should check when the machine was created:

```
Aug 17 16:16:16 shared-runners-manager-2.gitlab.com gitlab-runner[27141]: time="2017-08-17T16:16:16Z" level=info msg="Starting docker-machine build..." created=2017-08-17 16:14:36.793271703 +0000 UTC docker="tcp://67.205.164.213:2376" job=__REDACTED_JOB_ID__ name=runner-4e4528ca-machine-1502986476-1bb8514e-digital-ocean-2gb now=2017-08-17 16:16:16.116372198 +0000 UTC project=__REDACTED_PROJECT_ID__ runner=4e4528ca usedcount=1 #012<nil>
```

In the example above we see that the machine was created at `2017-08-17 16:14:36.793271703 +0000 UTC`.

From the created field and from the date/time when the line was logged we can decide if
searched IP meets the criteria from abuse report. This is important if machine can be used more than
once (so MaxBuilds setting in Runner's `config.toml` is greater than `1`) because then we need to
repeat further steps for each job that was executed in requested time. But if date/time information
is not related to reported incident, then most probably we're not the source of abusive activity.

In this record we can also see the ID of the job that used the machine: `job=__REDACTED_JOB_ID__` and the ID
of the project that started the job: `project=__REDACTED_PROJECT_ID__`.

If such data would suggest that the IP was used by us during the time reported in abuse report,
then we should execute another query: `program:"gitlab-runner" AND "job=REDACTED_JOB_ID" AND "Checking for jobs"`.
The result could look like:

```
Aug 17 16:16:13 shared-runners-manager-2.gitlab.com gitlab-runner[27141]: time="2017-08-17T16:16:13Z" level=info msg="Checking for jobs... received" job=__REDACTED_JOB_ID__ repo_url="https://gitlab.com/__REDACTED_GROUP__/__REDACTED_PROJECT__.git" runner=4e4528ca #012<nil>
```

From this you can go to https://gitlab.com/__REDACTED_GROUP__/__REDACTED_PROJECT__/-/jobs/__REDACTED_JOB_ID__ to look what was happening in such job and if it's an abusive usage.

## What if it is our fault?

If the node in question happens to still be on, shut it down. It is likely inactive anyway.
We should look into the source code of the job if malicious activity is actually traced back
to a job and project.

## Resolving with Digital Ocean

These results are initiated by Digital Ocean. Thus, to resolve them we simply reply to the
DO ticket and close it.

## Manual search through logs

We can use the logs on the `shared-runners-manager` servers to identify
when the build happened and what project it was associated with.

If they give you the hostname of the droplet, you can find which manager it
is on by the name.

### Determine which manager ran the build

Given the droplet name `runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb` and IP
address `162.243.119.18`, `8a2f473d` is the first few characters of the token the ci runner uses.
This token is unique per shared manager. Using this information you can find out which runner
this is by checking the `/etc/gitlab-runner/config.toml` config.

```
$ sudo grep 8a2f473d /etc/gitlab-runner/config.toml
token = "8a2f473dxxxxx"
```

### Find information on build

You can then search through the logs on that server for information on that server.

```
$ sudo zgrep runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb /var/log/upstart/gitlab-runner.log*
/var/log/upstart/gitlab-runner.log.2.gz:(runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb) Creating SSH key...
/var/log/upstart/gitlab-runner.log.2.gz:(runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb) Creating Digital Ocean droplet...
/var/log/upstart/gitlab-runner.log.2.gz:(runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb) Waiting for IP address to be assigned to the Droplet...
/var/log/upstart/gitlab-runner.log.2.gz:(runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb) Created droplet ID 25707737, IP address 162.243.119.18
/var/log/upstart/gitlab-runner.log.2.gz:To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb
/var/log/upstart/gitlab-runner.log.2.gz:INFO[490268] Machine created                               fields.time=41.287847806s name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:13:00.486139952 +0000 UTC time=41.287847806s
/var/log/upstart/gitlab-runner.log.2.gz:INFO[490353] Starting docker-machine build...              build=__REDACTED_JOB_ID__ created=2016-09-14 05:12:19.194805069 +0000 UTC docker=tcp://162.243.119.18:2376 name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:14:26.046959918 +0000 UTC project=__REDACTED_PROJECT_ID__ runner=8a2f473d usedcount=1
/var/log/upstart/gitlab-runner.log.2.gz:INFO[490791] Finished docker-machine build: exit code 1    build=__REDACTED_JOB_ID__ created=2016-09-14 05:12:19.194805069 +0000 UTC docker=tcp://162.243.119.18:2376 name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:21:44.146434198 +0000 UTC project=__REDACTED_PROJECT_ID__ runner=8a2f473d usedcount=1
/var/log/upstart/gitlab-runner.log.2.gz:WARN[490793] Removing machine                              created=9m26.401884019s name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:21:45.596698457 +0000 UTC reason=Too many builds used=34.08µs
/var/log/upstart/gitlab-runner.log.2.gz:About to remove runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb
/var/log/upstart/gitlab-runner.log.2.gz:Successfully removed runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb
/var/log/upstart/gitlab-runner.log.2.gz:INFO[490793] Machine removed                               created=9m26.816163983s name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:21:46.010975786 +0000 UTC reason=Too many builds used=413.850825ms
```

The following line will show you which build ID is associated with this server:

```
/var/log/upstart/gitlab-runner.log.2.gz:INFO[490353] Starting docker-machine build...              build=__REDACTED_JOB_ID__ created=2016-09-14 05:12:19.194805069 +0000 UTC docker=tcp://162.243.119.18:2376 name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:14:26.046959918 +0000 UTC project=__REDACTED_PROJECT_ID__ runner=8a2f473d usedcount=1
```

The build ID in this case is `__REDACTED_JOB_ID__` which we can grep through the logs for to
determine which project created the build.

### Determine which project created the build

```
$ sudo zgrep __REDACTED_JOB_ID__ /var/log/upstart/gitlab-runner.log.2.gz
INFO[490352] Checking for builds... received               build=__REDACTED_JOB_ID__ repo_url=https://gitlab.com/__REDACTED_GROUP__/__REDACTED_PROJECT__.git runner=8a2f473d
INFO[490353] Starting docker-machine build...              build=__REDACTED_JOB_ID__ created=2016-09-14 05:12:19.194805069 +0000 UTC docker=tcp://162.243.119.18:2376 name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:14:26.046959918 +0000 UTC project=__REDACTED_PROJECT_ID__ runner=8a2f473d usedcount=1
INFO[490791] Finished docker-machine build: exit code 1    build=__REDACTED_JOB_ID__ created=2016-09-14 05:12:19.194805069 +0000 UTC docker=tcp://162.243.119.18:2376 name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:21:44.146434198 +0000 UTC project=__REDACTED_PROJECT_ID__ runner=8a2f473d usedcount=1
WARN[490791] Build failed: exit code 1                     build=__REDACTED_JOB_ID__ project=__REDACTED_PROJECT_ID__ runner=8a2f473d
```

Now that we have a lot of information on the matter, we can search the IP address in the
logs to correlate to the time of the abuse report.

### Associate time and server

```
# on SM1
shared-runners-manager-1:~$ sudo zgrep 162\.243\.119\.18 /var/log/upstart/gitlab-runner.log* | grep created=2016-09-13
shared-runners-manager-1:~$ sudo zgrep 162\.243\.119\.18 /var/log/upstart/gitlab-runner.log* | grep now=2016-09-13
shared-runners-manager-1:~$

# on SM2
shared-runners-manager-2:~$ sudo zgrep 162\.243\.119\.18 /var/log/upstart/gitlab-runner.log* | grep created=2016-09-13
shared-runners-manager-2:~$ sudo zgrep 162\.243\.119\.18 /var/log/upstart/gitlab-runner.log* | grep now=2016-09-13
shared-runners-manager-2:~$
```

In this case, the IP address and the time of the abuse report do not match up. As such, this was
most likely not us.
