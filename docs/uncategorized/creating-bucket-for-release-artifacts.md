# Release Artifact Bucket

We will occasionally get a request such as [this one](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10637)
that asks us to create a bucket for release artifacts. Currently we
create the bucket in the `gitlab-ops` account and give the requested
permissions. You can see an example of what to do in `terraform` by
looking at [this merge request](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/merge_requests/1996).
