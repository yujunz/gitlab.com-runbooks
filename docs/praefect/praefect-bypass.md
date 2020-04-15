# Bypass Praefect

In case of a catastrofic failure on Praefect you may opt for bypassing it and
having clients access Gitaly directly. This will disrupt replication but it may
become necessary to prevent an extended outage.

## Steps

1. Check the `omnibus-gitlab.gitlab_rb.praefect.virtual_storages` configuration
  on chef-repo for the mapping of shards to underlying file storages (for gprd,
  these live on `roles/gprd-base.json`)
1. Update `omnibus-gitlab.gitlab_rb.git_data_dirs` to replace each shard served
  via Praefect to point directly to the Gitaly client on the file server marked
  as `primary` in the Praefect configuration.

    For example, if `virtual_storages` contains:

    ```json
      "virtual_storages": {
        "praefect-file01": {
          "file-praefect-01": {
            "address": "tcp://file-praefect-01-stor-gprd.c.gitlab-production.internal:9999",
            "token": "get_me_from_vault",
            "primary": true
          },
          "file-praefect-02": {
            "address": "tcp://file-praefect-02-stor-gprd.c.gitlab-production.internal:9999",
            "token": "get_me_from_vault"
          }
        }
      }
    ```

    Then the following `git_data_dirs` configuration:

    ```json
      "git_data_dirs": {
        ...
        "nfs-file49": {
          "path": "/var/opt/gitlab/git-data-file49",
          "gitaly_address": "tcp://file-49-stor-gprd.c.gitlab-production.internal:9999"
        },
        "praefect-file01": {
          "path": "/var/opt/gitlab/git-data-praefect-file01",
          "gitaly_address": "tcp://i.gprd-gcp-tcp-lb-internal-praefect.il4.us-east1.lb.gitlab-production.internal:2305"
        },
        ...
      }
    ```

    becomes:

    ```json
      "git_data_dirs": {
        ...
        "nfs-file49": {
          "path": "/var/opt/gitlab/git-data-file49",
          "gitaly_address": "tcp://file-49-stor-gprd.c.gitlab-production.internal:9999"
        },
        "praefect-file01": {
          "path": "/var/opt/gitlab/git-data-praefect-file01",
          "gitaly_address": "tcp://file-praefect-01-stor-gprd.c.gitlab-production.internal:9999"
        },
        ...
      }
    ```

1. Create a chef-repo MR with those changes. Merge and apply.
1. Run `knife ssh roles:gprd-base "sudo chef-client"` to apply the changes
  inmediately.
1. Create a rollback MR to ensure traffic is re-routed through Praefect once the
  underlying problem is addressed. Replication should resume on its own.
