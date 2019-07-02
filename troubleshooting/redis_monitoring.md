# Redis monitoring

Redis has a built in command for monitoring the commands that are being executed on a Redis server: `MONITOR`.

Unfortunately, this is not suitable for production, as it can have up to a 50% impact on server throughput.

## Monitoring a Redis Instance without using MONITOR

This guide describes a technique that will not have a major performance impact. It uses `tcpdump` to analyze network traffic bound for Redis,
and a tool called [`redis-traffic-stats`](https://github.com/hirose31/redis-traffic-stats) to perform an analysis of the dumped traffic.

Visit https://github.com/hirose31/redis-traffic-stats#recommended-installation for full details of how to install `redis-traffic-stats` on your workstation.

### Capturing traffic

On the master Redis server, capture TCP packets using the following command.

```shell
$ sudo tcpdump -s 65535 tcp port 6379 -w redis.pcap -i ens4
tcpdump: listening on ens4, link-type EN10MB (Ethernet), capture size 65535 bytes
^C676 packets captured
718 packets received by filter
0 packets dropped by kernel

$ gzip redis.pcap
```

### Analyzing Redis traffic

Once you have the pcap file, transfer it to your local instance for further analysis.

```shell
$  scp redis-cache-01-db-gstg.c.gitlab-staging-1.internal:redis.pcap.gz .
$ gunzip redis.pcap.gz
$ # Now, run redis-traffic-stats ....
$ redis-traffic-stats -r redis.pcap
# redis-traffic-stats

## Summary

* Duration:
    * 2019-07-02 14:17:13 - 2019-07-02 14:17:31 (18s)
* Total Traffic:
    * 474 bytes (26.33 bytes/sec)
* Total Requests:
    * 98 requests (Avg 5.44 req/sec, Peak 98.00 req/sec)

## Top Commands

### By count
Command          | Count  | Pct    | Req/sec
-----------------|-------:|-------:|---------:
PING             |     50 |  51.02 |     2.78
PUBLISH          |     42 |  42.86 |     2.33
INFO             |      6 |   6.12 |     0.33

### By traffic
Command          | Bytes     | Byte/sec
-----------------|----------:|-------------:
PUBLISH          |       365 |        20.28
PING             |        85 |         4.72
INFO             |        24 |         1.33

## Command Detail

### PUBLISH
Key                | Bytes     | Byte/sec     | Count  | Pct    | Req/sec
-------------------|----------:|-------------:|-------:|-------:|---------:
__sentinel__:hello |       365 |        20.28 |     42 | 100.00 |     2.33

### PING
Key                | Bytes     | Byte/sec     | Count  | Pct    | Req/sec
-------------------|----------:|-------------:|-------:|-------:|---------:

### INFO
Key                | Bytes     | Byte/sec     | Count  | Pct    | Req/sec
-------------------|----------:|-------------:|-------:|-------:|---------:

## Slow Commands

Time   | Command
------:|------------------------------------------------------------------------
18.073 | PUBLISH __sentinel__:hello 10.224.8.121,26379,be4a8e32252f7e399d2d33d6...
18.073 | PING
18.073 | PUBLISH __sentinel__:hello 10.224.8.121,26379,be4a8e32252f7e399d2d33d6...
18.073 | PING
18.073 | INFO
```

# Please remember to delete the `pcap` file immediately after performing the analysis

