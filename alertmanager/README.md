# Alertmanager configuration

Alertmanager configuration files are shared amongst ALL alertmanagers across
all environments. In order to sync this configuration between any node
via chef and any pod running in Kubernetes, this directory holds the necessary
template file for the configuration, and allows CI to populate any secrets. We
then push the generated yml file as an encrypted file to object storage. The
chef recipe or helm managed kubernetes repo will pull down the file and populate
it into the appropriate place.

The CI jobs for this are run on ops.gitlab.net where the variables are configured.
See: https://ops.gitlab.net/gitlab-com/runbooks/-/settings/ci_cd

## Variables

### `ALERTMANAGER_SECRETS_FILE`

Type: File

Value: A jsonnet file, based on the dummy-secrets.jsonnet template.

### `SERVICE_KEY`

Type: File

Value: A GCP service key json file.

## CI Jobs

These jobs run in a CI pipeline, view the [.gitlab-ci.yml](../.gitlab-ci.yml) to
determine how this is configured.

To run a manual deploy, you will need a local secrets file with the filename
exported in the `ALERTMANAGER_SECRETS_FILE` variable.

Then remove the lines associated with authenticating and setting up gcloud in the
`update.sh` file.

* Generate the `alertmanager.yml` file.
  * `./generate.sh`
* Validate the `alertmanager.yml` looks reaosnable.
* Encrypt and upload the output file.
  * `./update.sh`
