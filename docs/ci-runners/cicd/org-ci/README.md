# org-ci runners

We are now operating a new set of shared runners in the `org-ci` environment.
These runners are designed to be used on projects in the `gitlab-org` namespace
that may have community contributions.
They are built in a new GCP Project to be separated from our current runners,
both because we were asked to as well as making it easier to identify costs.
There are 3 managers in `us-east1` and one manager in `us-central1`

The runner managers are configured in [terraform](https://gitlab.com/gitlab-com/gitlab-com-infrastructure/)
in the [org-ci](https://gitlab.com/gitlab-com/gitlab-com-infrastructure/-/tree/master/environments/org-ci)
environment. They are built using a [terraform module](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/ci-manager)
specifically for CI Runners.

The main chef role is `org-ci-base` with `org-ci-base-runner` as the base role for all manager.
There is an additional role for each region that a manager may be built in in order to set
appropriate region/zone specific configurations.

## Network

| Subnet Name   | CIDR        | Purpose                   |
| ------------- | ----------- | ------------------------- |
| manager       | 10.1.0.0/24 | Runner manager machines   |
| bastion       | 10.1.2.0/24 | bastion network           |
| shared-runner | 10.2.0.0/16 | Ephemeral runner machines |
