# Cloudflare: Managing Traffic

## General

 - GitLab Pages and the GitLab registry are not yet fronted by Cloudflare, so these blocks would not affect them.
 - Automation mentioned in this documentation is *not* created yet. (https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9711#note_323835098)
   - This also means, that automated expiry does not yet work.
 - Blocks should not be a permanent solution. IP addresses get rotated on an ISP level, so we should strive to block them only as long as required to mitigate an attack or block abusive behaviour.

## The goal of the [Firewall issue tracker](https://gitlab.com/gitlab-com/gl-infra/cloudflare-firewall)

 - Provide a searchable database of current and previous blocks and allowlists.
 - Provide a quick overview of what is currently allowlisted or blocklisted and why.
 - Reduce noise in the infrastructure and production trackers by separating it out.

## When to block and how to block

Blocks should be combined to limit the impact on customers sharing the same public IP as the abuser, whenever possible.

### Decision Matrix

| Type of traffic pattern \ Type of Block | Temporary block on URI | Temporary block on other criteria | Temporary block on IP/CIDR | Permanent block on IP/CIDR |
| --- | ---| --- | --- | --- |
| 1. Project abuse as CDN, causing production issues or similar | yes | yes, in combination if uniquely identifiable via User-Agent or other means | no | no |
| 2. Spamming on issues and/or MRs | yes, in combination, not as standalone | yes, if uniquely identifiable via User-Agent or other means | yes, if applicable | yes, if applicable and repeated |
| 3. API / Web abuse from single IP/CIDR | yes, if limited to specific paths | yes, in combination if uniquely identifiable via User-Agent or other means | yes | yes, if repeated |
| 4. L7 DDoS not automatically detected by WAF | no | no | yes | yes, if repeated |

### Scenarios:
  - Scenario 1.1:
     - Problem:
       - Project `foo/bar` is abused by someone, who develops an app (with a dedicated user-agent) which uses this project as a CDN for its version check. This causes high load on Gitaly, raising an alert.
     - Block to apply:
       - We have the following datapoints to identify traffic for this specific abuse, so we should apply those. This prevents blocking other, legitimate traffic the App might have with our service, while alleviating the abuse pattern.
         - The project URI
         - User-agent of the app
       - The block to apply would be a combination of those two datapoints.
     - Why?
       - Blocking the project URI itself would lead to a project being unavailable for everyone. But we should limit the impact of a block to the immediate offenders. Since we can uniquely identify update checks via the combination of project URI and User-agent, we should refrain from a project-wide block.
     - Further measures:
       - Make sure to have support reach out to the project owner(s), to have the abusive pattern removed.
       - Inform the abuse team, to further analyze long-term solutions.

  - Scenario 1.2:
    - Problem:
      - Project `bar/baz` is abused by someone, by hosting binary blobs, which are hot-linked all over the internet. This causes high load on Gitaly, raising an alert.
    - Blocks to apply:
      - We only have the project URI as an identifier of the requests, as they come from everywhere and are using different clients to connect.
      - Thus, the block to apply is on the project URI in question.
    - Why?
      - We cannot limit the impact of the block, as we have no other means of identifying requests, so we need to block the whole project as a last resort.
    - Further measures:
      - Have support reach out to the project owner(s), to have them remove the hot-links, if not the primary use-case of the project.
      - Inform the abuse team, to further analyze long-term solutions.

  - Scenario 2.1:
    - Problem:
      - A bot spams on issues of project `gnarf/zort`. It does not have a unique user-agent, but limits itself to a single project and originates in a single IP.
    - Blocks to apply:
      - We have the IP, as well as the project as identifiers.
      - We should issue a combined block of project and IP. This is however not applicable, if the target project changes. In that case blocking the IP is the only way we can alleviate this issue.
    - Why?
      - We should *never* block the project in these cases, as a project is to be considered a victim of the spam. The combination of project and IP allows a legit customer to still use GitLab if on a shared connection.
    - Further measures:
      - Involve the abuse team to get the issue spam removed and potentially the user account abused to create those issues blocked.

@TODO: More scenario examples

What to consider repeated abuse?

## Rule management

Each block/allowlist in the Cloudflare firewall is to be accompanied by an issue in the [Firewall issue tracker](https://gitlab.com/gitlab-com/gl-infra/cloudflare-firewall).
This includes rules added in Terraform for internal an customer allowlists.

### Labels

In order to keep the promise of a searchable database, we are using labels to categorize each rule.

Each issue should be labeled with with either of these labels:

  - `firewall-action::block`: The rule associated to the issue is blocking traffic
    - Applied by automation for a newly created block.
      - Might also be applied by an engineer to manually created issues
    - This label must only be used while the block is active.
    - While this label is applied the issue should not be closed, but may be for long-term rules.
  - `firewall-action::allow`: The rule associated to the issue is allowing traffic
    - Applied by an engineer documenting a allowlist.
    - This label must only be used while the allowlist is in place.
    - While this label is applied the issue should not be closed, but may be for long-term rules.
  - `firewall-action::expired`: The rule associated to the issue has expired
    - Applied by automation once all of these conditions are met
      - The minimum block time of 48h has passed
      - Metrics indicate, the rule has had little to no traffic in the last 12h
        - Little to no traffic = less than 7200 requests (10 requests/minute over 12h)
      - The rule was removed from Cloudflare
    - Issues with this label should also be closed
    - Manually applied by an engineer, once a long-term rule has been sunset.
  - `firewall-action::other`: The rule associated to the issue is documented in the issue
    - In other cases. Mostly reserved for manual actions on firewall rules not forseen in this document.
    - The exact state and purpose of the rule has to be described in the issue.
    - This will also disable automatic closing of the issue by automation. A rule might still get removed.

In addition to the state, the type of block/allowlist should be documented by applying all appropriate type labels. In case of a rule created via automation, these will be applied automatically.

  - `firewall-type:ip`: The rule filters based on IPs or CIDRs
  - `firewall-type:uri`: The rule filters based on the URI
  - `firewall-type:user-agent`: The rule filters based on the user-agent
  - `firewall-type:other-identifier`: The rule filters based on another identifier
  - `firewall-type:external`: There is an (additional) component, not managed in Cloudflare rules
    - A good example would be an additional block on the registry HAProxy to block traffic on the registry.

Because there are multiple ways to create a rule, please also apply one of the following labels to specify the rule origin.

  - `rule-origin::terraform`: The rule was created via terraform. Please also note in the issue where to find the resource in question.
  - `rule-origin::chatops`: The rule was created via ChatOps.
  - `rule-origin::manual`: The rule was added manually.

The longevity of a rule is to be indicated by either of these labels:

  - `rule-duration::long-term`: The rule is intended to stay active for a long time. Examples include allowlisting Customers or blocking repeated offenders.
  - `rule-duration::temporary`: The rule is intended to be short-lived. Its lifetime will in most cases be determined by automation.

### Description format of Cloudflare rules

In order for automation to do its job, it is required to have a standardized format it can parse. This format is a compromise between machine readability and human readability.

```
#<firewall issue id>|<rfc-3339 date of rule creation>|<temporary[=<validity>]|long-term>[|<description>]
```

 - The firewall issue ID should be used to link any relevant production incidents or other issues to it.
 - The RFC3339 date can be retrieved via the GNU date util `date --rfc-3339=seconds --utc`. It should be UTC.
 - The longevity of a rule is to be indicated by either `temporary` or `long-term`.
   - `temporary` rules are subject for processing by automation.
   - If required a different minimum validity can be set and a maximum time can be specified.
   - This is done by suffixing `=<minimum validity in hours>[,<maximum validity in hours>]`
   - To specify a maximum validity without overriding the minimum, set the minimum to 0.
 - A description may be provided to add further detail, but may be omitted.

Examples:

```
#42|2020-04-16 11:37:15+00:00|long-term|Don't Panic
#1337|2020-04-16 11:37:15+00:00|temporary
#9001|2020-04-16 11:37:15+00:00|temporary=0,72|Minimum unchanged, expires after max 72 hours
#40000|2020-04-16 11:37:15+00:00|temporary=168|Will last at least 1 week
```

### Creating a new rule

#### ChatOps
TBD.

#### Manually

The engineer should first create an issue in the firewall tracker, documenting the subject and reason for the rule. If possible link to other issues to add more context.

The issue title should contain searchable information about the rule, such as `allowlist IP 1.2.3.4 for customer ACME Corp.` or `block uri /foo/bar/baz`.

Context on what the rule does should be added via labels as discussed above. For `firewall-type` labels make sure to add info on the resource that is filtered. For example for an issue with `firewall-type:ip` include the IP in the description, for `firewall-type:external` another issue documenting that, etc.

Depending on the lifetime of the rule the process is different:

`temporary`: Create the rule using the Cloudflare UI at https://dash.cloudflare.com/852e9d53d0f8adbd9205389356f2303d/gitlab.com/firewall/firewall-rules keeping in mind the layout of the rule description.

`long-term`: Create the rule in Terraform. For customer allowlists, follow the [instructions of the terraform module](https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/cf_whitelists#whitelist-configuration).

After the rule creation, comment the rule ID on the issue, as well as tagging the issue with the appropriate `rule-origin` label, as described above.

### Sunsetting a rule

#### Automated expiry on temporary rules

The intent of this supplemental automation is to have a "set it and forget it" mentality when in comes to temporary rules. It will ensure, that constrains set upon creation are met and that the rule will be removed once traffic allows.

##### Keeping up-2-date

Every 3 hours a CI job will fetch a list of active rules from Cloudflare and parse them according to the format above. A `temporary` rule will be processed as following:

If the minimum rule lifetime time of 48h has passed its first job is to check, if the traffic processed by the rule is below the threshold for the last 12h. (7200 requests, 10 requests/minute over 12h).  
If that is the case, the rule is removed and the associated issue is labeled with `firewall-action::expired` and closed.
  - One exception to this: If the issue is labeled `firewall-action::other` it will not be re-labeled, nor closed!
If that is not the case, the rule will be left in-place and checked again on the next run.

When a maximum lifetime was specified and that has passed, the rule will be regarded as expired regardless of traffic state.

`long-term` rules will not be auto-expired, but are subject to processing and require, that a valid issue exists.

If a rule was manually modified, for example to include a user-agent after the fact, any new applicable `firewall-type` labels will be applied. No labels will be removed.

Any rule which is not parsable, will be logged as an error.

#### Manually removing a role

If automation is not working, or you need to remove a `long-term` rule, firstly take note of the issue ID of the role and open the issue.

Next remove the role from Cloudflare. Refer to the issue labels to determine the origin. If the rule was created in Terraform refer to the issue on details where to find it. In other cases, the rule can be found in the Cloudflare Dashboard or the API.

Once the rule is removed, mark the issue with `firewall-action::expired` and close the issue.
