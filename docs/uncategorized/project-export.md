# Summary

We sometimes need to manually export a project. This mostly is necessary when
exporting via UI fails for some reason.

<!-- vim-markdown-toc GitLab -->

* [From where to run the restore](#from-where-to-run-the-restore)
* [Restore a project via rails-console](#restore-a-project-via-rails-console)
  * [GCE credentials missing](#gce-credentials-missing)
  * [Statement timeouts](#statement-timeouts)
* [Debugging](#debugging)
  * [Call exporters one-by-one](#call-exporters-one-by-one)

<!-- vim-markdown-toc -->

# From where to run the restore

If the project isn't big, triggering the export from the console node could
work. If the project is big (several GiB), the console node might run out of
disk space, because the archive file will be created on the small `/`
filesystem. Also, the gitlab-ee version on the console might be outdated, which
can lead to compatibility problems or errors because of certain bugs that
haven't been fixed there.

__The best option seems to be to run the export from the file-node on which the
repository is located.__ You can find that by looking up the Gitaly storage name
and relative path of the project in the Admin UI or via rails console:

```ruby
p = Project.find_by_full_path('some/project')

storage = p.repository_storage
path = p.disk_path
```

# Restore a project via rails-console

* ssh to the file-node found above
* sudo gitlab-rails console

```ruby
u = User.find_by_any_email('<your_login>+admin@gitlab.com')
p = Project.find_by_full_path('some/project')
e = Projects::ImportExport::ExportService.new(p,u)

e.execute
```

If everything works, that will create an archive, upload it to GCS, send out an
email and a cleanup job will remove locally created files later.

But there are high chances, that things fail. If you get a failure with a sentry
event id, you should look that up by going to
`https://sentry.gitlab.net/gitlab/gitlabcom/?query=<long-sentry-id-number>`

## GCE credentials missing

If you get an error with `/etc/gitlab/gcs-creds.json` missing (very likely) that
means that the repository has external object storage items (e.g. Merge Request
Diffs) that need to be downloaded from GCS.

__Solution:__ temporarily copy this file from a sidekiq node over to the file
node (and delete it again when you are done!)

## Statement timeouts

That can happen because of some non-optimized queries in the current Exporter
code (e.g. https://gitlab.com/gitlab-org/gitlab/-/issues/212355#note_364049215).
This needs to get fixed in code probably. Try to get help from the Import team
(#g_manage_import).

# Debugging

## Call exporters one-by-one

The `execute` method of the Exporter actually just [loops over all defined
exporters](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/services/projects/import_export/export_service.rb#L61-66),
so we also can do this manually to see where the error is happening. For each of
the defined exporters:

```ruby
e.send(:version_saver).send(:save)
e.send(:avatar_saver).send(:save)
...
```

To find the location of the generated json and archive files, you can define a
saver:

```ruby
s = Gitlab::ImportExport::Saver.new(exportable: p, shared:p.import_export_shared)
```

This will show you the *export_path*, e.g. something like
`/var/opt/gitlab/gitlab-rails/shared/tmp/gitlab_exports/@hashed/49/94/4994...`.

To try an upload you can run

```ruby
s.send(:compress_and_save)
s.send(:save_upload)
```

Please make sure to delete the created files under `tmp/gitlab_exports/...` when
you are done.
