# Credential rotation

Rotating credentials in a high-availability database deployment with the
objective to ensure zero downtime can be a challenge.

Here are some explicit tasks which are required to accomplish the changing
of a password for an important database role like the `gitlab-superuser`.

## Change issue creation

Create a production change issue to track this work:

https://gitlab.com/gitlab-com/gl-infra/production/-/issues/new?issuable_template=change_management

Label the issue for criticality level 2 (`C2`) and severity level 2 (`S2`)
so that production deployments are not initiated during the prodedure.

Make a comment in the issue with the following content to apply some required labels:

```
/label ~change ~C2 ~S2 ~Database ~"Service::Postgres" ~"Service::Patroni" ~"requires commendted manager approval" ~"required production access" ~"section::ops" ~"security" ~"change::scheduled"
```

## Operator workstation setup

In order to support commands like `bundle exec knife <action>` it is
expected that an operator will change directory to their local workstation
clone of the `gitlab-com/runbooks` project and installed the required ruby
dependencies:

```bash
rbenv install
ruby -S gem install bundler
bundle install --path=vendor/bundle`
```

## Procedure

To update the credentials for *only* the `gitlab-superuser` user in the PostgreSQL database and the patroni cluster configuration:

### Phase one

1. [ ] Specify the environment in which to conduct operations:
   ```bash
   export GITLAB_ENVIRONMENT='gstg'
   ```
1. [ ] Specify the link to this issue:
   ```bash
   export issue_link='https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10961' # CHANGEME (as necessary)
   ```
1. [ ] Copy the current user password:
   ```bash
   bin/gkms-vault-cat gitlab-patroni "${GITLAB_ENVIRONMENT}" | jq --raw-output '."gitlab-patroni".patroni.users.superuser.password' | pbcopy
   ```
1. [ ] Record the password in a field of type `Password` in a secure note entitled "`gitlab-patroni ${GITLAB_ENVIRONMENT} gitlab-superuser`" in 1Password for reference in case a roll-back is necessary.
1. [ ] Deploy the scripts from https://gitlab.com/gitlab-com/runbooks/-/merge_requests/2197 on each patroni node:
   ```bash
   export mode=0700 install_dir='/root/scripts' repository='https://gitlab.com/gitlab-com/runbooks' branch='master' artifacts=$(echo "scripts/database-gitlab-superuser-session-connection-terminate.sh scripts/database-gitlab-superuser-user-role-create.sh scripts/database-gitlab-superuser-user-role-password-update.sh scripts/database-user-role-delete.sh")
   for patroni_node in $(bundle exec knife search node "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" --format=json | jq --raw-output '.rows|=sort_by(.automatic.fqdn)|.rows|.[] .automatic.fqdn'); do echo "Deploying database utility scripts from ${repository}/-/raw/${branch} to ${patroni_node}:${install_dir}"; for artifact in ${artifacts}; do ssh "${patroni_node}" "sudo mkdir -p ${install_dir} && curl --silent --show-error --location '${repository}/-/raw/${branch}/${artifact}' --output - | sudo tee ${install_dir}/${script}  &>/dev/null && sudo chmod $mode ${install_dir}/${script}"; done; done
   ```
1. [ ] Create a new password:
   ```bash
   export new_password=$(openssl rand -base64 4096 | tr -dc A-Za-z0-9 | head -c64)
   echo "${new_password}" | pbcopy
   echo "export NEW_PASSWORD=${new_password}" | tee ./new_password.sh &>/dev/null
   ```
1. [ ] Record the **new** password in a field of type `Password` named "`Temporary PostgreSQL superuser role password`" in the environmentally appropriate "`Postgres gitlab-superuser`" Password entry in 1Password.
1. [ ] Select the first member node of the patroni cluster:
   ```bash
   export patroni_node=$(bundle exec knife search node "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" --format=json | jq --raw-output '.rows|=sort_by(.automatic.fqdn)|.rows[0]|.automatic.fqdn')
   echo "${patroni_node}"
   ```
1. [ ] Ask the first patroni node to identify the leader patroni node:
   ```bash
   export leader_patroni_node=$(ssh "${patroni_node}" 'test -e /usr/bin/jq && sudo /usr/local/bin/gitlab-patronictl list --format json 2>/dev/null' | jq --raw-output '.[] | select(.Role=="Leader").Member')
   echo "${leader_patroni_node}"
   ```
1. [ ] Copy the password to the patroni leader:
   ```bash
   scp ./new_password.sh "${leader_patroni_node}":/tmp/new_password.sh
   bundle exec knife ssh "fqdn:${leader_patroni_node}" "sudo mv /tmp/new_password.sh /root/scripts/.new_password.sh && sudo chmod 0700 /root/scripts/.new_password.sh && sudo chown root:root /root/scripts/.new_password.sh"
   ```
1. [ ] Dry-run the script to create a new temporary database user role on the leader and record the output:
   ```bash
   bundle exec knife ssh "fqdn:${leader_patroni_node}" 'sudo /root/scripts/database-gitlab-superuser-user-role-create.sh --dry-run'
   ```
1. [ ] Confirm that there were no relevant errors in the `dry-run` invocation.
1. [ ] Run the script to create a new temporary database user role on the patroni leader and record the output:
   ```bash
   bundle exec knife ssh "fqdn:${leader_patroni_node}" 'sudo /root/scripts/database-gitlab-superuser-user-role-create.sh --wet-run'
   ```
1. [ ] Confirm that there were no relevant errors in the `wet-run` invocation.
1. [ ] Record the verbatim character string of the new user role in a field of type `Text` named "`Temporary PostgreSQL superuser role username`" in the environmentally appropriate "`Postgres gitlab-superuser`" Password entry in 1Password.
1. [ ] Wait for replication to "catch up" to the changes in the database of the leader.
   - [ ] Optionally check each node in the patroni cluster to confirm that the new temporary user role exists in each database:
      ```bash
      bundle exec knife ssh --concurrency 1 "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" 'sudo /usr/local/bin/gitlab-psql --command "\du" | grep "gitlab-superuser-"'
      ```
1. [ ] Create (but DO NOT yet merge) a chef MR to change the username defined in `patroni.yml` for the `gitlab-superuser` user role to the name of the new temporary user in the `gitlab-cookbooks/chef-repo/roles/${GITLAB_ENVIRONMENT}-base-db-patroni.json` file, by committing changes to:
   - [ ] Set the `default_attributes.gitlab-patroni.patroni.users.superuser.username` field to the name of the new temporary user, and also...
   - [ ] Set the `default_attributes.gitlab_wale.backup_user` field to the name of the new temporary user, and also...
   - [ ] Set the `default_attributes.gitlab_walg.backup_user` field to the name of the new temporary user.
1. [ ] Add a link to the MR here: [For example: Configure the staging patroni fleet to use a temporary role with a time-stamped username](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/merge_requests/3253)
1. [ ] Block/disable the chef-client service on all patroni hosts with an explanation that includes a link to the issue created to track this work:
   ```bash
   read -p "Operating in environment ${GITLAB_ENVIRONMENT}; press return to continue, CTRL-C to abort> " && bundle exec knife ssh --concurrency 1 "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" "sudo /usr/local/bin/chef-client-disable 'Configuring new superuser role in /var/opt/gitlab/patroni/patroni.yml, see issue ${issue_link}'"
   ```
1. [ ] Confirm that the chef-client service has been stopped on all the patroni nodes:
   ```bash
   bundle exec knife ssh --concurrency 1 "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" 'sudo systemctl status chef-client --full --no-pager | tail --lines=1'
   ```
1. [ ] Update the password in the GKMS vault at `gitlab-patroni.patroni.users.superuser.password` to be the temporary database role password (created above) instead of the original password for the original `gitlab-superuser` user role:
   ```bash
   EDITOR=`which vim` bin/gkms-vault-edit gitlab-patroni "${GITLAB_ENVIRONMENT}"
   ```
1. [ ] Notify relevant parties about a configuration change to the `${GITLAB_ENVIRONMENT}` patroni fleet.
1. [ ] Merge the MR and apply the changes if necessary. This will not actually apply the changes.
1. [ ] Undo the disablement of the chef-client service on all the patroni nodes at once:
   ```bash
   bundle exec knife ssh --concurrency 1 "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" 'sudo /usr/local/bin/chef-client-enable'
   ```
1. [ ] Invoke chef-client on all the patroni nodes in order to apply the changes:
   ```bash
   bundle exec knife ssh --concurrency 1 "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" 'sudo chef-client'
   ```
1. [ ] Verify and record in a comment that WAL-E replication push operations are still running successfully:
   ```bash
   bundle exec knife ssh "fqdn:${leader_patroni_node}" 'sudo journalctl --full --no-pager | grep --ignore-case --after-context=3 wal-e | grep --invert-match audit | tail --lines=6'
   ```
1. [ ] Verify and record in a comment that WAL-G backup write operations are still running successfully:
   ```bash
   for patroni_node in $(bundle exec knife search node "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" --format=json | jq --raw-output '.rows|=sort_by(.automatic.fqdn)|.rows|.[] .automatic.fqdn'); do DATE=$(date -u '+%Y/%m/%d') ssh "${patroni_node}" "sudo egrep '$DATE.*Wrote backup with name' /var/log/wal-g/wal-g_backup_push.log && hostname --fqdn"; done
   ```


### Phase two

Now that the original superuser role is not being used by the patroni cluster or the replication processes, update the password for the original superuser role, and revert the configurations to use the original role.

1. [ ] Ask the first patroni node to identify the leader patroni node:
   ```bash
   export leader_patroni_node=$(ssh "${patroni_node}" 'test -e /usr/bin/jq && sudo /usr/local/bin/gitlab-patronictl list --format json 2>/dev/null' | jq --raw-output '.[] | select(.Role=="Leader").Member')
   echo "${leader_patroni_node}"
   ```
1. [ ] Dry-run the script to update the original `gitlab-superuser` role with the new password on the patroni leader and record the output:
   ```bash
   bundle exec knife ssh "fqdn:${leader_patroni_node}" 'sudo /root/scripts/database-gitlab-superuser-user-role-password-update.sh --dry-run'
   ```
1. [ ] Confirm that there were no relevant errors in the `dry-run` invocation.
1. [ ] Run the script to set the password of the original `gitlab-superuser` role in the database to the new password on the patroni leader and record the output:
   ```bash
   bundle exec knife ssh "fqdn:${leader_patroni_node}" 'sudo /root/scripts/database-gitlab-superuser-user-role-password-update.sh --wet-run'
   ```
1. [ ] Confirm that there were no relevant errors in the `wet-run` invocation.
1. [ ] Wait for replication to "catch up" to the changes in the database of the leader.
   - [ ] Optionally confirm that the change has replicated to each patroni node (You will be repeatedly prompted to enter the new password, so it is recommended that you **turn off any screen-sharing or recording**.  If you paste the new password correctly, but the credentials update has not yet been replicated to all nodes in the patroni cluster, then this error will be displayed: `psql: FATAL:  password authentication failed for user "gitlab-superuser"`):
      ```bash
      for patroni_node in $(bundle exec knife search node "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" --format=json | jq --raw-output '.rows|=sort_by(.automatic.fqdn)|.rows|.[] .automatic.fqdn'); do ssh "${patroni_node}" "sudo su --command \"psql --password --port=5432 --host=localhost --username=gitlab-superuser --dbname=gitlabhq_production --tuples-only --quiet --command 'SELECT 1;'\" root"; done
      ```
1. [ ] Create (but DO NOT yet merge) a chef MR to change the username defined in `patroni.yml` for the `gitlab-superuser` user role from the name of the temporary user back to the name of the original user in the `gitlab-cookbooks/chef-repo/roles/${GITLAB_ENVIRONMENT}-base-db-patroni.json` file, by committing changes to:
   - [ ] Set the `default_attributes.gitlab-patroni.patroni.users.superuser.username` field back to the name of the original `gitlab-superuser` user role, and also...
   - [ ] Set the `default_attributes.gitlab_wale.backup_user` field back to the name of the original `gitlab-superuser` user role, and also...
   - [ ] Set the `default_attributes.gitlab_walg.backup_user` field back to the name of the original `gitlab-superuser` user role.
1. [ ] Add a link to the MR here: [For example: Configure the staging patroni fleet to use the original superuser role](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/merge_requests/3992)
1. [ ] Block/disable the chef-client service with an explanation on all patroni hosts:
   ```bash
   read -p "Operating in environment ${GITLAB_ENVIRONMENT}; press return to continue, CTRL-C to abort> " && bundle exec knife ssh --concurrency 1 "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" "sudo /usr/local/bin/chef-client-disable 'Manually updating /var/opt/gitlab/patroni/patroni.yml, see issue ${issue_link}'"
   ```
1. [ ] Confirm that the chef-client service has been stopped on all the patroni nodes:
   ```bash
   bundle exec knife ssh --concurrency 1 "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" 'sudo systemctl status chef-client --full --no-pager | tail --lines=1'
   ```
1. [ ] Notify relevant parties about a configuration change to the `${GITLAB_ENVIRONMENT}` patroni fleet.
1. [ ] Merge the MR and apply the changes if necessary.
1. [ ] Undo the disablement of the chef-client service on all the patroni nodes at once:
   ```bash
   bundle exec knife ssh --concurrency 1 "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" 'sudo /usr/local/bin/chef-client-enable'
   ```
1. [ ] Invoke chef-client on all the patroni nodes in order to apply the changes:
   ```bash
   bundle exec knife ssh --concurrency 1 "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" 'sudo chef-client'
   ```
1. [ ] Verify and record in a comment that WAL-E replication push operations are still running successfully:
   ```bash
   bundle exec knife ssh "fqdn:${leader_patroni_node}" 'sudo journalctl --full --no-pager | grep --ignore-case --after-context=3 wal-e | grep --invert-match audit | tail --lines=6'
   ```
1. [ ] Verify and record in a comment that WAL-G backup write operations are still running successfully:
   ```bash
   for patroni_node in $(bundle exec knife search node "fqdn:patroni-*-db-${GITLAB_ENVIRONMENT}*" --format=json | jq --raw-output '.rows|=sort_by(.automatic.fqdn)|.rows|.[] .automatic.fqdn'); do DATE=$(date -u '+%Y/%m/%d') ssh "${patroni_node}" "sudo egrep '$DATE.*Wrote backup with name' /var/log/wal-g/wal-g_backup_push.log && hostname --fqdn"; done
   ```

### Roll-back

1. [ ] In order to undo these changes it is recommended that the procedure be repeated with the old credentials exchanged for the new credentials.

### TODO

1. [ ] Include steps to delete the `/root/scripts/.new_password.sh` from the patroni leader node.
1. [ ] Delete the temporary superuser role which is no longer being used by any patroni node or database operation.

