# Dashboard Source

This folder is used to keep the source for some of our Grafana dashboards, checked into, and managed by, git.

On `master` builds, the dashboards will be uploaded to https://dashboards.gitlab.com. Any local changes to these dashboards on
the Grafana instance will be overwritten.

The dashboards are kept in [`grafonnet`](https://github.com/grafana/grafonnet-lib) format, which is based on the [jsonnet template language](https://jsonnet.org/).

# File nomenclature

We utilize the following file format: `dashboards/<service name, aka type>/<dashboard name>.dashboard.libsonnet`

Using this consistent schema makes URLs consistent, etc.

Example, the Container Registry is of service type `registry`.  Therefore,
`dashboards/registry/<somedashboard>.dashboard.libsonnet`

# Local Development

* Install `jsonnet`, `jq` and `curl`
  * On a Mac, `jsonnet` can be installed with `brew install jsonnet` (you'll
    need at least v0.15.0)
  * On Linux, you'll need to build the binary yourself, or use the docker image: `docker run --rm registry.gitlab.com/gitlab-com/runbooks/jsonnet:latest`
* Install `jb` [jsonet bundler](https://github.com/jsonnet-bundler/jsonnet-bundler)
  * `GO111MODULE="on" go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb`
* Update vendor dependencies
  * `(cd dashboards && jb install)`

# Testing Your Changes

* All users with viewer access to dashboards.gitlab.net, (ie, all GitLab team members), have full permission to edit all dashboards in the Playground Grafana folder: https://dashboards.gitlab.net/dashboards/f/playground-FOR-TESTING-ONLY/playground-for-testing-purposes-only
* You can create dashboards in this folder using the Grafana Web UI
* Alternatively, you can test your Grafonnet changes here using the following method:
  1. Clone git@gitlab.com:gitlab-com/runbooks.git and test your changes locally
  1. In the 1password Team Vault, lookup the API key stored in `dashboards.gitlab.net Grafana Playground API Key`
  1. Edit the `dashboards/.env.sh` file and add the following content: `export GRAFANA_API_TOKEN=<1PASSWORD API KEY VALUE>`
  1. In your shell, in the `dashboards` directory, run `. .env.sh`
  1. To upload your dashboard, run `./test-dashboard.sh dashboard-folder-path/file.dashboard.jsonnet`. It will upload the file and return a link to your dashboard.
  1. `./test-dashboard.sh -D $dashboard_path` will echo the dashboard JSON for pasting into Grafana.
* **Note that the playground is transient. By default, they will be deleted after 24 hours. Do not include links to playground dashboards in the handbook or other permanent content. **

# Editing Files

* Dashboards should be kept in files with the following name: `/dashboards/[grafana_folder_name]/[name].dashboard.jsonnet`
  * `grafana_folder_name` refers to the grafana folder where the files will be uploaded to. Note that the folder must already be created.
  * These can be created via `./create-grafana-folder.sh <grafana_folder_name> <friendly name>`
  * Example: `./create-grafana-folder.sh registry 'Container Registry'`
  * Note that if a folder already contains the name, it'll need to be removed or
    renamed in order for the API to accept the creation of a new folder
* Obtain a API key to the Grafana instance and export it in `GRAFANA_API_TOKEN`:
  * `export GRAFANA_API_TOKEN=123`
* To upload the files, run `./dashboards/upload.sh`

## Shared Dashboard Definition Files

Its possible to generate multiple dashboards from a single, shared, jsonnet file.

The file should end with `.shared.jsonnet` and the format of the file should be as follows:

```json
{
  "dashboard_uid_1": { /* Dashboard */ },
  "dashboard_uid_2": { /* Dashboard */ },
}
```

# The `jsonnet` docker image

* Google does not maintain official docker images for jsonnet.
* For this reason, we have a manual build step to build the `registry.gitlab.com/gitlab-com/runbooks/jsonnet:latest` image.
* To update the image, run this job in the CI build manually
