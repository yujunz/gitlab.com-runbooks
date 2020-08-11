# Release Artifact Bucket

We occasionally get a request such as [this one](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10637)
that asks us to create a bucket for release artifacts. Currently we
create the bucket in the `gitlab-ops` account and give the requested
permissions. The required terraform will look something like this:

```hcl
# issue link
resource "google_storage_bucket" "bucketname" {
  name     = "bucketname"
  location = "US"
  project  = var.project
}

# Create service account for read/write access
resource "google_service_account" "bucketname" {
  account_id   = "bucketname"
  display_name = "bucketname"
  description  = "Service account used to publish binaries to the bucketname bucket"
}
resource "google_storage_bucket_iam_member" "bucketname-write" {
  bucket = google_storage_bucket.bucketname.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.bucketname.email}"
}
```
