# Redis running out of keys

## Symptoms

You see an alert like

```
@channel redis3.cluster.gitlab.com service Redis_keys is UNKNOWN
```

Or you find this error message in the logs

```
unexpected error occurred in writing to Redis: ERR max number of clients reached
```

This is actually not so, the problem is that the redis server run out of connections and the applications cannot generate new ones

## Possible checks

* Go to the redis server checkmk page and check if tcp connections are increased and flatted out.
  * [redis3](https://checkmk.gitlap.com/gitlab/check_mk/index.py?start_url=%2Fgitlab%2Fpnp4nagios%2Findex.php%2Fgraph%3Fhost%3Dredis3.cluster.gitlab.com%26srv%3DTCP_Connections%26theme%3Dmultisite%26baseurl%3D..%2Fcheck_mk%2F)
  * [redis4](https://checkmk.gitlap.com/gitlab/check_mk/index.py?start_url=%2Fgitlab%2Fpnp4nagios%2Findex.php%2Fgraph%3Fhost%3Dredis4.cluster.gitlab.com%26srv%3DTCP_Connections%26theme%3Dmultisite%26baseurl%3D..%2Fcheck_mk%2F)
* The graph should look something like this
  * ![Maxed out tcp sessions on redis](img/redis-tcp-sessions.png)

## Resolution

* ssh into the redis master
* get redis password with `grep requirepass /var/opt/gitlab/redis/redis.conf`
* login into redis by running `/opt/gitlab/embedded/bin/redis-cli`
* Auth `auth PASSWORD` to gain permissions
* check that the timeout setting is 0 with `config get timeout`
* set the timeout setting `config set timeout 60`

## Post checks

* Check that the tcp sessions are dropping to stay flat
