# GitLab staging environment

The GitLab.com staging environment keeps a copy of the whole production database, ~~anonymised~~, and ~~automatically updated every weekend~~

This environment also contains a copy of the GitLab groups repos accessible through NFS to provide a similar experience to what we actually have in production.

## What is this for?

The main goal of this environment is to reduce the feedback loop between development and production, and to have a playground where we can deploy RCs without compromising production as a whole.
If you have any idea on how to improve such feedback loop or you are missing any particular thing that you would like

## What is it made of?

* One front-end load balancer: `fe01.stg.gitlab.com`
* One API node: `api01.stg.gitlab.com`
* One git node: `git01.stg.gitlab.com`
* One Sidekiq node: `sidekiq01.stg.gitlab.com`
* One web node: `web01.stg.gitlab.com`
* One Redis node: `redis1.staging.gitlab.com`
* Four Postgres nodes: `db3.staging.gitlab.com`, `db4.staging.gitlab.com`, `db5.staging.gitlab.com` and `db6.staging.gitlab.com`
* One Elasticsearch node: `es1.staging.gitlab.com`
* One storage node: `nfs5.staging.gitlab.com`

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
