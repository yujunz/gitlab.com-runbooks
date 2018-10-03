## Background

In some cases it is necessary to grant database or rails console access
to team members who are not in the Infrastructure Engineering team.

Access is configured in data bags in [chef-repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo) and Chef configures it across
our infrastructure.

The below table shows the groups we have for DB and Rails console, their description and
what a user's account would look like for access.

| Group              | Description          | Account           |
|--------------------|----------------------|-------------------|
| db-console         | DB secondary console | <user>-db         |
| db-console-primary | DB primary console   | <user>-db-primary |
| db-console-geo     | DB geo console       | <user>-db-geo     |
| rails-console      | Rails console        | <user>-rails      |

The access level (staging or production or both) for the groups is also configured
in the same data bags. Access types we have:

| Access Type | Description                                             | Data bag group    | Bastion setup                                                             |
|-------------|---------------------------------------------------------|-------------------|---------------------------------------------------------------------------|
| Staging     | Access to staging environment via staging bastion       | gstg-bastion-only | https://gitlab.com/gitlab-com/runbooks/blob/master/howto/gprd-bastions.md |
| Production  | Access to production environment via production bastion | gprd-bastion-only | https://gitlab.com/gitlab-com/runbooks/blob/master/howto/gstg-bastions.md |

## Process
Team member, needing access, should:
1. Open an issue in [infrastructure](https://gitlab.com/gitlab-com/gl-infra/infrastructure)
2. Provide their public SSH key they want to use for access. (_If this is not provided,
   we will use the key(s) defined in_ https://gitlab.com/<user>.keys)

SRE oncall should:
1. Assign the issue, based on priority and oncall load
2. Follow the steps mentioned below
3. Update the issue asking requester to confirm and close the issue   

## Steps
1. If you haven't already, `git clone https://ops.gitlab.net/gitlab-cookbooks/chef-repo`
2. `cd chef-repo/data_bags` and remember to create a branch
3. If the user doesn't already have a .json file, copy an existing .json file and create one named after the user's name.
4. Edit the `<user>.json` file accordingly. See below for reference:

| Field               | Description (Each value should be double-quoted)                                                                                                                                                                                                         |
|---------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| id                  | UNIX login                                                                                                                                                                                                                                               |
| comment             | Firstname Lastname                                                                                                                                                                                                                                       |
| ops_gitlab_username | GitLab handle                                                                                                                                                                                                                                            |
| ssh_keys            | SSH key(s) provided by the user in the issue OR  get it from http://gitlab.com/user.keys. This field  takes a list so a comma separated keys will also work.                                                                                             |
| groups              | This field takes a list. Look at the "groups" listed  in above table and provide the groups separated by comma.  Example: staging access for db and rails console will be:   "groups": [    "gstg-bastion-only",     "db-console",     "rails-console" ] |
| shell               | You can leave it as-is unless specifically requested  to change it.                                                                                                                                                                                      |
| action              | You can leave it as-is unless specifically requested  to change it.  

5. Send an MR for the change.
6. Once change is merged, run: `git pull` so that your `master` branch syncs
7. Run: `knife data bag from file users <user>.json`

After this the user will be able to ssh using these usernames which will
immediately launch the corresponding console. A log of the entire session
will be on `/var/log/{db,rails}_sessions_{geo,primary}`. These logs are not currently
forwarded for security reasons.

## Testing Access
User should already have setup the bastion config: [gprd-bastions](gprd-bastions.md) and/or
[gstg-bastions](gstg-bastions.md). Each has an instruction on how to access console.

Example:
For DB: `ssh <user>-db@<dedicated-console-server>`
For Rails: `ssh <user>-rails@dedicated-console-server`
