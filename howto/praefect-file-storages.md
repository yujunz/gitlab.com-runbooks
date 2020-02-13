# Add and remove file storages to praefect

Modifying the list of file storages configured in praefect must be done
carefully, given that the secrets and the chef role changes must be deployed
simultaneosly or else
[gitlab_secrets](https://gitlab.com/gitlab-cookbooks/gitlab_secrets) will create
incomplete and invalid entries. To avoid this, follow the next steps (example
commands for production. Adjust chef-repo roles accordingly for other
environments):

1. Stop chef-client on all praefect and gitaly nodes served by praefect to
prevent inconsistencies in the middle of the process:

    ```
    knife ssh "roles:gprd-base-stor-gitaly-praefect OR roles:gprd-base-stor-praefect" "sudo service chef-client stop"
    ```

1. Edit the secrets in GKMS to add or remove the tokens for the corresponding
file storages you're modifying:

    ```
    bin/gkms-vault-edit praefect-omnibus-secrets gprd
    ```

1. Apply the chef-repo roles changes that add or remove  file storages.

1. Run chef-client on the target hosts:

    ```
    knife ssh "roles:gprd-base-stor-gitaly-praefect OR roles:gprd-base-stor-praefect" "sudo chef-client"
    ```

1. Re-enable chef-client:

    ```
    knife ssh "roles:gprd-base-stor-gitaly-praefect OR roles:gprd-base-stor-praefect" "sudo service chef-client start"
    ```
