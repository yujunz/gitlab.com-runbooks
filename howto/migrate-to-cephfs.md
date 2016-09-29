# Migrate a project to CephFS

Our CephFS repository storage is located in `/var/opt/gitlab/git-data-ceph` and named `ceph`

## What is this for?

To migrate projects to CephFS repository storage.

## Getting access to it

You have to be a GitLab employee to have access to it.

## How to

### Run the following curl command

TOKEN == Admin token

ID == Project ID
```
curl --request PUT --header "PRIVATE-TOKEN: TOKEN" -d repository_storage=ceph https://gitlab.com/api/v3/projects/ID
```
