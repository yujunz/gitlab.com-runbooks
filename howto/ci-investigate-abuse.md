# Investigating Abuse Reports

Sometimes we receive abuse reports from Digital Ocean regarding something
our docker-machines have done. This can be the result of a malicious user
or it could also be a mistake. Usually the abuse report will give you the
IP address and sometimes the Droplet name. We only use each droplet for 
one build before it is destroyed.

## Identifying the offender

We can use the logs on the `shared-runners-manager` servers to identify 
which when the build happened and what project it was associated with. 

If they give you the hostname of the droplet, you can find which manager it 
is on by the name.

### Determine which manager ran the build

Given the droplet name `runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb` and IP 
address `162.243.119.18`, 
`8a2f473d` is the first few characters of the token the ci runner uses. This token is unique
per shared manager. Using this information you can find out which runner this is by checking
the `/etc/gitlab-runner/config.toml` config.

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
/var/log/upstart/gitlab-runner.log.2.gz:INFO[490353] Starting docker-machine build...              build=4033980 created=2016-09-14 05:12:19.194805069 +0000 UTC docker=tcp://162.243.119.18:2376 name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:14:26.046959918 +0000 UTC project=<redacted project ID> runner=8a2f473d usedcount=1
/var/log/upstart/gitlab-runner.log.2.gz:INFO[490791] Finished docker-machine build: exit code 1    build=4033980 created=2016-09-14 05:12:19.194805069 +0000 UTC docker=tcp://162.243.119.18:2376 name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:21:44.146434198 +0000 UTC project=<redacted project ID> runner=8a2f473d usedcount=1
/var/log/upstart/gitlab-runner.log.2.gz:WARN[490793] Removing machine                              created=9m26.401884019s name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:21:45.596698457 +0000 UTC reason=Too many builds used=34.08µs
/var/log/upstart/gitlab-runner.log.2.gz:About to remove runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb
/var/log/upstart/gitlab-runner.log.2.gz:Successfully removed runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb
/var/log/upstart/gitlab-runner.log.2.gz:INFO[490793] Machine removed                               created=9m26.816163983s name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:21:46.010975786 +0000 UTC reason=Too many builds used=413.850825ms
```

The following line will show you which build ID is associated with this server:

```
/var/log/upstart/gitlab-runner.log.2.gz:INFO[490353] Starting docker-machine build...              build=4033980 created=2016-09-14 05:12:19.194805069 +0000 UTC docker=tcp://162.243.119.18:2376 name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:14:26.046959918 +0000 UTC project=<redacted project> runner=8a2f473d usedcount=1
```

The build ID in this case is `490353` which we can grep through the logs for to 
determine which project created the build.

### Determine which project created the build

```
$ sudo zgrep 4033980 /var/log/upstart/gitlab-runner.log.2.gz
INFO[490352] Checking for builds... received               build=4033980 repo_url=<redacted repo URL> runner=8a2f473d
INFO[490353] Starting docker-machine build...              build=4033980 created=2016-09-14 05:12:19.194805069 +0000 UTC docker=tcp://162.243.119.18:2376 name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:14:26.046959918 +0000 UTC project=<redacted project ID> runner=8a2f473d usedcount=1
INFO[490791] Finished docker-machine build: exit code 1    build=4033980 created=2016-09-14 05:12:19.194805069 +0000 UTC docker=tcp://162.243.119.18:2376 name=runner-8a2f473d-machine-1473829939-c241015e-digital-ocean-4gb now=2016-09-14 05:21:44.146434198 +0000 UTC project=<redacted project ID> runner=8a2f473d usedcount=1
WARN[490791] Build failed: exit code 1                     build=4033980 project=<redacted project ID> runner=8a2f473d
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

## What if it is our fault?

This needs to be determined.

## Resolving with Digital Ocean

These results are initiated by Digital Ocean. Thus, to resolve them we simply reply to the
DO ticket and close it. 
