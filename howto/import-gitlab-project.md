## Custom import

Customers and potential ones may want to import a large project into GitLab.com. We hava a script to provide a workaround in a timely manner for them.

### How does it work?

The script is https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/project_import.rb

In order to run it we can follow the steps in the template: https://gitlab.com/gitlab-com/gl-infra/infrastructure/blob/master/.gitlab/issue_templates/import.md

1. Grab the Slack token from 1Password (search for `Import Slack token`)
1. On the console server (console-01-sv-gprd), run as **root** in a **tmux** session (Adding slack token, and `-u -p -f` options):
```sh
sudo -u git -H bash -c "EXECJS_RUNTIME=Disabled SLACK_TOKEN='changeme' RAILS_ENV=production /opt/gitlab/embedded/bin/ruby <(curl -s https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/project_import.rb) -u gitlab_username -p namespace/project -f /path/to/export.tar.gz"
```
1. Wait for the script to send a message to #annoucements confirming it finished
1. Exit the tmux session and remove the export file
