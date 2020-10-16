# Incidents

General documentation about our incident workflow itself. Service-specific
information, including what to do in response to an incident relating to that
service, is found in the docs for that service.

## Slack `/incident declare` failed to create an incident issue

Usually we rely on the `/incident declare` Slack command to co-ordinate our
incident workflow, including opening an incident issue. If gitlab.com is totally
down, this will fail.

As a backup, open a Google doc in order to collaborate with others to help
resolve the incident:

- Navigate to https://drive.google.com/
- Create a new Google Doc
- Click "Share" in the top-right corner
- In the "Get link" section of the modal, click "Change link to GitLab" to make
  the doc shareable with the whole company.
- Change the "Anyone with the link in GitLab" permissions to "Editor"
- Click done.
- Post a link to the doc in Slack
- Good luck!
