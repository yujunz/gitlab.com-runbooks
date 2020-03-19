# PostgreSQL Trigram Indexes

This documents to action taken on https://gitlab.com/gitlab-com/database/issues/14. The script below rebuilds
all trigram indexes that existed at the time of writing (note this may change in the future).

The reason why this cannot be part of a regular migration is that it takes too long to rebuild indexes on
GitLab.com during a regular deploy. It cannot be part of a background migration because we don't have a way
at the moment to increase statement timeouts for background migration (and the `CREATE INDEX` statements are
going to run for hours).

The script should be run like so:

```
ON_ERROR_STOP=1 sudo gitlab-psql -d gitlabhq_production < rebuild_indexes.sql
```

One-by-one, we build a new index and replace the old one:

```sql
SET statement_timeout=0;

ALTER INDEX "index_issues_on_title_trigram" RENAME TO "index_issues_on_title_trigram_old";
CREATE INDEX CONCURRENTLY index_issues_on_title_trigram ON issues USING gin(title gin_trgm_ops);
DROP INDEX "index_issues_on_title_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_issues_on_description_trigram" RENAME TO "index_issues_on_description_trigram_old";
CREATE INDEX CONCURRENTLY index_issues_on_description_trigram ON issues USING gin(description gin_trgm_ops);
DROP INDEX "index_issues_on_description_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_merge_requests_on_title_trigram" RENAME TO "index_merge_requests_on_title_trigram_old";
CREATE INDEX CONCURRENTLY index_merge_requests_on_title_trigram ON merge_requests USING gin(title gin_trgm_ops);
DROP INDEX "index_merge_requests_on_title_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_merge_requests_on_description_trigram" RENAME TO "index_merge_requests_on_description_trigram_old";
CREATE INDEX CONCURRENTLY index_merge_requests_on_description_trigram ON merge_requests USING gin(description gin_trgm_ops);
DROP INDEX "index_merge_requests_on_description_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_milestones_on_title_trigram" RENAME TO "index_milestones_on_title_trigram_old";
CREATE INDEX CONCURRENTLY index_milestones_on_title_trigram ON milestones USING gin(title gin_trgm_ops);
DROP INDEX "index_milestones_on_title_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_milestones_on_description_trigram" RENAME TO "index_milestones_on_description_trigram_old";
CREATE INDEX CONCURRENTLY index_milestones_on_description_trigram ON milestones USING gin(description gin_trgm_ops);
DROP INDEX "index_milestones_on_description_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_namespaces_on_name_trigram" RENAME TO "index_namespaces_on_name_trigram_old";
CREATE INDEX CONCURRENTLY index_namespaces_on_name_trigram ON namespaces USING gin(name gin_trgm_ops);
DROP INDEX "index_namespaces_on_name_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_namespaces_on_path_trigram" RENAME TO "index_namespaces_on_path_trigram_old";
CREATE INDEX CONCURRENTLY index_namespaces_on_path_trigram ON namespaces USING gin(path gin_trgm_ops);
DROP INDEX "index_namespaces_on_path_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_notes_on_note_trigram" RENAME TO "index_notes_on_note_trigram_old";
CREATE INDEX CONCURRENTLY index_notes_on_note_trigram ON notes USING gin(note gin_trgm_ops);
DROP INDEX "index_notes_on_note_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_projects_on_name_trigram" RENAME TO "index_projects_on_name_trigram_old";
CREATE INDEX CONCURRENTLY index_projects_on_name_trigram ON projects USING gin(name gin_trgm_ops);
DROP INDEX "index_projects_on_name_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_projects_on_path_trigram" RENAME TO "index_projects_on_path_trigram_old";
CREATE INDEX CONCURRENTLY index_projects_on_path_trigram ON projects USING gin(path gin_trgm_ops);
DROP INDEX "index_projects_on_path_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_projects_on_description_trigram" RENAME TO "index_projects_on_description_trigram_old";
CREATE INDEX CONCURRENTLY index_projects_on_description_trigram ON projects USING gin(description gin_trgm_ops);
DROP INDEX "index_projects_on_description_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_snippets_on_title_trigram" RENAME TO "index_snippets_on_title_trigram_old";
CREATE INDEX CONCURRENTLY index_snippets_on_title_trigram ON snippets USING gin(title gin_trgm_ops);
DROP INDEX "index_snippets_on_title_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_snippets_on_file_name_trigram" RENAME TO "index_snippets_on_file_name_trigram_old";
CREATE INDEX CONCURRENTLY index_snippets_on_file_name_trigram ON snippets USING gin(file_name gin_trgm_ops);
DROP INDEX "index_snippets_on_file_name_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_users_on_username_trigram" RENAME TO "index_users_on_username_trigram_old";
CREATE INDEX CONCURRENTLY index_users_on_username_trigram ON users USING gin(username gin_trgm_ops);
DROP INDEX "index_users_on_username_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_users_on_name_trigram" RENAME TO "index_users_on_name_trigram_old";
CREATE INDEX CONCURRENTLY index_users_on_name_trigram ON users USING gin(name gin_trgm_ops);
DROP INDEX "index_users_on_name_trigram_old";

SELECT pg_sleep(10800); -- 3 hours

ALTER INDEX "index_users_on_email_trigram" RENAME TO "index_users_on_email_trigram_old";
CREATE INDEX CONCURRENTLY index_users_on_email_trigram ON users USING gin(email gin_trgm_ops);
DROP INDEX "index_users_on_email_trigram_old";
```
