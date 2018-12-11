# Pingdom

## How to configure checks in Pingdom

* Pingdom checks are configured in the `pingdom/pingdom.yml` file
* On non-`master` branches, the `dryrun_pingdom_checks` CI job will (partially) validate the `pingdom.yml` file and will display changes that will be made via the Pingdom API (see [Dry-run Mode](#dry-run-mode) for details).
* When changes to this file are merged to `master`, the `deploy_pingdom_checks` GitLab CI will execute and make the actual changes:
* This job will perform 3 tasks:
  * It will insert any new checks that have been added to the file. These checks will be prefixed with `check:`
  * It will remove any checks in Pingdom with the prefix `check:` that are not in this file
  * It will update any other checks from `pingdom/pingdom.yml`

* **Note:** the pingdom script uses the `check:` prefix to signal that the check is managed by the script. **Any checks on Pingdom that use the `check:` prefix but are not on the master branch will be deleted the next time the master pipeline is executed**

### `pingdom.yml` Details

The `pingdom.yml` is structured as follows:

```yaml
unique_tag: "pingdom-automated" # This is a tag which only checks in this file should include
defaults:
  timeout_ms: 2000              # The default timeout in milliseconds
  resolution_minutes: 5         # The amount of time before raising an alert
integrations:                   # This maps from the names we use in this document to the IDS pingdom needs
  - name: pagerduty
    id: 65172                   # This can be found in the URL when editing an integration
checks:
  # Each check has the following structure
  - url: https://gitlab.com/gitlab-org/gitlab-ce/
    timeout_ms: 5000            # The timeout for this check
    notify_when_restored: true  # Send an alert when service is restored
    tags:                       # Any additional tags to add to the check
      - gitaly
      - database
    teams:                      # Teams to associate the check with. See Pingdom for a list of teams
      - Infrastructure
    integrations:
      - pagerduty
```

## Dry-run Mode

When run with the `--dry-run`, the script will execute in dry-run mode, which will display changes but without executing them against the Pingdom API.

It is always safe to run.

### Running Locally

You can run the script locally, so long as you provide the following environment variables, which can be found in Pingdom and 1Password.

```
export PINGDOM_USERNAME="gitlab-ops+pingdom@gitlab.com"
export PINGDOM_PASSWORD="..."
export PINGDOM_APPKEY="..."
export PINGDOM_ACCOUNT_EMAIL="..."
```
