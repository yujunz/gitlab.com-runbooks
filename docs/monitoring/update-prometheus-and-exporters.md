# Updating Prometheus and Exporters

As identified in [this infrastructure issue](https://gitlab.com/gitlab-com/infrastructure/issues/813),
we have had issues in the past with unverified upgrades to Prometheus and it's exporters.
This document will describe the process for updating them.

## Process 

### Create issue

First and foremost, [create an issue](https://gitlab.com/gitlab-com/infrastructure/issues/new) about the upgrade. The subject should be the service
you want to update and the version. 

In the body of the issue, please use the following checklist template.

```
## Precheck

- [] Ensure the exporter is currently being scraped and validate in the [targets page](https://prometheus.gitlab.com/targets)

## Upgrade

- [] Update the cookbook to get the new version
- [] Create MR and assign it to someone for review
- [] Merge and upload the new cookbook
- [] Run `chef-client` to update the exporter
- [] Run `chef-client` on the prometheus server

## Postcheck

- [] Check that the exporter has been updated and it is running & listening on the expected port
- [] Check [targets page](https://prometheus.gitlab.com/targets) again to ensure that Prometheus is indeed
scraping.
```

### Precheck

In order to ensure that everything is working as expected before we upgrade, it is necessary to
calidate that Prometheus is currently scraping the target. You can check this in the [targets page](https://prometheus.gitlab.com/targets).

### Upgrade step and check

In order to actually perform the upgrade, we need to tell chef what version of the exporter to 
install. The exporters are installed via the [gitlab-prometheus](https://gitlab.com/gitlab-cookbooks/gitlab-prometheus/)
cookbook. Edit the attributes file for the exporter you are upgrading to point to the new version and update
the checksum if applicable. You'll then need to bump the version number in `metadata.rb` so that 
berkshelf will update it on the chef server.

Create an MR as usual and assign it to someone for review. Once that person has reviewed and merged the 
cookbook update, the new cookbook will be uploaded automatically through a CI pipeline.

Bump the cookbook version in the desired environment file (or all of them) under `chef-repo/environments/`, 
run `knife environment from file <path-to-modified-env-files>`, then create an MR for these changes as well.

Finally, run `chef-client` on the node(s) that need the updated exporter. Then, check to make sure the exporter
is the newest version and has started as expected.
Once the check is done and verified as accurate, run `chef-client` on the prometheus server to ensure it has any updates to
ports or configurations. At this point you can check the targets page once again to ensure that the service
is indeed still being scraped. If it is, all is well and the upgrade is complete. At this point you may close
the issue.
