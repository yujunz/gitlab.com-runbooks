## Summary

In some cases it is necessary to grant database or rails console access
to team members who are not in the production team.

To do this a user can be granted access to special accounts that will give them
access to either the rails or the db console. 

* db-console - Connect to the db secondary console with `<user>-db`
* db-console-primary - Connect to the db primary console with `<user>-db-primary`
* db-console-geo - Connect to the geo db with `<user>-geo-db`
* rails-console - Connect to the rails console with `<user>-rails`

After this the user will be able to ssh using these usernames which will
immediately launch the corresponding console. A log of the entire session
will be on `/var/log/{db,rails}_sessions_{geo,primary}`. These logs are not currently
forwarded for security reasons.

## Granting Access

Example for giving access to user `susan`:

* Add susan to one or more of the groups above.
* Submit an MR for the change.
* Run `knife role from file <role file>` to update the role.
* After the next chef run susan can access the corresponding console by `ssh susan-<id>@deploy.gitlab.com` for azure production or `ssh susan-<id>@console-01-sv-gprd.c.gitlab-production.internal` for gcp.
* Note for the gcp environment you must connect to the dedicated console vm, see the [gprd-bastions](gprd-bastions.md) howto.
