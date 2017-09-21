# Summary

[This script](https://gitlab.com/gitlab-com/gitlab-com-infrastructure/blob/master/modules/gitlab-single-azure-db/bin-files/pseudonymization.sql) can be used for [pseudonymization](https://en.wikipedia.org/wiki/Pseudonymization) of the Gitlab database.

Note that this does NOT "sanitize" customer data or make it anonymous.
Even after running this against the database, data should be treated as
it is on production.
