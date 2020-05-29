# CI Runner Overview

We have several different kind of runners. Below is a brief overview of each.

- `shared-runners-manager`
- `gitlab-shared-runners-manager`
- `private-runners-manager`
- `gitlab-docker-shared-runners-manager`
- `windows-shared-runners-manager`

## Runner Descriptions

### Share Runners Manager (SRM)

These are the main runners our customers use. They are housed in the `gitlab-ci` project.
Each machine is used for one build and then rebuilt. See [`gitlab-ci` network](#gitlab-ci-project)
for subnet information.

### gitlab-shared-runners-manager (GSRM)

These runners are used for GitLab application tests. They can be used by customer forks of the
GitLab application. These are also housed in the `gitlab-ci` project. See [`gitlab-ci` network](#gitlab-ci-project)
for subnet information.

### private-runners-manager (PRM)

These runners are added to the `gitlab-com` and `gitlab-org` groups for internal GitLab use
only. They are also added to the ops instance as shared runners for the same purpose. They
have privileged mode on. See [`gitlab-ci` network](#gitlab-ci-project) for subnet information.

### gitlab-docker-shared-runners-manager (GDSRM)

These are the newest runners we have. They are used for all of our open source projects under
the `gitlab-org` group. They are also referred to as `org-ci` runners. These are housed in the
`gitlab-org-ci` project. For further info please see the [org-ci README](./cicd/org-ci/README.md).
For network information see [gitlab-org-ci networking](#gitlab-org-ci-project).

### windows-shared-runners-manager (WSRM)

As the name suggests, these are runners that spawn Windows machines. They are currently in
beta. They are housed in the `gitlab-ci-windows` project. For further info please see the
[windows CI README](./cicd/windows/README.md). For network information see [gitlab-ci-windows networking](#gitlab-ci-windows-project).

## Network Info

Below is the networking information for each project.

### gitlab-ci project

These subnets are created under the `default` network.

| Subnet Name           | CIDR          | Purpose                                              |
| --------------------- | ------------- | ---------------------------------------------------- |
| default               | 10.142.0.0/20 | all non-runner machines (managers, prometheus, etc.) |
| shared-runners        | 10.0.32.0/20  | shared runner (SRM) machines                         |
| private-runners       | 10.0.0.0/20   | private runner (PRM) machines                        |
| gitlab-shared-runners | 10.0.16.0/20  | gitlab shared runner (GSRM) machines                 |

### gitlab-org-ci project

These subnets are created under the `org-ci` network.

| Subnet Name   | CIDR        | Purpose                   |
| ------------- | ----------- | ------------------------- |
| manager       | 10.1.0.0/24 | Runner manager machines   |
| bastion       | 10.1.2.0/24 | bastion network           |
| shared-runner | 10.2.0.0/16 | Ephemeral runner machines |

### gitlab-ci-windows project

These subnets are created under the `windows-ci` network.

| Subnet Name        | CIDR        | Purpose                           |
| ------------------ | ----------- | --------------------------------- |
| manager-subnet     | 10.1.0.0/16 | Runner manager machines           |
| executor-subnet    | 10.2.0.0/16 | Ephemeral runner machines         |
| bastion-windows-ci | 10.3.1.0/24 | bastion network                   |
| runner-windows-ci  | 10.3.0.0/24 | Runner network for ansible/packer |
