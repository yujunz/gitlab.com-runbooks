# Summary

When making a copy of production data the following should be done
at a minimum to ensure that emails and passwords belong to customers
are removed.

Note that this does NOT sanitize customer data or make data anonymous.
Even after following these steps customer data should be treated similar
as it is on production.

## WebHooks

* Disable web hooks to prevent accidental notifications

    ```ruby
    WebHooks.destroy_all
    ```

## Private data

* Auth and RSS tokens

    ```sql
    UPDATE users
      SET authentication_token = null, rss_token = null
      WHERE email NOT LIKE '%@gitlab.com';
    ```

* OTP secrets

    ```sql
    UPDATE users
      SET encrypted_otp_secret = null, encrypted_otp_secret_iv = null, encrypted_otp_secret_salt = null
      WHERE email NOT LIKE '%@gitlab.com';
    ```

* Access tokens

    ```sql
    DELETE
      FROM personal_access_tokens
      USING users
      WHERE personal_access_tokens.user_id = users.id
        AND users.email NOT LIKE '%gitlab.com';
    ```

* OAuth applications

    ```sql
    DELETE
      FROM oauth_applications
      USING oauth_access_tokens, users
      WHERE oauth_applications.id = oauth_access_tokens.application_id
        AND oauth_access_tokens.resource_owner_id = users.id
        AND users.email NOT LIKE '%gitlab.com';

    DELETE
      FROM oauth_access_tokens
      USING users
      WHERE oauth_access_tokens.resource_owner_id = users.id
        AND users.email NOT LIKE '%gitlab.com';
    ```

* CI variables

    ```sql
    DELETE
      FROM ci_variables
      USING projects, users
      WHERE ci_variables.project_id = projects.id
        AND projects.creator_id = users.id
        AND users.email NOT LIKE '%@gitlab.com';
    ```

* Project import data

    ```sql
    UPDATE project_import_data
      SET encrypted_credentials = null, encrypted_credentials_iv = null, encrypted_credentials_salt = null;
    ```

## Emails

Wipe email addresses from database:

```sql
UPDATE users
  SET email = 'ops-contact+TESTBED-' || id || '@gitlab.com'
  WHERE email NOT LIKE '%@gitlab.com';

DELETE FROM emails WHERE email NOT LIKE '%@gitlab.com';
```

## Remote mirrors

You will likely want to disable all remote mirroring.

```sql
UPDATE remote_mirrors SET enabled = 'f' WHERE enabled = 't';
```

## CI Runners

To remove all runners:

```sql
TRUNCATE TABLE ci_runners;
```

## Confidential issues

Erase all confidential issues, and their comments.

```sql
UPDATE notes n
  SET note = '!!! CONFIDENTIAL NOTE - REDACTED !!!'
  FROM (
    SELECT id
    FROM issues
    WHERE issues.confidential = 't') c
  WHERE n.noteable_id = c.id
    AND n.noteable_type = 'Issue';

UPDATE issues i
  SET title = 'CONFIDENTIAL ISSUE', description = '!!! CONFIDENTIAL ISSUE - REDACTED !!!'
  FROM issues
  WHERE issues.confidential = 't';
```
