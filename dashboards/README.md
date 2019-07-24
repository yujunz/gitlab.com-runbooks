# Dashboard Source

This folder is used to keep the source for some of our Grafana dashboards, checked into, and managed by, git.

On `master` builds, the dashboards will be uploaded to https://dashboards.gitlab.com. Any local changes to these dashboards on
the Grafana instance will be overwritten.

The dashboards are kept in [`grafonnet`](https://github.com/grafana/grafonnet-lib) format, which is based on the [jsonnet template language](https://jsonnet.org/).

# Local Development

* Install `jsonnet`, `jq` and `curl`
  * On a Mac, `jsonnet` can be installed with `brew install jsonnet`
  * On Linux, you'll need to build the binary yourself, or use the docker image: `docker run --rm registry.gitlab.com/gitlab-com/runbooks/jsonnet:latest`
* Install `jb` [jsonet bundler](https://github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb)
  * `go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb`
* Update vendor dependencies
  * `(cd dashboards && jb install)`

# Editing Files

* Dashboards should be kept in files with the following name: `/dashboards/[grafana_folder_name]/[name].dashboard.jsonnet`
  * `grafana_folder_name` refers to the grafana folder where the files will be uploaded to. Note that the folder must already be created.
* Obtain a API key to the Grafana instance and export it in `GRAFANA_API_TOKEN`:
  * `export GRAFANA_API_TOKEN=123`
* To upload the files, run `./dashboards/upload.sh`

# The `jsonnet` docker image

* Google does not maintain official docker images for jsonnet.
* For this reason, we have a manual build step to build the `registry.gitlab.com/gitlab-com/runbooks/jsonnet:latest` image.
* To update the image, run this job in the CI build manually
