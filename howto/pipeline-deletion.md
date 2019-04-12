# Deleting Pipelines on GitLab.com

There might come an occasion where you need to delete a pipeline from a project on GitLab.com.  The GitLab-EE documentation includes a handy guide describing how to delete them on a standard GitLab-EE instance: https://docs.gitlab.com/ee/api/pipelines.html#delete-a-pipeline

For GitLab.com:

> curl --header "PRIVATE-TOKEN: <ADMIN_TOKEN>" --request "DELETE" "https://gitlab.com/api/v4/projects/<PROJECT_ID>/pipelines/<PIPELINE_ID>"

| Variable | Explanation |
| ---------- | ---------- |
| ADMIN_TOKEN | This can be either a GitLab.com admin token or a project owner token |
| PROJECT_ID | The ID # of the project |
| PIPELINE_ID | The pipeline # shown in the MR/commit or jobs |
