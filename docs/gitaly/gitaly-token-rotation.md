# Gitaly token rotation

## Execution

To disable enforcement of gitaly authentication:
- [ ] Disable enforcement of gitaly authentication by setting `default_attributes['omnibus-gitlab']['gitlab_rb']['gitaly']['auth_transitioning'] = true` in `gprd-base-stor-gitaly`
```json
  "default_attributes": {
    [...]
    "omnibus-gitlab": {
      "gitlab_rb": {
        [...]
        "gitaly": {
          "auth_transitioning": true,
          [...]
```

- [ ] apply the changes to the gitaly servers. `knife ssh -C3 roles:gprd-base-stor-gitaly 'sudo chef-client'`
- [ ] Ensure that `gitaly_authentications_total` is set to true in prometheus and that 100% of all requests are "unenforced"
  - https://thanos-query.ops.gitlab.net/graph?g0.range_input=1h&g0.expr=count(gitaly_authentications_total%7Benv%3D%22gprd%22%2Cenforced%3D%22true%22%2Cstatus%3D~%22.*ok%22%7D)%20or%20vector(0)&g0.tab=0
  - [ ] That should go down to 0

Backup and replace the current `auth_token`
- [ ] Save the current `auth_token` in case we need to revert.
   - `./bin/gkms-vault-show gitlab-omnibus-secrets gprd | jq -r '.["omnibus-gitlab"].gitlab_rb.gitaly.auth_token'` within chef-repo
  - Save it it 1Password and document the name it was saved under.
  - Also backup the whole file locally in case it gets corrupted later during the change `./bin/gkms-vault-show gitlab-omnibus-secrets gprd > gitlab-omnibus-secrets.bak`
- [ ] Create a new random token `echo "$(pwgen 16 1)-gprdtoken"`
- [ ] Update the auth token in the `gitlab-omnibus-secrets gprd` vault by setting `gitaly['auth_token']`
- [ ] Update the auth token  in the `gitlab-omnibus-secrets gprd` vault for the application by setting `["omnibus-gitlab"].gitlab_rb.gitlab_rails.gitaly_token`
- [ ] and apply that to the fleet
  - [ ] `knife ssh -C3 roles:gprd-base-fe-api 'sudo chef-client'`
  - [ ] `knife ssh -C3 roles:gprd-base-stor-gitaly 'sudo chef-client'`
  - [ ] `knife ssh -C3 roles:gprd-base-fe-web 'sudo chef-client'`
  - [ ] `knife ssh -C3 roles:gprd-base-be-sidekiq 'sudo chef-client'`
  - [ ] `knife ssh -C3 roles:gprd-base-console-node 'sudo chef-client'`

Verify that the tokens are updated in all the places and ensure that authentication is working as expected.
 - https://thanos-query.ops.gitlab.net/graph?g0.range_input=1h&g0.expr=count(gitaly_authentications_total%7Benv%3D%22gprd%22%2Cenforced%3D%22false%22%2Cstatus%3D~%22.*ok%22%7D)%20or%20vector(0)&g0.tab=0
  - [ ] This should be equal to the number of gitaly nodes
- [ ] Finally, re-enable authentication enforcement by removing the `gitaly['auth_transitioning'] = true` setting added to the role in step 1
- [ ] apply that to the gitlay servers. `knife ssh -C3 roles:gprd-base-stor-gitaly 'sudo chef-client'`

## Rollback

Follow the execution steps, but instead of creating a new token via `pwgen` set the old token in the vault.
