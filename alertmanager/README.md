## Alertmanager configuration

Alertmanager configuration files are shared amongst ALL alertmanagers across
all environments.  In order to sync this configuration between any node
via chef and any pod running in Kubernetes, this directory holds the necessary
template file for the configuration, and allows CI to populate any secrets.  We
then push these files as encrypted objects to object storage.  The necessary
chef recipe or helm managed kubernetes repo will pull down the file and populate
it into the appropriate place.

The CI jobs for this are run on ops.gitlab.net where the variables for
setting up gcloud and the secrets for the template are located: https://ops.gitlab.net/gitlab-com/runbooks/-/settings/ci_cd

These jobs run in a CI pipeline, view the [.gitlab-ci.yml](../.gitlab-ci.yml) to
determine how this is configured.

This is not meant to be run locally but can be enabled to do so, simply remove
the lines associated with authenticating and setting up gcloud in the
`update.sh` file.  You will need to set environment variables specified in
`template.rb` in order to see these populate the template correctly.

* Generate template file
  * `./template.rb`
* Encrypt template file
  * `./update.sh`
