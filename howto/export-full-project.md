### Export full project

This page details how to export a project with its repository and metadata without sending notifications to the owner of the project. A regular export (e.g. as an admin user through the UI) would also send notifications to the owner of the project. This may or may not be wanted.

```ruby

p = Project.find_by_full_path("path_to/project")
u = User.by_login('you+admin@gitlab.com')
p.add_export_job(current_user: u)
```

The above snippet will trigger an export job that will only send a notification to the given user, not additionally to the project owner.

