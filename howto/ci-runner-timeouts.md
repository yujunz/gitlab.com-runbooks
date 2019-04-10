# Shared CI Runner Timeouts

The shared runner managers have timeouts that can restrict the time a CI job is allowed to run. In a runner config, there is a *Maximum job timout* field that is described by the following: ```This timeout will take precedence when lower than project-defined timeout and accepts a human readable time input language like "1 hour". Values without specification represent seconds.```

Manually changing this can be done per shared runner manager in the GitLab admin interface under ```Admin Area -> Overview -> Runners```. Select, or search for the runner managers you want to increase (or decrease) the runtime timeout for.

API bulk update idea:
``` bash
for runner in 157328 157329 380989 380990; do
  curl -sL \
       -H "Private-Token: $GITLAB_COM_ADMIN_PAT" \
       -X PUT  "https://gitlab.com/api/v4/runners/$runner" \
       -F 'maximum_timeout=5400' | jq '"\(.description): \(.maximum_timeout)"'
  sleep 1
done
```

Example Issue: https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/6547
