# Redis monitoring

Redis has a built in command for monitoring the commands that are being executed on a Redis server: `MONITOR`.

Unfortunately, this is not suitable for production, as it can have up to a 50% impact on server throughput.

## Monitoring a Redis Instance without using MONITOR

This guide describes a technique that will not have a major performance
impact. It does the following:

1. Captures Redis traffic via `tcpdump`.
2. Uses [tcp-flow](https://github.com/simsong/tcpflow/) to read the
packet capture data and to save a separate file for each TCP flow.
3. Runs a custom script to aggregate the results.

### Capturing traffic and downloading it to your local machine

On the *master* Redis server, capture TCP packets and compress them with the following commands:

```shell
$ sudo timeout 30 tcpdump -s 65535 tcp port 6379 -w redis.pcap -i ens4
tcpdump: listening on ens4, link-type EN10MB (Ethernet), capture size 65535 bytes
676 packets captured
718 packets received by filter
0 packets dropped by kernel

$ gzip redis.pcap
```

now download and decompress the capture with:
```shell
$ scp redis-cache-01-db-gstg.c.gitlab-staging-1.internal:redis.pcap.gz .
$ gunzip redis.pcap.gz
```

remember to remove the pcap file once you're done!

### Analyzing Redis traffic

#### get the number of commands sent to redis ####

1. install tcpflow (on MacOS: `brew install tcpflow`)
1. get the number of commands that are issued to redis with:
```shell
$ tcpflow -o redis-analysis -r redis.pcap
$ cd ./redis-analysis/
$ find . -name '*.06379'|xargs -n 1 perl -0777  -pe 's/\*\d+\r\n\$\d+\r\n(\w+)\r\n\$\d+\r\n([\w\d:]+)/command: $1 $2/gsx;'|grep -a '^command'|grep -v "command: auth "|sort|uniq -c|sort -nr > ./script_report
$ less ./script_report
70334 command: setex peek:requests:
69205 command: get cache:gitlab:geo:current_node:12.0.0-pre:5.1.7
69178 command: get cache:gitlab:geo:node_enabled:12.0.0-pre:5.1.7
65642 command: get cache:gitlab:flipper/v1/feature/enforced_sso_requires_session
(...)
```

# Please remember to delete the `pcap` file immediately after performing the analysis

