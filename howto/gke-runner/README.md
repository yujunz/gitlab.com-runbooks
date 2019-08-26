## Summary

This directory contains the kubernetes configuration for the GKE runner cluster
that is created by Terraform run for the projects that config runners on GKE.

## Configure

Run the following command which will generate customized instructions

1. Ensure that `ensubst` is installed locally:

    ```
    brew install gettext
    ```

2. Export the following variables for the endpoint and the GCP project:

    ```
    export GITLAB_ENDPOINT=pre.gitlab.com
    export GITLAB_PROJECT=gitlab-pre
    ```
    
3. Run the following command to generate customized instructions for the
   instance

    ```
    DOLLAR='$' envsubst < INSTRUCTIONS.md
    ```
