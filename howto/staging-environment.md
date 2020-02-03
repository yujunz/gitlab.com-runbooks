# GitLab staging environment

The GitLab.com staging environment has a copy of the production database that
is not current, ways to keep staging updates are being discussed but no plan are
yet made to keep it regularly updated.

This environment also contains a copy of some GitLab groups that are on storage
nodes

## What is this for?

The main goal of this environment is to reduce the feedback loop between development and production, and to have a playground where we can deploy RCs without compromising production as a whole.
If you have any idea on how to improve such feedback loop or you are missing any particular thing that you would like

## What is it made of?

For all hosts running in the staging environment see the [host dashboard](https://dashboards.gitlab.net/d/fasrTtKik/hosts?orgId=1&var-environment=gstg&var-prometheus=prometheus-01-inf-gstg).

Access to staging environment is treated the same as production as per
[handbook](https://about.gitlab.com/handbook/engineering/infrastructure/#production-and-staging-access).

## Run a rails console in staging environment

* Having [created your chef user data
  bag](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/user-administration.md),
  ensure that "rails-console" is one of your `groups`. See existing data bags
  for examples.
* After the data bag is uploaded you will have console access on instances that
  chef-client has subsequently run on. This may take up to 30m.
* Try to start a console with:

    ```
    ssh yourname-rails@console-01-sv-gstg.c.gitlab-staging-1.internal`
    sudo gitlab-rails console
    ```

## Run a redis console in staging environment

* SSH into the redis host
  * `ssh redis1.staging.gitlab.com`
* Get the redis password with `sudo grep requirepass /var/opt/gitlab/redis/redis.conf`
* Start redis-cli `/opt/gitlab/embedded/bin/redis-cli`
* Authenticate `auth PASSWORD` - replace "PASSWORD" with the retrieved password

## Run a psql console in staging environment

* ssh into the primary database host:
  * `ssh db1.staging.gitlab.com`
* start `gitlab-psql` with the following command:

    ```
    sudo -u gitlab-psql -H sh \
      -c "/opt/gitlab/embedded/bin/psql \
      -h /var/opt/gitlab/postgresql gitlabhq_production"
    ```

## Deploy to staging

Follow the instructions [from the chef-repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/blob/master/doc/staging.md)
(to which you need access to deploy anyway)
