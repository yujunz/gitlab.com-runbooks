# Internal GitLab DNS

We are running internal DNS caching resolvers and query forwards for efficiency,
security, and dynamic scaling.

## Architecture

There are three (3) DNS nodes (dns-0[1-3].inf.prd.gitlab.net) that are running the
PowerDNS Recursor software.  These nodes are configured to do lookups from the root
DNS servers and cache the results for the allowable cacheable timeframe.

## Management

The DNS servers are chef managed through the [gitlab_dns](https://gitlab.com/gitlab-cookbooks/gitlab_dns) cookbook
and applied via the `infra-base-dns` role.
