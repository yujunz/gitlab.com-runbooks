# Workers under heavy load because of being used as a CDN

## First and foremost

*Don't Panic*

## Symptoms

* skyrocket increase of load in workers
  * ![Sample High Load on Workers](img/workers-high-load.png)
* decrease of connections
  * ![Sample of low HTTP connections](img/low-connections.png)
* decrease of database load
  * ![Sample of low database load](img/low-database-load.png)
* increase of git http processes
  * ![Sample of high count of git http processes](img/high-http-git-processes.png)
* Relevant Dashboard where to find all these graphs
  * http://performance.gitlab.net/dashboard/db/fleet-overview

## Possible checks

* Perform a count of all the http ssh processes that are a cat-file blob

```
knife ssh 'role:<cluster-role>' "ps -U git -o cmd | grep 'cat-file blob' | grep -v grep | sort | uniq -c -u"
```

## Resolution

* Set the project as logically deleted to prevent requests from reaching the git layer.

```
sudo gitlab-rails console
proj = Project.find_with_namespace('group/project_name') # the path without the .git
proj.pending_delete = true
proj.save
```

* Kill them all

```
knife ssh 'role:<cluster-role>' "for p in \$(ps -U git -o pid,cmd | grep <object-id> | grep -v grep | awk '{ print \$1 }'); do kill -9 \$p; done"
```

## Post Checks

Count processes again and monitor the initially referred dashboard
