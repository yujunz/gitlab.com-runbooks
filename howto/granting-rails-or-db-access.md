## Summary

In some cases it is necessary to grant database or rails console access
to team members who are not in the production team.

To do this a user can be granted access to special accounts that will give them
access to either the rails or the db console. To create these accounts add the user
accounts to the `rails_users` or `db_users` keys in the deploy role. After
the chef run one or both of the following accounts will be created on the 
deploy host:  `<username>-db` or `<username>-rails`.

The special account to connect to the database will only connect to the
secondary.

After this the user will be able to ssh using these usernames which will
immediately launch the corresponding console. A log of the entire session
will be on `/var/log/{db,rails}_sessions`. These logs are not currently
forwarded to the rsyslog server for security reasons.

## Granting Access

Example for giving access to user `susan`:

* Ensure that `susan` has VPN access so that they can access the deploy host.
* Add `susan` to one or both of `rails_users`/`db_users` in `gitlab-base-deploy-node.json`.
* Submit an MR for the change.
* Run `knife role from file gitlab-base-deploy-node.json` to update the role.
* After the next chef run susan can access the corresponding console by `ssh susan-{db,rails}@deploy.gitlab.com`.
