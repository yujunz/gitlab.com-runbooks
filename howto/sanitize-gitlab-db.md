# Summary

When making a copy of production data the following should be done
at a minimum to ensure that emails and passwords belong to customers
are removed.

Note that this does NOT sanitize customer data or make data anonymous.
Even after following these steps customer data should be treated similar
as it is on production.

## WebHooks

* Disable web hooks to prevent accidental notifications
```
WebHooks.destroy_all
```

## Private data

* Auth and RSS tokens
```
UPDATE users set authentication_token = null WHERE email NOT LIKE '%@gitlab.com';
UPDATE users set rss_token = null WHERE email NOT LIKE '%@gitlab.com';
```

* Access tokens
```
DELETE FROM personal_access_tokens
 WHERE user_id IN (SELECT id FROM users WHERE email NOT LIKE '%gitlab.com')
```

* CI variables
```
DELETE FROM ci_variables where ci_variables.project_id IN (select projects.id FROM projects, users where projects.creator_id = users.id AND users.email NOT LIKE '%@gitlab.com');
```

## Emails

```
UPDATE users SET email = 'ops-contact+TESTBED-' || id || '@gitlab.com' WHERE email NOT LIKE '%@gitlab.com';
```

## Remote mirrors

You will likely want to disable all remote mirroring.

```
UPDATE remote_mirrors SET enabled = 'f';
```

