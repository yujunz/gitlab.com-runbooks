# Service Locations

This is a table of various services we run and what they run behind.

| Domain               | Service            | Provider                         |
| -------------------- | ------------------ | -------------------------------- |
| staging.gitlab.com   | GitLab Web/API/SSH | Cloudflare                       |
| staging.gitlab.com   | static assets      | Fastly                           |
| GitLab.com           | GitLab Web/API/SSH | Cloudflare                       |
| GitLab.com           | static assets      | Fastly                           |
| ops.GitLab.com       |                    | Cloudflare                       |
| customers.gitlab.com |                    | direct to Azure                  |
| license.gitlab.com   |                    | direct to Google                 |
| version.gitlab.com   |                    | direct to Google                 |
| pre.gitlab.com       |                    | direct to Google                 |
| about.gitlab.com     |                    | Fronted by Fastly, backed by GCS |
