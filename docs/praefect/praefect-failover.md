# Praefect has performed a failover

## Symptoms

* Alert: Praefect performed a failover for `xyz` virtual storage

## Actions

1. Identify the virtual storage under which a failover has occurred. It should be specified in the alert message.
1. Check for data loss on that virtual storage
    * On a Praefect node (e.g. `praefect-01-stor-gstg`), run the following command:
        ```
        sudo -u git /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss -virtual-storage nfs-file22
        ```
    * The output *does not* mean actual data loss. Instead, it shows
      there are still unreplicated changes from the old primary to the new one.
      It also shows any outdated replicas, which should be reconciled (see "The old primary is intact" below).
    * You can also use the
      [`gitaly_praefect_read_only_repositories`][read-only-metric] Prometheus
      metric to track the number of read-only repositories (which means they
      still have unreplicated changes)
1. Check the state of the old primary

### The old primary is intact

If the old primary and its data disk are intact, then once Gitaly is up and
running, Praefect should be able to process those changes. However, replication
jobs are attempted 3 times after which they are dropped and they happen
with no back-off so they end up being exhausted almost immediately.

To compensate for this fact, we to run `reconcile` to replicate from an
up-to-date node (replace the `virtual` value with the virtual storage in
question, `reference` value with the up-to-date node and the `target`
value with the outdated node):
```
$ tmux # Next command can take some time to finish
$ sudo -u git /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml reconcile -f -virtual nfs-file22 -reference <up-to-date-storage> -target file-04
```

This command traverses all repositories on the `target` replica, it will
schedule a replication job for a repository if its checksum across replicas
differs.

### The old primary is corrupt and no other replicas exist for this virtual storage

In this case we have a data loss, and it depends on the situation how to go
forward. Assuming it is OK to lose data for a given repository, run the
following command to accept the data loss and make the repository writable
again (replace `authoritative-storage` value with the current primary,
`virtual-storage` value with the virtual storage in question, and `repository`
value with the relative path of the repository to accept data loss for):

```
sudo -u git /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss\
  -virtual-storage nfs-file22 \
  -authoritative-storage file-04 \
  -repository @hashed/00/00/0000000000000000000000000000000000000000000000000000000000000000.git
```

[read-only-metric]: https://thanos-query.ops.gitlab.net/graph?g0.range_input=1h&g0.max_source_resolution=0s&g0.expr=max(gitaly_praefect_read_only_repositories%7Benv%3D%22gprd%22%2Cvirtual_storage%3D%22praefect-file01%22%7D)&g0.tab=0
