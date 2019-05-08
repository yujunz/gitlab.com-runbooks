## INSTRUCTIONS

1. Install gitlab-runner on your workstation https://docs.gitlab.com/runner/install/osx.html
2. Generate a cicd token:
    * `/usr/local/bin/gitlab-runner register`
    * Copy the coordinator URL and registration token from `https://$GITLAB_ENDPOINT/admin/runners`
    * Use `kubernetes` as the executor
3. Generate the kubectl configuration for the cluster by running the _connect to cluster_
   option in the console UI, for example:
   ```
   gcloud container clusters get-credentials CLUSTER_NAME --zone us-east1-b --project $GITLAB_PROJECT
   ```
4. Retrieve the `Runner Token` for the newly created runner from the admin runner page on $GITLAB_ENDPOINT - https://$GITLAB_ENDPOINT/admin/runners
   and set it `export RUNNER_TOKEN=<token value>` It will be substituted in the configmap
   when the configuration is applied.
    * **Note**: This is _NOT_ the token in the section `Set up a shared Runner manually`
5. Apply the configuration
    ```
    for f in $(/bin/ls *.yml); do envsubst < "${DOLLAR}f" | kubectl apply -f -; done
    ```
6. Confirm that the runner is able to contact pre on the runner admin page - https://$GITLAB_ENDPOINT/admin/runners
7. If things aren't working properly see the status of the pods by running `kubectl get all -n gitlab`
