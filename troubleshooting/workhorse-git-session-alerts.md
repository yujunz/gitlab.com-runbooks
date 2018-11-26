# Workhorse Session Alerts

## Symptoms

![Workhorse HTTP](../img/workhorse-git-http-session-issues.png)

## Possible checks

* HAProxy may not be able to keep up
* Gitaly is overloaded
* Gitaly rate-limiting issues

## Reference Issues

[**2018-11-06: Up to 15 minute delays on clones from GitLab repositories, including www-gitlab-com, gitlab-ee, gitlab-ce*](https://gitlab.com/gitlab-com/gl-infra/production/issues/553)

* A S2 level incident lasting 3 days, led to disruption to git clones, in particular for the `www-gitlab-com`, `gitlab-ee`, `gitlab-ce`
  although many others were affected to.
* Diagnosis went around in circles:
   * Initially targetted abuse
   * High CI activity rates
   * Workhorse throughput
   * Network issues
   * Gitaly concurrency limits (which had contributed)
* Smoking gun: not only git clones which were slow, artifact downloads against S3 had also sky-rocket in latency
* Testing git clones and artifact downloads via https://gitlab.com, then against front-end load balancers, then again Workhorse helps us pinpoint the issue with the HAProxy front-end fleet.



