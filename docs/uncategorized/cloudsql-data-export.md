# Summary

To export data from a cloudSQL database (such as `version.gitlab.com`), to give to the data team for analytics, use this procedure

# Prepare

Create a temporary bucket in the `gitlab-internal` GCP project.  In this case, I'm creating `tmurphy-temp`

Verify that you have access to both the new bucket and the cloudSQL instance in the `gs-production` and `license-prd` projects.  (All SRE's should have this access).

# Procedure

## Ensure the projects are set up

This only needs to be done once, and you can skip it and re-use your own project configurations below if you know that you already have them set up with a different name.

```
gcloud config configurations create gs-production --project gs-production-efd5e8 --account $USER@gitlab.com
gcloud config configurations create license-prd --project license-prd-bfe85b --account $USER@gitlab.com
```
> Note that you'll need to replace `$USER` in the commands if your Google ID and local user name are different.

## Export version

```
gcloud config configurations activate gs-production
gcloud sql export sql cloudsql-411f gs://gs-production-db-backups/version-data-(date +"%Y-%m-%d").gz --database=default
```

The above operation WILL time out. This is fine. The error message will be something similar to the following:

```
Operation https://sqladmin.googleapis.com/sql/v1beta4/projects/gs-production-efd5e8/operations/94248252-85ce-487c-8bc4-e3ee5f340f26 is taking longer than expected. You can continue waiting for the operation by running `gcloud beta sql operations wait --project gs-production-efd5e8 94248252-85ce-487c-8bc4-e3ee5f340f26`
```
Run the command suggested in that message to check when it finishes. (It might be necessary to run it to check more than once).

## Copy version

Once it completes, copy it to the temporary bucket.

```
gsutil cp gs://gs-production-db-backups/version-data-(date +"%Y-%m-%d").gz gs://tmurphy-temp/version-data-(date +"%Y-%m-%d").gz
```

## Export license

```
gcloud config configurations activate license-prd
gcloud sql export sql cloudsql-4bf6 gs://license-prd-data/license-data-(date +"%Y-%m-%d").gz --database=default
```

## Copy license

Once it completes, copy it to the temporary bucket.

```
gsutil cp gs://license-prd-data/license-data-(date +"%Y-%m-%d").gz gs://tmurphy-temp/license-data-(date +"%Y-%m-%d").gz
```

## Wrap up

Notify the requester of the bucket name above and remind them that they are responsible for deleting the bucket.
