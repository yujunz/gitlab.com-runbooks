# postgres_exporter

We use [`postgres_exporter`](https://github.com/wrouesnel/postgres_exporter) to collect metrics
from a running PostgreSQL server. Metrics collected are internal to PostgreSQL (e.g. tuple statistics
or replication progress) and _not_ related to the actual data stored (e.g. number of archived projects).
For the latter, you may consider extending [gitlab-exporter](https://gitlab.com/gitlab-org/gitlab-exporter).

`postgres_exporter` is deployed by a Chef [recipe](https://gitlab.com/gitlab-cookbooks/gitlab-exporters/-/blob/master/recipes/postgres_exporter.rb)
in the [gitlab-exporters](https://gitlab.com/gitlab-cookbooks/gitlab-exporters) cookbook.

## Defining new metrics

New metrics can be defined in [`queries.yml`](https://gitlab.com/gitlab-cookbooks/gitlab-exporters/-/blob/master/files/default/postgres_exporter/queries.yaml).

1. Create a new MR with the changes in [`queries.yml`](https://gitlab.com/gitlab-cookbooks/gitlab-exporters/-/blob/master/files/default/postgres_exporter/queries.yaml) and the version
  in [`metadata.rb`](https://gitlab.com/gitlab-cookbooks/gitlab-exporters/-/blob/master/metadata.rb) bumped.
1. Get the MR approved and merged.
1. Consult the [workflow for cookbook changes](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/f29a0138a95895711777245ec431222093115b97/README.md#workflow-for-cookbook-changes)
  to get the change deployed to staging and then to production.
