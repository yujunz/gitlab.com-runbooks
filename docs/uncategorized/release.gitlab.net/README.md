# `release.gitlab.net`

The release environment is a single VM installation that is configured using our existing terraform and chef tooling.  It serves as a target environment for the latest self-managed omnibus release.  This environment will serve as the location where QA is run prior to a package being released to the public.

Note that auto-deploy release candidates (RC's) will not be deployed to this environment, instead they are deployed to `preprod`.  Only self-managed omnibus releases will be installed on this environment.  Like auto-deploy, the deployment pipeline for the release environment is triggered from the [omnibus-gitlab] pipeline.

## Configuration

Terraform is utilized to bring the instance online. The terraform configurations can be found by looking for the `release` environment inside of [gitlab-com-infrastructure](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/tree/master/environments/release)

Due to the domain name utilized, `*.gitlab.net`, this falls into the CloudFlare WAF ruleset governing this domain.  One can find these rules in our [cloudflare-waf.tf](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/ops/cloudflare-waf.tf) configuration.  Please refer to our documentation related to CloudFlare management, which can be found in this repo: [CloudFlare Management].

Chef is utilized the configure the instance.  The role for this instance can be found here: [release-gitlab.json].  This requires a set of roles, and secrets stored in the appropriate vault for GKMS.  Please refer to existing documentation on roles and our GKMS secrets for details related to this.

## Data

This instance is strictly utilized for purposes of QA.  No RED data is permitted to be installed on this system.  The configurations and secrets utilized are specifically for this instance and cannot be reused across environments.

## Access

Logging into this GitLab Application is limited to those with `gitlab.com` email addresses.

Administrative access to the GitLab Application is currently limited to members of the Delivery team as owners of this instance.

Logging into the instance via ssh is also restricted as defined in our chef role [release-gitlab.json].

[CloudFlare Management]: https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/cloudflare/README.md
[omnibus-gitlab]: https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/lib/gitlab/tasks/gitlab_com.rake
[release-gitlab.json]: https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/blob/master/roles/release-gitlab-omnibus-version.json
